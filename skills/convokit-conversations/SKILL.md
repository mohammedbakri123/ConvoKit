---
name: convokit-conversations
description: >
  Use when displaying conversation lists, handling conversation selection, implementing ConversationRepository, or customizing ConversationsView.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Conversations

Guidelines and patterns for displaying and managing conversation lists.

## Public UI: `ConversationsView`

The primary widget for conversation lists:

```dart
ConversationsView(
  onConversationTap: (conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation),
      ),
    );
  },
  listItemBuilder: (context, conversation) {
    // Optional custom item builder
    return null; // Fallback to default
  },
  emptyBuilder: (context) => const Center(child: Text('No active chats')),
  errorBuilder: (context, error) => Center(child: Text(error.message)),
)
```

## Contract: `ConversationRepository`

Hosts implement `ConversationRepository`:

```dart
abstract class ConversationRepository {
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  });

  Future<ChatResult<ChatConversation>> getConversation(String id);
  Future<ChatResult<void>> markAsRead(String conversationId);
  Future<ChatResult<void>> deleteConversation(String conversationId);
}
```

## Model Invariants: `ChatConversation`

- **Direct Conversations**: Created via `ChatConversation.direct(id: ..., peer: user)`. Invariant: `group` is null, `peer` is non-null.
- **Group Conversations**: Created via `ChatConversation.group(id: ..., group: group)`. Invariant: `peer` is null, `group` is non-null.
- **Unread Counts**: Managed by Core; updated when messages arrive or when `markAsRead` is called.
