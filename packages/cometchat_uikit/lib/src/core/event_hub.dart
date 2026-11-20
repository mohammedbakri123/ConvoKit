/// Centralized EventHub implementation according to API-DESIGN.md §8, §10, §11.2.
library;

import 'dart:async';

import '../contracts/contracts.dart';
import 'convo_kit.dart';
import 'message_coordinator.dart';
import 'models/models.dart';
import 'stores/stores.dart';

/// Central EventHub coordinating realtime subscriptions and lifecycle for a ConvoKit instance.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class EventHub {
  int _generation = 0;
  ConvoKit? _kit;
  bool _isDisposed = false;
  String? _lastUserId;

  StreamSubscription<ChatUser?>? _sessionSubscription;
  StreamSubscription<ChatEvent>? _eventSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  Future<void> _lifecycleQueue = Future.value();

  MessageCoordinator? _coordinator;
  final ConversationStore _conversationStore = ConversationStore();
  final TypingRegistry _typingRegistry = TypingRegistry();
  final PresenceRegistry _presenceRegistry = PresenceRegistry();

  final Set<String> _visibleConversations = {};
  final Set<String> _staleConversations = {};
  final List<ChatEvent> _bufferedEvents = [];
  bool _isRecovering = false;

  ConnectionStatus _currentStatus = const ConnectionStatus(
    ConnectionState.disconnected,
  );
  final _connectionStateController =
      StreamController<ConnectionStatus>.broadcast();

  bool _wasConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  static const List<Duration> _backoffDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  int get generation => _generation;
  bool get isDisposed => _isDisposed;
  ConvoKit? get currentKit => _kit;

  MessageCoordinator get coordinator =>
      _coordinator ??= MessageCoordinator(_kit!);
  ConversationStore get conversationStore => _conversationStore;
  TypingRegistry get typingRegistry => _typingRegistry;
  PresenceRegistry get presenceRegistry => _presenceRegistry;

  Stream<ConnectionStatus> get connectionState =>
      _connectionStateController.stream;
  ConnectionStatus get currentConnectionStatus => _currentStatus;

  MessageStore getMessageStore(String conversationId) =>
      coordinator.getStore(conversationId);

  void registerVisibleConversation(String conversationId) {
    _visibleConversations.add(conversationId);
    if (_staleConversations.remove(conversationId)) {
      unawaited(coordinator.fetchLatest(conversationId));
    }
  }

  void unregisterVisibleConversation(String conversationId) {
    _visibleConversations.remove(conversationId);
  }

  /// Attaches a [ConvoKit] instance, subscribes to the session stream,
  /// and connects if a user is signed in.
  void attach(ConvoKit kit) {
    if (_isDisposed) return;
    final gen = ++_generation;
    _lifecycleQueue = _lifecycleQueue.then((_) async {
      if (_isDisposed || gen != _generation) return;
      _kit = kit;
      _coordinator = MessageCoordinator(kit);
      _lastUserId = kit.session.currentUser?.id;
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

    // Synchronously cancel subscriptions and clear old stores per §10.1
    _coordinator?.cancelAllUploads();
    _coordinator?.discardAllPending();
    _cancelSubscriptions();
    _reconnectTimer?.cancel();
    _clearAllStores();

    _lifecycleQueue = _lifecycleQueue.then((_) async {
      // 1. Teardown old kit if present (bounded wait 5s)
      if (oldKit != null) {
        try {
          await oldKit.events
              .disconnect()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => ChatResult.ok(),
              )
              .catchError((_) => ChatResult.ok());
        } catch (_) {
          // Bounded wait (5s) best-effort teardown.
        }
      }

      // If generation changed while awaiting disconnect, skip connecting intermediate kit.
      if (_isDisposed || gen != _generation) return;

      _kit = newKit;
      _coordinator = MessageCoordinator(newKit);
      _lastUserId = newKit.session.currentUser?.id;
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
    _reconnectTimer?.cancel();
    _clearAllStores();

    final kitToDisconnect = _kit;
    _kit = null;

    if (kitToDisconnect != null) {
      _lifecycleQueue = _lifecycleQueue.then((_) async {
        try {
          await kitToDisconnect.events
              .disconnect()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => ChatResult.ok(),
              )
              .catchError((_) => ChatResult.ok());
        } catch (_) {
          // Best-effort disconnect after dispose.
        }
      });
    }

    _conversationStore.dispose();
    _typingRegistry.dispose();
    _presenceRegistry.dispose();
    _connectionStateController.close();
  }

  void _cancelSubscriptions() {
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = null;
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;
    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = null;
  }

  void _clearAllStores() {
    _coordinator?.clearAll();
    _conversationStore.clear();
    _typingRegistry.clear();
    _presenceRegistry.clear();
    _visibleConversations.clear();
    _staleConversations.clear();
    _bufferedEvents.clear();
  }

  void _updateConnectionStatus(ConnectionStatus status) {
    _currentStatus = status;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(status);
    }
  }

  void _subscribeSession(ConvoKit kit, int gen) {
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = kit.session.currentUserStream.listen(
      (user) {
        if (_isDisposed || gen != _generation) return;
        _onSessionUserChanged(user, gen);
      },
      onError: (Object _) {
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

    if (newUser?.id == _lastUserId) {
      // Same-user re-emission is a no-op (§10.1)
      return;
    }

    final oldUserId = _lastUserId;
    _lastUserId = newUser?.id;

    if (newUser != null) {
      if (oldUserId != null && oldUserId != newUser.id) {
        // Identity change A -> B: teardown old first, clear all stores (§10.1)
        final nextGen = ++_generation;
        _coordinator?.cancelAllUploads();
        _coordinator?.discardAllPending();
        _cancelSubscriptions();
        _clearAllStores();

        _lifecycleQueue = _lifecycleQueue.then((_) async {
          try {
            await curKit.events
                .disconnect()
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => ChatResult.ok(),
                )
                .catchError((_) => ChatResult.ok());
          } catch (_) {}

          if (_isDisposed || nextGen != _generation) return;
          _subscribeSession(curKit, nextGen);
          await _connectKit(curKit, nextGen);
        });
      } else {
        // null -> user
        final nextGen = ++_generation;
        _lifecycleQueue = _lifecycleQueue.then((_) async {
          if (_isDisposed || nextGen != _generation) return;
          await _connectKit(curKit, nextGen);
        });
      }
    } else {
      // User signed out -> null
      final nextGen = ++_generation;
      _coordinator?.cancelAllUploads();
      _coordinator?.discardAllPending();
      _cancelSubscriptions();
      _clearAllStores();

      _lifecycleQueue = _lifecycleQueue.then((_) async {
        try {
          await curKit.events
              .disconnect()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => ChatResult.ok(),
              )
              .catchError((_) => ChatResult.ok());
        } catch (_) {}

        if (_isDisposed || nextGen != _generation) return;
        _updateConnectionStatus(
          const ConnectionStatus(ConnectionState.disconnected),
        );
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
    _clearAllStores();
    _updateConnectionStatus(
      const ConnectionStatus(ConnectionState.disconnected),
    );
  }

  Future<void> _connectKit(ConvoKit kit, int gen) async {
    if (_isDisposed || gen != _generation) return;

    _updateConnectionStatus(const ConnectionStatus(ConnectionState.connecting));

    // Subscribe fresh to event stream and connection state stream (API-DESIGN.md §8.3)
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = kit.events.events.listen(
      (event) {
        if (_isDisposed || gen != _generation) return;
        _handleIncomingEvent(event);
      },
      onError: (Object error) {
        if (_isDisposed || gen != _generation) return;
        _handleStreamFailure(gen, error);
      },
      onDone: () {
        if (_isDisposed || gen != _generation) return;
        _handleStreamFailure(gen, 'events stream closed');
      },
      cancelOnError: false,
    );

    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = kit.events.connectionState.listen(
      (status) {
        if (_isDisposed || gen != _generation) return;
        _handleConnectionStatus(kit, status, gen);
      },
      onError: (Object error) {
        if (_isDisposed || gen != _generation) return;
        _handleStreamFailure(gen, error);
      },
      onDone: () {
        if (_isDisposed || gen != _generation) return;
        _handleStreamFailure(gen, 'connectionState stream closed');
      },
      cancelOnError: false,
    );

    try {
      final res = await kit.events.connect();
      if (_isDisposed || gen != _generation) {
        // Stale result discarded
        return;
      }
      if (res.isFailure) {
        final error = (res as ChatFailure<void>).error;
        _updateConnectionStatus(
          ConnectionStatus(ConnectionState.disconnected, error: error),
        );
        _scheduleReconnect(gen);
      }
    } catch (e) {
      if (_isDisposed || gen != _generation) return;
      final error = ChatError(ChatErrorCode.network, e.toString());
      _updateConnectionStatus(
        ConnectionStatus(ConnectionState.disconnected, error: error),
      );
      _scheduleReconnect(gen);
    }
  }

  void _handleConnectionStatus(
    ConvoKit kit,
    ConnectionStatus status,
    int gen,
  ) {
    _updateConnectionStatus(status);

    if (status.state == ConnectionState.connected) {
      final needsRecovery = _wasConnected;
      _wasConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      if (needsRecovery) {
        _runReconnectRecovery(kit, gen);
      }
    } else if (status.state == ConnectionState.disconnected) {
      if (kit.session.currentUser != null) {
        _scheduleReconnect(gen);
      }
    }
  }

  void _scheduleReconnect(int gen) {
    if (_isDisposed || gen != _generation) return;
    if (_kit?.session.currentUser == null) return;
    if (_currentStatus.state == ConnectionState.connecting) return;
    if (_reconnectAttempts >= 5) {
      // Capped at 5 attempts; manual retryConnection() required (§8.2)
      return;
    }

    final delay = _reconnectAttempts < _backoffDelays.length
        ? _backoffDelays[_reconnectAttempts]
        : const Duration(seconds: 30);
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_isDisposed || gen != _generation) return;
      _reconnect(gen);
    });
  }

  /// Manual retry of connection, resetting backoff schedule (§8.2).
  void retryConnection() {
    if (_isDisposed) return;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    final gen = _generation;
    _reconnect(gen);
  }

  void _reconnect(int gen) {
    if (_isDisposed || gen != _generation) return;
    final curKit = _kit;
    if (curKit == null || curKit.session.currentUser == null) return;
    if (_currentStatus.state == ConnectionState.connecting) return;

    _lifecycleQueue = _lifecycleQueue.then((_) async {
      if (_isDisposed || gen != _generation) return;
      await _connectKit(curKit, gen);
    });
  }

  void _handleStreamFailure(int gen, Object error) {
    if (_isDisposed || gen != _generation) return;
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;
    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = null;

    final curKit = _kit;
    if (curKit != null) {
      unawaited(
        curKit.events
            .disconnect()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => ChatResult.ok(),
            )
            .catchError((_) => ChatResult.ok()),
      );
    }

    _updateConnectionStatus(
      ConnectionStatus(
        ConnectionState.disconnected,
        error: ChatError(ChatErrorCode.network, error.toString()),
      ),
    );

    _scheduleReconnect(gen);
  }

  Future<void> _runReconnectRecovery(ConvoKit kit, int gen) async {
    _isRecovering = true;

    try {
      // 1. Mark non-visible conversations as stale (§8.6)
      for (final store in coordinator.stores.values) {
        if (!_visibleConversations.contains(store.conversationId)) {
          _staleConversations.add(store.conversationId);
        }
      }

      // 2. For each visible conversation, run catch-up (§5.2, §5.5, §8.6)
      for (final convId in _visibleConversations) {
        if (_isDisposed || gen != _generation) return;
        final store = coordinator.getStore(convId);

        if (kit.capabilities.messageCatchUp && store.newerCheckpoint != null) {
          var currentCursor = store.newerCheckpoint;
          var pagesFetched = 0;
          var hasMoreNewer = true;

          while (pagesFetched < 10 && hasMoreNewer) {
            if (_isDisposed || gen != _generation) return;
            final req = MessagePageRequest(
              direction: MessagePageDirection.newer,
              cursor: currentCursor,
            );
            final pageRes = await kit.messages.fetchMessages(convId, req);
            if (pageRes.isFailure) break;

            final page = (pageRes as ChatSuccess<ChatPage<ChatMessage>>).value;
            store.mergePage(page, MessagePageDirection.newer);
            pagesFetched++;
            currentCursor = page.newerCursor;
            hasMoreNewer = page.hasNewer;
          }

          if (hasMoreNewer) {
            store.setGapFlag(true);
          } else {
            store.setGapFlag(false);
          }
        } else {
          // Fallback to latest refresh + merge (§5.4)
          if (_isDisposed || gen != _generation) return;
          final req = const MessagePageRequest(
            direction: MessagePageDirection.latest,
          );
          final pageRes = await kit.messages.fetchMessages(convId, req);
          if (pageRes.isSuccess) {
            final page = (pageRes as ChatSuccess<ChatPage<ChatMessage>>).value;
            store.mergePage(page, MessagePageDirection.latest);
          }
        }
      }

      // 3. Refresh conversation list: unread counts backend-authoritative (§8.6)
      if (_isDisposed || gen != _generation) return;
      final convsRes = await kit.conversations.listConversations();
      if (convsRes.isSuccess) {
        final page =
            (convsRes as ChatSuccess<ChatPage<ChatConversation>>).value;
        _conversationStore.setConversations(page.items);
      }

      // 4. Drain buffered events in order through dedupe (§8.6)
      final eventsToDistribute = List<ChatEvent>.from(_bufferedEvents);
      _bufferedEvents.clear();

      for (final event in eventsToDistribute) {
        if (_isDisposed || gen != _generation) return;
        _distributeEvent(event);
      }
    } finally {
      _isRecovering = false;
    }
  }

  void _handleIncomingEvent(ChatEvent event) {
    if (_isRecovering) {
      _bufferedEvents.add(event);
    } else {
      _distributeEvent(event);
    }
  }

  void _distributeEvent(ChatEvent event) {
    switch (event) {
      case MessageReceived e:
        final store = coordinator.getStore(e.message.conversationId);
        store.addOrReconcile(e.message);
      case MessageStatusChanged e:
        final store = coordinator.getStore(e.conversationId);
        store.applyStatusChange(
          e.messageId,
          e.deliveryState,
          currentUserId: _kit?.session.currentUser?.id,
        );
      case MessageDeleted e:
        final store = coordinator.getStore(e.conversationId);
        store.removeMessage(e.messageId);
      case TypingChanged e:
        _typingRegistry.setTyping(e.conversationId, e.user, e.isTyping);
      case PresenceChanged e:
        _presenceRegistry.setPresence(e.user.id, e.presence);
      case ConversationUpdated e:
        _conversationStore.updateConversation(e.conversation);
    }
  }
}
