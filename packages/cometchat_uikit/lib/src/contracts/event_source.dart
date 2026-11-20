/// Realtime event contracts according to API-DESIGN.md §8.
library;

import '../core/models/conversation.dart';
import '../core/models/message.dart';
import '../core/models/user.dart';
import 'result.dart';

sealed class ChatEvent {
  final DateTime receivedAt;
  const ChatEvent({required this.receivedAt});
}

class MessageReceived extends ChatEvent {
  final ChatMessage message; // a new message (or the echo of our own send)

  const MessageReceived({
    required this.message,
    required super.receivedAt,
  });

  @override
  String toString() =>
      'MessageReceived(message: ${message.localId}, receivedAt: $receivedAt)';
}

class MessageStatusChanged extends ChatEvent {
  /// The backend-generated delivery state for a message WE sent.
  /// The only status change events can carry in v1.
  final String conversationId;
  final String messageId;
  final DeliveryState deliveryState; // delivered or read only

  const MessageStatusChanged({
    required this.conversationId,
    required this.messageId,
    required this.deliveryState,
    required super.receivedAt,
  }) : assert(
         deliveryState == DeliveryState.delivered ||
             deliveryState == DeliveryState.read,
         'MessageStatusChanged deliveryState must be delivered or read',
       );

  @override
  String toString() =>
      'MessageStatusChanged(conversationId: $conversationId, messageId: $messageId, deliveryState: $deliveryState)';
}

class MessageDeleted extends ChatEvent {
  final String conversationId;
  final String messageId;

  const MessageDeleted({
    required this.conversationId,
    required this.messageId,
    required super.receivedAt,
  });

  @override
  String toString() =>
      'MessageDeleted(conversationId: $conversationId, messageId: $messageId)';
}

class TypingChanged extends ChatEvent {
  final String conversationId;
  final ChatUser user;
  final bool isTyping;

  const TypingChanged({
    required this.conversationId,
    required this.user,
    required this.isTyping,
    required super.receivedAt,
  });

  @override
  String toString() =>
      'TypingChanged(conversationId: $conversationId, user: ${user.id}, isTyping: $isTyping)';
}

class PresenceChanged extends ChatEvent {
  final ChatUser user;
  final UserPresence presence;

  const PresenceChanged({
    required this.user,
    required this.presence,
    required super.receivedAt,
  });

  @override
  String toString() =>
      'PresenceChanged(user: ${user.id}, presence: $presence)';
}

class ConversationUpdated extends ChatEvent {
  final ChatConversation conversation;

  const ConversationUpdated({
    required this.conversation,
    required super.receivedAt,
  });

  @override
  String toString() =>
      'ConversationUpdated(conversation: ${conversation.id})';
}

enum ConnectionState { connecting, connected, disconnected }

/// The authoritative connection status. `error` is present when the state
/// is `disconnected` because of a failure.
class ConnectionStatus {
  final ConnectionState state;
  final ChatError? error;

  const ConnectionStatus(this.state, {this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStatus &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          error == other.error;

  @override
  int get hashCode => Object.hash(state, error);

  @override
  String toString() => 'ConnectionStatus($state, error: $error)';
}

abstract class ChatEventSource {
  Stream<ChatEvent> get events;

  /// The single authoritative connection-state mechanism.
  Stream<ConnectionStatus> get connectionState;

  Future<ChatResult<void>> connect();
  Future<ChatResult<void>> disconnect();
  Future<ChatResult<void>> reconnect();
}
