import 'package:convokit/src/core/models/models.dart';

/// Utility for validating that a quoted message belongs to the current conversation.
class ReplyUtils {
  /// Returns the quoted message's server ID if it belongs to the current
  /// conversation, or `null` if invalid (wrong conversation or null).
  static String? getQuotedMessageId({
    ChatMessage? quotedMessage,
    ChatUser? user,
    ChatGroup? group,
    String? conversationId,
  }) {
    if (quotedMessage == null) return null;
    final id = quotedMessage.id;
    if (id == null || id.isEmpty) return null;

    if (conversationId != null && conversationId.isNotEmpty) {
      return quotedMessage.conversationId == conversationId ? id : null;
    }

    if (user != null) {
      final ids = quotedMessage.conversationId.split('_');
      return ids.contains(user.id) ? id : null;
    }

    if (group != null) {
      return quotedMessage.conversationId == group.id ||
              quotedMessage.conversationId.contains(group.id)
          ? id
          : null;
    }

    return null;
  }
}
