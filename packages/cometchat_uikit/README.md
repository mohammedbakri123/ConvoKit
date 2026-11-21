# ConvoKit for Flutter

ConvoKit provides pre-built, customizable UI components and core contracts to add chat messaging to your Flutter applications against any backend.

## Architecture & State Management

### Agnostic Public API
ConvoKit's public API is 100% plain Dart contracts, models, streams, and widgets (`ConvoKitScope`, `ConversationsView`, `MessageListView`). Consumers are free to use any state management system (Riverpod, Provider, signals, or plain widgets).

### Zero CometChat SDK & Zero `flutter_bloc` Dependencies
As of **`convokit` 0.1.0**, the package has **zero CometChat SDK dependencies** (`cometchat_sdk`, `cometchat_cards`, `cometchat_calls_sdk`) and **zero `flutter_bloc` or `bloc_test` dependencies**. All widgets observe plain-Dart ConvoKit Core stores (`ConversationStore`, `MessageStore`, `UserStore`, `GroupStore`, `GroupMemberStore`, `PresenceRegistry`, `TypingRegistry`) and `MessageCoordinator` directly via `ConvoKitScope`.

## Installation

Add ConvoKit to your `pubspec.yaml`:

```yaml
dependencies:
  convokit: ^0.1.0
```

## Quick Start (Host Integration Example)

```dart
import 'package:flutter/material.dart';
import 'package:convokit/convokit.dart';

void main() {
  final kit = ConvoKit(
    session: mySession,
    users: myUserRepository,
    conversations: myConversationRepository,
    messages: myMessageRepository,
    events: myEventSource,
    groups: myGroupRepository,       // optional
    media: myMediaProvider,          // optional
    capabilities: ChatCapabilities.basic(),
  );

  runApp(
    MaterialApp(
      home: ConvoKitScope(
        kit: kit,
        child: const ConversationsView(),
      ),
    ),
  );
}
```

## License

ConvoKit is licensed under the MIT License.
Based on CometChat UIKit for Flutter, © CometChat, MIT.
