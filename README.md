# ConvoKit for Flutter

ConvoKit is a backend-agnostic Flutter chat UI library. It provides high-performance, customizable chat widgets with optimistic messaging, client-side lifecycle management, and clear contract boundaries.

## Architecture & State Management

### Agnostic Public API
ConvoKit's public API is 100% plain Dart contracts, models, streams, and widgets (`ConvoKitScope`, `ConversationsView`, `MessageListView`). Consumers are free to use any state management system (Riverpod, Provider, signals, or plain widgets). The library does not expose or force any BLoC types in its public API.

### Honest Dependency Position: `flutter_bloc` in v1
In v1, `flutter_bloc` **remains an internal direct dependency** of the `convokit` package, used internally by legacy adapter blocs. While BLoC is completely absent from the public API and host applications never need to use or configure `BlocProvider`, the package itself still directly depends on `flutter_bloc`. Full removal of the internal `flutter_bloc` dependency in favor of direct Core store observation is planned for Phase 7.

## Installation

Add ConvoKit to your `pubspec.yaml`:

```yaml
dependencies:
  convokit: ^0.1.0
```

## Quick Start (Host Integration Example)

ConvoKit uses host-driven dependency injection via plain Dart composition roots. To integrate with your backend (or a local in-memory fake):

```dart
import 'package:flutter/material.dart';
import 'package:convokit/convokit.dart';

void main() {
  // 1. Build your backend providers implementing the ConvoKit contracts
  final fakeBackend = InMemoryChatBackend();

  // 2. Assemble the ConvoKit composition root
  final kit = ConvoKit(
    session: fakeBackend.session,
    users: fakeBackend.users,
    conversations: fakeBackend.conversations,
    messages: fakeBackend.messages,
    events: fakeBackend.events,
    groups: fakeBackend.groups,       // nullable: omit if unsupported
    media: fakeBackend.media,         // nullable: omit if unsupported
    capabilities: ChatCapabilities.basic(),
  );

  runApp(
    MaterialApp(
      home: ConvoKitScope(
        kit: kit,
        child: const ChatHomeScreen(),
      ),
    ),
  );
}

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: ConversationsView(
        onConversationTap: (conversation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(conversation.peer?.name ?? conversation.id)),
                body: MessageListView(conversationId: conversation.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## Repository Structure

| Directory | Description |
|-----------|-------------|
| `packages/cometchat_uikit` | The `convokit` library package (contracts, core, UI components, tests) |
| `examples/sample_app` | Full offline sample app running against an in-memory backend |
| `examples/clean_consumer` | Pure Riverpod consumer app with zero BLoC usage |
| `skills/` | Agent guidance for integrating and customizing ConvoKit |

## License & Attribution

ConvoKit is licensed under the MIT License.
Based on CometChat UIKit for Flutter, © CometChat, MIT.
