import 'dart:async';

import '../contracts/contracts.dart';
import 'message_coordinator.dart';
import 'models/models.dart';
import 'stores/message_store.dart';

/// Controller for host-driven interaction with MessageListView.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc (API-DESIGN.md §11.2).
class MessageListController {
  MessageStore? _store;
  MessageCoordinator? _coordinator;
  String? _conversationId;

  StreamSubscription<bool>? _gapSubscription;
  final _gapController = StreamController<bool>.broadcast();

  final List<void Function(String localId)> _scrollListeners = [];

  bool get hasPossibleGap => _store?.hasPossibleGap ?? false;
  Stream<bool> get hasPossibleGapStream => _gapController.stream;

  void attach({
    required MessageStore store,
    required MessageCoordinator coordinator,
    required String conversationId,
  }) {
    _store = store;
    _coordinator = coordinator;
    _conversationId = conversationId;

    _gapSubscription?.cancel();
    _gapSubscription = store.gapStream.listen((gap) {
      _gapController.add(gap);
    });
    _gapController.add(store.hasPossibleGap);
  }

  void detach() {
    _gapSubscription?.cancel();
    _gapSubscription = null;
    _store = null;
    _coordinator = null;
    _conversationId = null;
  }

  /// Triggers a refresh. If gap banner was visible, re-runs catch-up.
  Future<void> refresh() async {
    if (_coordinator != null && _conversationId != null) {
      await _coordinator!.refresh(_conversationId!);
    }
  }

  /// Retries a failed message with the same localId.
  Future<ChatResult<ChatMessage>?> retryFailed(String localId) async {
    if (_coordinator != null && _conversationId != null) {
      return _coordinator!.retryFailed(
        localId,
        conversationId: _conversationId!,
      );
    }
    return null;
  }

  /// Scroll to a specific message by localId.
  void scrollToMessage(String localId) {
    for (final listener in _scrollListeners) {
      listener(localId);
    }
  }

  void addScrollListener(void Function(String localId) listener) {
    _scrollListeners.add(listener);
  }

  void removeScrollListener(void Function(String localId) listener) {
    _scrollListeners.remove(listener);
  }

  void dispose() {
    detach();
    _gapController.close();
    _scrollListeners.clear();
  }
}
