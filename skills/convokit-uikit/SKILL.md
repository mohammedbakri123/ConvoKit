---
name: convokit-uikit
description: >
  Use when building chat with ConvoKit for Flutter (convokit). Triggers on ConvoKit, ConvoKitScope, ConversationsView, MessageListView, ConvoKitConversations, ConvoKitMessageList, ConvoKitMessageComposer, ChatCapabilities, ChatSession, and ChatResult. Entry point skill for ConvoKit routing to feature-specific skills.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit for Flutter — Orchestrator

Entry point skill for the `convokit` package. Routes to specialized skills based on task context.

## Project Setup

Add ConvoKit to your `pubspec.yaml`:
```yaml
dependencies:
  convokit: ^0.1.0
```

Import public APIs:
```dart
// Pure Dart contracts, core models, EventHub, and high-level views:
import 'package:convokit/convokit.dart';

// UI Kit component library (when using individual UI widgets):
import 'package:convokit/convokit_uikit.dart';
```

## Skill Routing

| Context / Need | Route to skill |
|----------------|----------------|
| Composition root, ConvoKitScope, session, capabilities, architecture | `convokit-core` |
| Conversation lists, recent chats, conversation cards | `convokit-conversations` |
| Message list, composer, header, attachments, send lifecycle | `convokit-messages` |
| Users, groups, group members, contacts | `convokit-users-groups` |
| Realtime events, EventHub, status updates, presence, typing | `convokit-events` |
| Theme, color palette, dark mode, typography, spacing | `convokit-theming` |
| Custom builders, view overrides, custom styling | `convokit-customization` |
| Atomic shared widgets (avatar, badge, status, receipt, shimmer) | `convokit-components` |
| Feature capabilities negotiation and fail-closed flags | `convokit-features` |
| App navigation, screen layouts, responsive split-view | `convokit-placement` |
| Error resolution, constructor validation, runtime checks | `convokit-troubleshooting` |
| Production readiness, offline persistence, error reporting | `convokit-production` |

## Core Principles

1. **Backend Agnostic**: ConvoKit defines pure Dart contracts. The host implements providers (or uses an existing backend adapter).
2. **Deterministic Validation**: Provider and capability mismatches throw `ArgumentError` immediately at `ConvoKit` construction.
3. **No Forced State Management**: Public APIs use plain Dart, streams, and `InheritedWidget`. Any state management (Riverpod, Provider, BLoC) works seamlessly in host apps.
4. **Clean Error Model**: All operational methods return `ChatResult<T>` with sealed `ChatResult.success(value)` or `ChatResult.failure(error)`.
