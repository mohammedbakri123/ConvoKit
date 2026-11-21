import 'dart:async';

import 'package:convokit/convokit.dart';

/// In-memory [ChatEventSource] implementation for the offline Atelier Studio
/// backend.
///
/// Streams realtime [ChatEvent]s and [ConnectionStatus] transitions locally
/// with helper methods for repositories and tests to emit domain events.
class StudioEventSource implements ChatEventSource {
  final StreamController<ChatEvent> _eventsController =
      StreamController<ChatEvent>.broadcast();
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _currentStatus = const ConnectionStatus(
    ConnectionState.disconnected,
  );
  bool _isDisposed = false;

  @override
  Stream<ChatEvent> get events => _eventsController.stream;

  @override
  Stream<ConnectionStatus> get connectionState => _connectionController.stream;

  /// Current synchronous connection status snapshot.
  ConnectionStatus get currentStatus => _currentStatus;

  /// Whether the event source is currently connected.
  bool get isConnected => _currentStatus.state == ConnectionState.connected;

  @override
  Future<ChatResult<void>> connect() async {
    if (_isDisposed) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Event source is disposed.'),
      );
    }
    _setStatus(const ConnectionStatus(ConnectionState.connecting));
    _setStatus(const ConnectionStatus(ConnectionState.connected));
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> disconnect() async {
    if (_isDisposed) {
      return ChatResult.ok();
    }
    _setStatus(const ConnectionStatus(ConnectionState.disconnected));
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> reconnect() async {
    if (_isDisposed) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Event source is disposed.'),
      );
    }
    _setStatus(const ConnectionStatus(ConnectionState.disconnected));
    _setStatus(const ConnectionStatus(ConnectionState.connecting));
    _setStatus(const ConnectionStatus(ConnectionState.connected));
    return ChatResult.ok();
  }

  /// Emits an arbitrary [ChatEvent] to all active subscribers.
  void emit(ChatEvent event) {
    if (_isDisposed || _eventsController.isClosed) return;
    _eventsController.add(event);
  }

  void emitMessageReceived(ChatMessage message, {DateTime? receivedAt}) {
    emit(
      MessageReceived(
        message: message,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void emitMessageStatusChanged({
    required String conversationId,
    required String messageId,
    required DeliveryState deliveryState,
    DateTime? receivedAt,
  }) {
    emit(
      MessageStatusChanged(
        conversationId: conversationId,
        messageId: messageId,
        deliveryState: deliveryState,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void emitMessageDeleted({
    required String conversationId,
    required String messageId,
    DateTime? receivedAt,
  }) {
    emit(
      MessageDeleted(
        conversationId: conversationId,
        messageId: messageId,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void emitTypingChanged({
    required String conversationId,
    required ChatUser user,
    required bool isTyping,
    DateTime? receivedAt,
  }) {
    emit(
      TypingChanged(
        conversationId: conversationId,
        user: user,
        isTyping: isTyping,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void emitPresenceChanged({
    required ChatUser user,
    required UserPresence presence,
    DateTime? receivedAt,
  }) {
    emit(
      PresenceChanged(
        user: user,
        presence: presence,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void emitConversationUpdated(
    ChatConversation conversation, {
    DateTime? receivedAt,
  }) {
    emit(
      ConversationUpdated(
        conversation: conversation,
        receivedAt: receivedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  void _setStatus(ConnectionStatus status) {
    _currentStatus = status;
    if (!_isDisposed && !_connectionController.isClosed) {
      _connectionController.add(status);
    }
  }

  /// Closes both broadcast stream controllers cleanly.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _eventsController.close();
    await _connectionController.close();
  }
}
