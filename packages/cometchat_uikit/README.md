# ConvoKit for Flutter

ConvoKit provides pre-built, customizable UI components and core contracts to add chat messaging to your Flutter applications against any backend.

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
