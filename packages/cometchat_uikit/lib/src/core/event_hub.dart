/// Centralized EventHub skeleton according to API-DESIGN.md §8, §11.2.
library;

import 'dart:async';

import '../contracts/contracts.dart';
import 'convo_kit.dart';
import 'models/models.dart';

/// Central EventHub coordinating realtime subscriptions and lifecycle for a ConvoKit instance.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class EventHub {
  int _generation = 0;
  ConvoKit? _kit;
  bool _isDisposed = false;

  StreamSubscription<ChatUser?>? _sessionSubscription;
  StreamSubscription<ChatEvent>? _eventSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  Future<void> _lifecycleQueue = Future.value();

  int get generation => _generation;
  bool get isDisposed => _isDisposed;
  ConvoKit? get currentKit => _kit;

  /// Attaches a [ConvoKit] instance, subscribes to the session stream,
  /// and connects if a user is signed in.
  void attach(ConvoKit kit) {
    if (_isDisposed) return;
    final gen = ++_generation;
    _lifecycleQueue = _lifecycleQueue.then((_) async {
      if (_isDisposed || gen != _generation) return;
      _kit = kit;
      _subscribeSession(kit, gen);

      if (kit.session.currentUser != null) {
        await _connectKit(kit, gen);
      }
    });
  }

  /// Reattaches with a new [ConvoKit] instance.
  ///
  /// Serialized through [_lifecycleQueue] with generation token invalidation.
  void reattach(ConvoKit newKit) {
    if (_isDisposed) return;
    final gen = ++_generation;
    final oldKit = _kit;

    // Synchronously cancel existing subscriptions so old source events stop immediately.
    _cancelSubscriptions();

    _lifecycleQueue = _lifecycleQueue.then((_) async {
      // 1. Teardown old kit if present
      if (oldKit != null) {
        try {
          await oldKit.events
              .disconnect()
              .timeout(const Duration(seconds: 5), onTimeout: () => ChatResult.ok());
        } catch (_) {
          // Bounded wait (5s) best-effort teardown.
        }
      }

      // If generation changed while awaiting disconnect, skip connecting intermediate kit.
      if (_isDisposed || gen != _generation) return;

      _kit = newKit;
      _subscribeSession(newKit, gen);

      if (newKit.session.currentUser != null) {
        await _connectKit(newKit, gen);
      }
    });
  }

  /// Disposes the hub.
  ///
  /// Synchronously cancels subscriptions, increments generation token
  /// to invalidate in-flight async work, and performs best-effort teardown.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    ++_generation;

    _cancelSubscriptions();

    final kitToDisconnect = _kit;
    _kit = null;

    if (kitToDisconnect != null) {
      _lifecycleQueue = _lifecycleQueue.then((_) async {
        try {
          await kitToDisconnect.events
              .disconnect()
              .timeout(const Duration(seconds: 5), onTimeout: () => ChatResult.ok());
        } catch (_) {
          // Best-effort disconnect after dispose.
        }
      });
    }
  }

  void _cancelSubscriptions() {
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = null;
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;
    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = null;
  }

  void _subscribeSession(ConvoKit kit, int gen) {
    _sessionSubscription = kit.session.currentUserStream.listen(
      (user) {
        if (_isDisposed || gen != _generation) return;
        _onSessionUserChanged(user, gen);
      },
      onError: (Object error) {
        if (_isDisposed || gen != _generation) return;
        // Session stream error treated as unobservable session (API-DESIGN.md §10.2).
        _handleSessionTermination(gen);
      },
      onDone: () {
        if (_isDisposed || gen != _generation) return;
        _handleSessionTermination(gen);
      },
      cancelOnError: false,
    );
  }

  void _onSessionUserChanged(ChatUser? newUser, int gen) {
    final curKit = _kit;
    if (curKit == null) return;

    if (newUser != null) {
      _lifecycleQueue = _lifecycleQueue.then((_) async {
        if (_isDisposed || gen != _generation) return;
        await _connectKit(curKit, gen);
      });
    } else {
      _lifecycleQueue = _lifecycleQueue.then((_) async {
        if (_isDisposed || gen != _generation) return;
        try {
          await curKit.events
              .disconnect()
              .timeout(const Duration(seconds: 5), onTimeout: () => ChatResult.ok());
        } catch (_) {}
      });
    }
  }

  void _handleSessionTermination(int gen) {
    final curKit = _kit;
    if (curKit != null) {
      try {
        unawaited(curKit.events.disconnect());
      } catch (_) {}
    }
    _cancelSubscriptions();
  }

  Future<void> _connectKit(ConvoKit kit, int gen) async {
    if (_isDisposed || gen != _generation) return;

    // Subscribe to event stream and connection state stream (one subscription per instance).
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = kit.events.events.listen(
      (event) {
        if (_isDisposed || gen != _generation) return;
        // Distribution to stores will be wired in Phase 3.
      },
      onError: (Object _) {
        // Stream errors handled per API-DESIGN.md §8.3.
      },
      cancelOnError: false,
    );

    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = kit.events.connectionState.listen(
      (status) {
        if (_isDisposed || gen != _generation) return;
        // Connection status handling wired in Phase 3.
      },
      onError: (Object _) {},
      cancelOnError: false,
    );

    try {
      final res = await kit.events.connect();
      if (_isDisposed || gen != _generation) {
        // Stale result discarded.
        return;
      }
      if (res.isFailure) {
        // Handled as disconnected with error in Phase 3.
      }
    } catch (_) {
      // Handled in Phase 3.
    }
  }
}
