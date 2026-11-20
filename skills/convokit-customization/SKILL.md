---
name: convokit-customization
description: >
  Use when customizing item builders, message bubbles, action buttons, or headers in ConvoKit views.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Customization

Recipes and patterns for overriding widgets, message bubbles, and item layouts.

## Custom Conversation List Items

```dart
ConversationsView(
  listItemBuilder: (context, conversation) {
    return ListTile(
      leading: ConvoKitAvatar(
        name: conversation.peer?.name ?? conversation.id,
      ),
      title: Text(conversation.peer?.name ?? 'Chat'),
      subtitle: Text(conversation.lastMessage?.previewText ?? ''),
      trailing: ConvoKitBadge(count: conversation.unreadCount),
      onTap: () => openChat(conversation),
    );
  },
)
```

## Custom Message Bubbles

```dart
MessageListView(
  conversationId: 'conv_123',
  messageBuilder: (context, message) {
    if (message is TextMessage && message.text.startsWith('/alert')) {
      return Container(
        color: Colors.red.shade100,
        padding: const EdgeInsets.all(12),
        child: Text('ALERT: ${message.text}'),
      );
    }
    // Return null to use standard ConvoKit bubble
    return null;
  },
)
```
