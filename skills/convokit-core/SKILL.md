---
name: convokit-core
description: >
  Use when configuring ConvoKit, initializing ConvoKitScope, implementing ChatSession, setting ChatCapabilities, or understanding the architecture and BLoC boundary.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Core Architecture & Rules

Non-negotiable constraints and patterns for setting up and running ConvoKit.

## Composition Root (`ConvoKit`)

The host builds a single plain Dart composition root and provides it to the app:

```dart
final kit = ConvoKit(
  session: myChatSession,
  users: myUserRepository,
  conversations: myConversationRepository,
  messages: myMessageRepository,
  events: myEventSource,
  groups: myGroupRepository,       // Nullable: pass null if capabilities.groups is false
  media: myMediaProvider,          // Nullable: pass null if capabilities.media is false
  capabilities: ChatCapabilities.basic(),
);
```

### Constructor Validation (Release-Safe)
The `ConvoKit` constructor validates provider and capability alignment at runtime:
- If `capabilities.groups == true` but `groups == null` -> throws `ArgumentError`.
- If `capabilities.groups == false` but `groups != null` -> throws `ArgumentError`.
- If `capabilities.media == true` but `media == null` -> throws `ArgumentError`.
- If `capabilities.media == false` but `media != null` -> throws `ArgumentError`.
- If `capabilities.mediaDelete == true` but `media == null` -> throws `ArgumentError`.

## ConvoKitScope Lifecycle

`ConvoKitScope` is a `StatefulWidget` owning the `EventHub` lifecycle:

```dart
ConvoKitScope(
  kit: kit,
  child: const MaterialApp(
    home: HomeScreen(),
  ),
)
```

- **`initState`**: Initializes EventHub and attaches the `ConvoKit` instance.
- **`didUpdateWidget`**: If the `kit` identity changes (or current user changes), runs a serialized teardown and reattach (clearing old stores, cancelling pending work, connecting new session).
- **`dispose`**: Synchronously disconnects the event source and disposes all Core stores.

## Authentication Boundary (`ChatSession`)

ConvoKit does NOT store tokens, call login endpoints, or show login screens. The host owns authentication.

```dart
abstract class ChatSession {
  ChatUser? get currentUser;
  Stream<ChatUser?> get currentUserStream;
}
```

When the user logs in, out, or switches accounts, emit the new user (or null) on `currentUserStream`.

## Honest `flutter_bloc` Position (v1)

- In v1, `flutter_bloc` remains an internal direct dependency of `convokit`.
- The public API is 100% free of BLoC types: widgets accept plain data and contracts.
- Host apps can use Riverpod, Provider, or any state management without touching BLoC.
- Phase 7 will replace internal adapter blocs with direct store observation.
