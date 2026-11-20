---
name: convokit-placement
description: >
  Use when integrating ConvoKit into Flutter app navigation, tabs, split-views, or modal dialogs.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Placement & Screen Integration

Common application layouts and navigation patterns.

## Pattern 1: Standard Push-Navigation (Mobile)

Place `ConvoKitScope` at the app root, and push `MessageListView` when a conversation is tapped:

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ConversationsView(
        onConversationTap: (conversation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
      ),
    );
  }
}
```

## Pattern 2: Responsive Split-View (Tablet / Desktop / Web)

```dart
Widget buildSplitView(BuildContext context) {
  return Row(
    children: [
      SizedBox(
        width: 350,
        child: ConversationsView(
          onConversationTap: (conv) => setState(() => selectedId = conv.id),
        ),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        child: selectedId != null
            ? MessageListView(conversationId: selectedId!)
            : const Center(child: Text('Select a conversation')),
      ),
    ],
  );
}
```
