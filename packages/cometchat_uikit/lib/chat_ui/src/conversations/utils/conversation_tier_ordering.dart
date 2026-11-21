import 'package:convokit/convokit.dart';

/// Ordering helper for [ChatConversation] rows.
///
/// ConvoKit v1 sorts conversations by descending `updatedAt` (managed by
/// [ConversationStore]). Optional pinned conversation IDs can be supplied
/// externally to keep pinned items grouped at the top.
class ConversationTierOrdering {
  ConversationTierOrdering._();

  static const int systemPinTier = 0;
  static const int userPinTier = 1;
  static const int normalTier = 2;

  /// Returns the tier for [conversation] given optional pinned ID sets.
  static int tierOf(
    ChatConversation conversation, {
    Set<String> systemPinnedIds = const {},
    Set<String> userPinnedIds = const {},
  }) {
    if (systemPinnedIds.contains(conversation.id)) return systemPinTier;
    if (userPinnedIds.contains(conversation.id)) return userPinTier;
    return normalTier;
  }

  /// Index where a row of [tier] enters [rows] — the top of its own tier.
  static int tierTopIndex(
    int tier,
    List<ChatConversation> rows, {
    Set<String> systemPinnedIds = const {},
    Set<String> userPinnedIds = const {},
  }) {
    var index = 0;
    while (index < rows.length &&
        tierOf(
              rows[index],
              systemPinnedIds: systemPinnedIds,
              userPinnedIds: userPinnedIds,
            ) <
            tier) {
      index++;
    }
    return index;
  }
}
