/// MessageRepository contract according to API-DESIGN.md §4.
library;

import '../core/models/message.dart';
import 'pagination.dart';
import 'result.dart';

abstract class MessageRepository {
  /// Directional, opaque-cursor pagination.
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  );

  /// One-shot send. The adapter sends exactly the message it is given and
  /// returns the confirmed message (same localId, server id filled in)
  /// or a failure. It keeps no pending state and offers no retry.
  /// If the backend reports that localId was already persisted (a retry
  /// after a lost response), the adapter MUST return success with the
  /// already-persisted server message — not an error.
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message);

  Future<ChatResult<void>> deleteMessage(String messageId);

  /// Report that received messages were delivered/read by this user.
  /// These report client-side receipt state to the backend; the receipt
  /// states of sent messages arrive as MessageStatusChanged events.
  Future<ChatResult<void>> markAsDelivered(String messageId);
  Future<ChatResult<void>> markAsRead(String messageId);

  /// Typing signals this user sends. Inbound typing arrives via events.
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping);
}
