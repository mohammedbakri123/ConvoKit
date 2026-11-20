---
name: convokit-messages
description: >
  Use when implementing chat screens, MessageListView, ConvoKitMessageComposer, handling optimistic sending, attachments, or implementing MessageRepository.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Messages & Composer

Complete guide to messaging, message lists, composers, and attachments.

## Public UI: `MessageListView`

```dart
MessageListView(
  conversationId: conversation.id,
  controller: myController, // Optional MessageListController
  onMessageTap: (message) => handleTap(message),
  onMessageLongPress: (message) => showOptions(message),
)
```

## Message Models & Lifecycle

### Sealed `ChatMessage` Hierarchy
- `TextMessage`: Contains `String text`.
- `MediaMessage`: Contains `ChatAttachment attachment` and optional `String? caption`.
- `CustomMessage`: Contains `String kind` and `Map<String, dynamic> payload`.

### Split State: `SendState` vs `DeliveryState`
- **`SendState`** (Core-local): `sending`, `sent`, `failed`.
- **`DeliveryState`** (Server/peer-driven, forward-only): `none`, `delivered`, `read`.
- A retry of a failed message updates `SendState` back to `sending` without modifying `DeliveryState`.

## Optimistic Sending & Idempotency

1. Client creates pending message with unique `localId`.
2. Message immediately appears in `MessageListView` with `SendState.sending`.
3. Server receives `localId` as idempotency key, echoes it back with confirmed `id`.
4. Core reconciles local pending message with confirmed remote message.
5. If send fails, `SendState.failed` displays retry button. Retrying uses the **same `localId`**.

## Media Attachments (`ChatMediaProvider`)

Media upload and message send are distinct two-step operations:

1. **Pick File**: Attachment state is `AttachmentState.local`.
2. **Upload**: Provider executes `upload(UploadRequest)`. Attachment moves to `uploading` with progress updates.
3. **Upload Success**: State becomes `uploaded` (`remoteId` and `url` populated).
4. **Message Send**: `MessageRepository.sendMessage` is called with the uploaded attachment.
5. **Upload Failure vs Send Failure**:
   - If upload fails: Retry re-uploads, then sends (same `localId`).
   - If send fails after successful upload: Retry sends ONLY (does NOT re-upload).
6. **Cancellation**: Cancelling an upload deletes the pending message entirely.
