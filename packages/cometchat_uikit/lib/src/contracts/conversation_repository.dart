/// ConversationRepository contract according to API-DESIGN.md §4.
library;

import '../core/models/conversation.dart';
import 'pagination.dart';
import 'result.dart';

abstract class ConversationRepository {
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  });
  Future<ChatResult<ChatConversation>> getConversation(String id);
  Future<ChatResult<void>> markAsRead(String conversationId);
  Future<ChatResult<void>> deleteConversation(String conversationId);
}
