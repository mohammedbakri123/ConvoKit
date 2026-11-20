---
name: convokit-events
description: >
  Use when implementing realtime event sources, handling WebSocket/SSE connections, and understanding EventHub event coordination.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Realtime Events & EventHub

Realtime architecture, event stream contract, and connection lifecycle.

## Contract: `ChatEventSource`

Backends stream realtime signals via `ChatEventSource`:

```dart
abstract class ChatEventSource {
  Stream<ChatEvent> get events;
  Stream<ConnectionStatus> get connectionState;
  Future<void> connect();
  Future<void> disconnect();
}
```

## Sealed `ChatEvent` Hierarchy

- `MessageReceived(ChatMessage message)`: New inbound message.
- `MessageStatusChanged(String conversationId, String messageId, DeliveryState status)`: Delivered or read receipt.
- `ConversationUpdated(ChatConversation conversation)`: Conversation metadata or unread count changed.
- `ConversationDeleted(String conversationId)`: Conversation removed.
- `UserPresenceChanged(String userId, bool isOnline, DateTime? lastActive)`: Presence updates.
- `TypingChanged(String conversationId, ChatUser user, bool isTyping)`: Typing signals (expires after ~5s).

## EventHub Coordination

The EventHub acts as the central coordinator:
1. **Single Authority**: One event subscription per active session.
2. **Buffer During Reconnect**: Inbound events arriving during disconnect are buffered until catch-up completes.
3. **Catch-Up & Recovery**:
   - Fetches newer messages from stored checkpoint.
   - Bounded recovery (max 10 pages). If gap limit is hit, shows the missing message banner.
4. **Deduplication**: Merges events and pagination responses by `localId` then `id`.
