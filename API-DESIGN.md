# ConvoKit — Public API Design (v5)

**Status:** proposal for approval. No code written against it yet.
**Companion:** [`UI-ONLY-PLAN.md`](UI-ONLY-PLAN.md) (migration phases, gates).
**Library name `ConvoKit` / package `convokit` — decided 2026-11-19.**
**Revision:** v5, 2026-11-19. Replaces v4. What changed vs v4 is listed in
§19; the headline changes are: runtime (non-assert) `ConvoKit` constructor
validation that throws `ArgumentError` in release builds too; one consistent
attachment `localPath` rule; asynchronous lifecycle safety (generation
tokens, serialized teardown/reattach, disposal guarantees); restartable
event-stream and session-stream contracts; and receipt-capability precedence
(`receipts == false` suppresses all receipt UI). No features were added to v1.

This document defines the public surface a host app programs against. Anything
not in this document is internal and may change without notice.

## 1. Design principles

1. **Plain Dart at the boundary.** Contracts are abstract classes with
   `Future`/`Stream` — no Flutter widgets, no BLoC, no third-party types.
2. **Small, focused interfaces.** One responsibility per contract; a host
   implements only what it uses (see §9 for what "uses" means).
3. **The library owns UI behaviour and client-side orchestration, never
   backend behaviour.** Rendering, ordering, optimistic state, pagination
   orchestration, retry, dedupe, event coordination — library. Persistence,
   ordering authority, fan-out, auth — host backend.
4. **Return, don't throw, for expected failures.** Every contract method
   reports operational failure the same way (§3). Programming errors are the
   only thing that throws, and they are bugs, not API.
5. **No CometChat concepts or naming.** No `CometChat`, no `muid`, no `uid`
   as a special concept (ids are opaque `String`s), no `CometChatUIKit`.
   See the naming table in §15.
6. **Fail-closed capabilities.** A feature the backend doesn't declare is
   hidden, not rendered broken.
7. **No forced state management.** The host's Riverpod / Provider / BLoC /
   `setState` never appears in this API. The library exposes plain objects
   and streams; the host wires them however it likes.
8. **One event subscription per ConvoKit instance.** Widgets never touch the
   transport (§8).

## 2. Core models and relationships

```dart
/// A person. `id` is opaque — the library never interprets it.
class ChatUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final UserPresence presence; // online, offline, away, unknown
  final bool isBlocked;
  const ChatUser({required this.id, required this.name, ...});
}

enum UserPresence { online, offline, away, unknown }

class ChatMember {
  final ChatUser user;
  final GroupRole role; // owner, admin, member
  const ChatMember({required this.user, required this.role});
}

class ChatGroup {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final GroupType type; // public, private, passwordProtected
  final int memberCount;
  /// Null = members not loaded; empty list = group has no members.
  final List<ChatMember>? members;
  const ChatGroup({...});
}
```

**Conversation invariants.** A conversation is exactly one of direct or
group — never both, never neither. Enforced by named factories over a private
constructor; `type` is derived, not settable:

```dart
class ChatConversation {
  final String id;
  final ChatUser? peer;   // direct only, null for groups
  final ChatGroup? group; // group only, null for direct
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversationType get type => peer != null
      ? ChatConversationType.direct
      : ChatConversationType.group;

  factory ChatConversation.direct({
    required String id,
    required ChatUser peer,
    ChatMessage? lastMessage,
    int unreadCount = 0,
    required DateTime updatedAt,
  }) => ChatConversation._(id: id, peer: peer, ...);

  factory ChatConversation.group({
    required String id,
    required ChatGroup group,
    ChatMessage? lastMessage,
    int unreadCount = 0,
    required DateTime updatedAt,
  }) => ChatConversation._(id: id, group: group, ...);

  ChatConversation._({required this.id, this.peer, this.group, ...})
      : assert((peer == null) != (group == null),
            'Exactly one of peer/group must be set');
}
```

### 2.1 Message state — send state is not delivery state

A failed send retried later must not violate the monotonic delivery-status
rule. So the two are separate fields with separate transition rules:

```dart
/// Outcome of Core's send attempts. Owned by Core; never set by events.
enum SendState { sending, sent, failed }

/// What the backend reported about a message WE sent. Only moves forward,
/// and only while sendState == sent. Set by MessageStatusChanged events (§8).
enum DeliveryState { none, delivered, read }

sealed class ChatMessage {
  /// Server-assigned id. Null until the server confirms the message.
  final String? id;
  /// Client-generated id, always present. The idempotency key (§6).
  final String localId;
  final String conversationId;
  final ChatUser sender;
  /// Client time while pending; server time after confirmation.
  final DateTime createdAt;
  final DateTime? serverCreatedAt;
  final SendState sendState;
  final DeliveryState deliveryState;
  /// Set when sendState == failed; null otherwise. Drives the retry UI.
  final ChatError? failure;
  final ChatMessage? repliedTo;
}

class TextMessage extends ChatMessage {
  final String text;
}

class MediaMessage extends ChatMessage {
  final ChatAttachment attachment;
  final String? caption;
}

class CustomMessage extends ChatMessage {
  /// Backend-defined payload the library renders via registered templates.
  final String kind;
  final Map<String, dynamic> data;
}
```

**Allowed transitions:**

| From | To | Trigger |
|---|---|---|
| `sending` | `sent` | `sendMessage` success, or reconciliation (§6.3) |
| `sending` | `failed` | `sendMessage` failure (incl. `outcomeUnknown`) |
| `failed` | `sending` | Retry — deliveryState untouched (stays `none`) |
| `sent` + `none` | `sent` + `delivered` | `MessageStatusChanged(delivered)` |
| `sent` + `delivered` | `sent` + `read` | `MessageStatusChanged(read)` |

Rules: delivery transitions require `sendState == sent`; a stale or
backwards delivery update is ignored; a failed message always has
`deliveryState == none`; received messages arrive with
`sendState == sent, deliveryState == none` (receipts of other people's
messages are not tracked on the message — the conversation's unread state
is separate, §8.6).

**UI representation** (derived from the pair, never from one field alone):

| sendState | deliveryState | UI shows |
|---|---|---|
| `sending` | `none` | Clock / spinner |
| `failed` | `none` | Warning + retry action |
| `sent` | `none` | Single tick |
| `sent` | `delivered` | Double tick |
| `sent` | `read` | Double tick, accent colour |

**Receipt-capability precedence.** When `capabilities.receipts == false`,
**all** receipt UI is suppressed — including the single tick for
`sent + none`. A sent message shows no indicator at all. The clock/spinner
for `sending` and the warning for `failed` are send-state indicators, not
receipt indicators, and are unaffected. Conversation-list receipt indicators
(ticks next to a conversation's last message) follow the same rule: hidden
when `receipts == false`. Unread counts are not receipt indicators and are
unaffected.

### 2.2 Attachments — a pending local file is a first-class state

A pending local file must exist in the model before any remote URL exists.
The attachment carries an explicit state machine with asserted invariants:

```dart
enum AttachmentState { local, uploading, uploaded, failed }

class ChatAttachment {
  /// Client-generated, stable across the attachment's life.
  final String id;
  /// Server media id. Non-null if and only if state == uploaded.
  final String? remoteId;
  final AttachmentKind kind; // image, video, file, audio
  /// Non-null while state is local, uploading, or failed. Optional when
  /// uploaded: the host may retain it for a local cache/thumbnail or drop
  /// it; rendering always uses `url`. One rule, stated here and in the
  /// invariant below — there is no second rule elsewhere in this document.
  final String? localPath;
  /// Non-null if and only if state == uploaded.
  final String? url;
  /// Non-null if and only if state == uploaded (when the backend provides one).
  final String? thumbnailUrl;
  final AttachmentState state;
  /// 0..1. Non-null if and only if state == uploading.
  final double? uploadProgress;
  /// Non-null if and only if state == failed.
  final ChatError? uploadFailure;
  final String? mimeType;
  final int? sizeBytes;
  final String? name;

  const ChatAttachment({...})
      : assert(state == AttachmentState.uploaded || localPath != null,
            'localPath is required until upload completes'),
        // No assert on localPath when uploaded: it is optional there
        // (retained for cache, or dropped) — see the field comment above.
        assert((url != null) == (state == AttachmentState.uploaded)),
        assert((remoteId != null) == (state == AttachmentState.uploaded)),
        assert((uploadProgress != null) == (state == AttachmentState.uploading)),
        assert((uploadFailure != null) == (state == AttachmentState.failed));
}
```

**State flow (driven by Core, §7):** `local` → `uploading` (progress updates
replace the attachment immutably) → `uploaded` (url + remoteId from the
returned `UploadedMedia`) or `failed` (uploadFailure set, local file kept).
After upload, `localPath` is optional — it may be retained for caching or
dropped; either way, rendering always uses `url`. `UploadedMedia.id`
becomes the attachment's `remoteId`. (v4 contradicted itself here: its
assert required `localPath` to be null once uploaded, while its text said a
cached copy may be retained. The rule above is the single consistent rule:
required until upload completes, optional afterwards.)

**Cancellation (defined, no ambiguity):** cancelling an upload aborts it, the
provider returns `ChatError(code: cancelled)`, and Core **deletes the pending
message entirely**. No draft is kept, and there is no host-choice or
draft-capability flag for this. If a host wants drafts, it implements draft
storage itself, outside ConvoKit — drafts are a host feature, not a library
behaviour.

Relationships: `ChatConversation` → `lastMessage: ChatMessage?` →
`sender: ChatUser`; `ChatGroup` → `members: List<ChatMember>` →
`user: ChatUser`. Widgets take these models, never backend entities.

## 3. Type-safe result and error contracts

One convention everywhere: repositories, event-source operations, and media
operations all report expected operational failures the same way — as a
returned value, never as a thrown exception.

### 3.1 `ChatResult<T>` — sealed, impossible to represent incorrectly

```dart
sealed class ChatResult<T> {
  const ChatResult();

  const factory ChatResult.success(T value) = ChatSuccess<T>;
  const factory ChatResult.failure(ChatError error) = ChatFailure<T>;

  /// Convenience for `ChatResult<void>`: success with no value.
  static ChatResult<void> ok() => const ChatSuccess<void>(null);

  bool get isSuccess;
  bool get isFailure;

  /// Branch on the outcome. The failure branch always carries the error.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChatError error) onFailure,
  });

  /// Transform a success value; a failure passes through unchanged,
  /// preserving the original error.
  ChatResult<U> map<U>(U Function(T value) transform);
}

final class ChatSuccess<T> extends ChatResult<T> {
  final T value;
  const ChatSuccess(this.value);
}

final class ChatFailure<T> extends ChatResult<T> {
  final ChatError error;
  const ChatFailure(this.error);
}
```

`map` on a failure returns the same `ChatError` — failures propagate without
losing information. There is no `valueOrNull`/`errorOrNull` pair that could
be misread; use `fold` or the `isSuccess`/`isFailure` guards with a cast
after checking.

### 3.2 `ChatError` — one error type, one meaning of retryable

```dart
enum ChatErrorCode {
  network,        // transport failure — retryable
  unauthorized,   // session invalid — host should re-authenticate
  forbidden,      // not allowed (e.g. not a member)
  notFound,
  validation,     // bad input (e.g. empty message, oversize file)
  uploadFailed,   // media upload failed — retryable, re-upload
  sendFailed,     // message send failed — retryable, re-send same localId
  cancelled,      // the caller cancelled — never an exception (§3.3)
  unsupported,    // backend lacks the capability
  unknown,        // outcome could not be determined (see outcomeUnknown)
}

class ChatError {
  final ChatErrorCode code;
  final String message;    // human-readable, for logs/debug UI
  final Object? cause;     // the underlying exception, if any
  /// True when the adapter cannot tell whether the backend persisted the
  /// operation (e.g. the response was lost after the send). Core treats
  /// this as failed-but-retryable: retry reuses the same localId and the
  /// backend dedupes (§6.4).
  final bool outcomeUnknown;

  const ChatError(this.code, this.message, {this.cause, this.outcomeUnknown = false});

  bool get isRetryable => switch (code) {
    ChatErrorCode.network ||
    ChatErrorCode.uploadFailed ||
    ChatErrorCode.sendFailed ||
    ChatErrorCode.unknown => true,
    _ => false,
  };
}
```

The UI switches on `code`, never on message strings.

### 3.3 Throw vs return — the rule

| Situation | Handling |
|---|---|
| Expected operational failure (network down, 403, not found, validation, upload/send failure, cancelled, unsupported) | **Returned** as `ChatResult.failure`. Adapters must convert their own exceptions into `ChatError` — they must not let them escape. |
| Cancellation | **Returned** as `ChatError(code: cancelled)`. Cancellation is a result, never an exception, even though a `CancellationToken` is used to request it. |
| Programming / configuration error (null `ConvoKit`, missing scope, calling a widget outside `ConvoKitScope`, a contract violated by the host's own code, a `ConvoKit` constructor invariant broken) | **Thrown** as `StateError` / `ArgumentError`. These are bugs. They must not be disguised as `ChatResult` failures. |
| Timeout | Mapped by the adapter to `ChatErrorCode.network`. |

## 4. Repository contracts

Five focused repositories. None of them knows about HTTP, sockets, or any
backend. Every method returns `ChatResult<T>` (§3). **There is no
`retrySend`: retry is Core's job (§6), not the adapter's.**

```dart
/// Session: who is signed in. Read-only observable state — see §10.
/// The host owns sign-in, sign-out, token storage and session restore.
/// The library never sees credentials and never calls a login endpoint.
abstract class ChatSession {
  ChatUser? get currentUser;
  Stream<ChatUser?> get currentUserStream;
}

abstract class UserRepository {
  Future<ChatResult<ChatUser>> getUser(String id);
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({String? cursor, int limit = 30});
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(String query, {String? cursor, int limit = 30});
}

abstract class ConversationRepository {
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({String? cursor, int limit = 30});
  Future<ChatResult<ChatConversation>> getConversation(String id);
  Future<ChatResult<void>> markAsRead(String conversationId);
  Future<ChatResult<void>> deleteConversation(String conversationId);
}

abstract class MessageRepository {
  /// Directional, opaque-cursor pagination — see §5.
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  );

  /// One-shot send. The adapter sends exactly the message it is given and
  /// returns the confirmed message (same `localId`, server `id` filled in)
  /// or a failure. It keeps no pending state and offers no retry.
  /// If the backend reports that `localId` was already persisted (a retry
  /// after a lost response), the adapter MUST return success with the
  /// already-persisted server message — not an error.
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message);

  Future<ChatResult<void>> deleteMessage(String messageId);

  /// Report that *received* messages were delivered/read by this user.
  /// These report client-side receipt state to the backend; the receipt
  /// states of *sent* messages arrive as `MessageStatusChanged` events (§8).
  Future<ChatResult<void>> markAsDelivered(String messageId);
  Future<ChatResult<void>> markAsRead(String messageId);

  /// Typing signals this user sends. Inbound typing arrives via events.
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping);
}

abstract class GroupRepository {
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({String? cursor, int limit = 30});
  Future<ChatResult<ChatGroup>> getGroup(String id);
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(String groupId, {String? cursor, int limit = 30});
  Future<ChatResult<void>> joinGroup(String groupId);
  Future<ChatResult<void>> leaveGroup(String groupId);
  Future<ChatResult<void>> addMembers(String groupId, List<String> userIds);
  Future<ChatResult<void>> removeMember(String groupId, String userId);
}
```

**Deliberately not in v1:** message editing, reactions, threads, polls,
stickers, group creation, group admin ops beyond add/remove member. Each is a
small additive method on the existing contracts later — the contracts are
designed to grow by addition, not by redesign. (Reactions: deferred by
explicit decision, §17.)

**Consistency note (audit):** every operation referenced by a widget, event,
capability, or lifecycle rule in this document exists in the contracts above.
User search is `UserRepository.searchUsers` (v1 search = user search only;
message search is v1.1). There is no operation in the widgets (§13) without a
contract method behind it.

## 5. Pagination and recovery

### 5.1 The contract — checkpoint, cursor, and flag are three different things

Cursors are opaque and backend-owned. Core stores them verbatim and never
parses them — it must not assume a cursor is a message id, timestamp,
sequence number, or anything else. Direction is explicit in the request, so
older-history pagination and newer-message catch-up can never be confused.
And the resume checkpoint is separate from the "another page exists" flag:

```dart
enum MessagePageDirection { latest, older, newer }

class MessagePageRequest {
  /// latest: cursor must be null — returns the newest page.
  /// older:  cursor is the `olderCursor` of the currently oldest page.
  /// newer:  cursor is the `newerCursor` of the currently newest page, or
  ///         the stored `newerCheckpoint` when starting catch-up (§5.2).
  final MessagePageDirection direction;
  final String? cursor;
  final int limit; // default 30
  const MessagePageRequest({required this.direction, this.cursor, this.limit = 30});
}

class ChatPage<T> {
  final List<T> items;
  /// Opaque cursor for the page *older* than this one, or null at the start.
  final String? olderCursor;
  /// Opaque cursor for the page *newer* than this one, or null when there
  /// is currently no newer page. Transient: advances as newer pages load.
  final String? newerCursor;
  /// Durable resume token for newer-message catch-up, established by a
  /// `latest` fetch. Present even when `hasNewer` is false: it anchors
  /// "the end of history as of this fetch", so catch-up after a
  /// disconnection starts from the right place even if nothing was newer
  /// at fetch time. Null means the backend cannot provide this guarantee.
  final String? newerCheckpoint;
  bool get hasOlder => olderCursor != null;
  bool get hasNewer => newerCursor != null;
}
```

List endpoints (conversations, users, groups, members) use the same
`ChatPage<T>` but only the older direction: `olderCursor` advances the list,
`newerCursor` and `newerCheckpoint` are always null for them. Only message
pagination uses all three fields.

### 5.2 The four operations

| Operation | Request | Response meaning |
|---|---|---|
| Open a conversation (latest) | `latest`, cursor null | Newest page; `olderCursor` scrolls back; `newerCursor` is null (nothing newer exists yet) — but `newerCheckpoint` is set: Core stores it as the catch-up anchor |
| Scroll up (older history) | `older`, cursor = oldest page's `olderCursor` | The next older window; repeat until `hasOlder == false` |
| Catch up after reconnect (newer) | `newer`, cursor = stored `newerCheckpoint` for the first page, then each page's `newerCursor` | Messages that arrived while disconnected; repeat until `hasNewer == false` (bounded — §5.5) |
| Event-stream interruption | — (handled by §8) | No silent loss: catch-up runs before live events resume (§8.4) |

### 5.3 Who creates and interprets cursors and checkpoints

The backend — and only the backend. Core's obligations are: store the
checkpoint from the most recent `latest` fetch (and refresh it from every
newer page response, which carries a checkpoint valid as of that response),
pass the right token back for the requested direction, and never inspect,
compare, or construct a token. A host adapter that cannot produce a token
for a direction returns a page with that field null, which Core reads as
"no further pages in that direction" (for cursors) or "no catch-up guarantee"
(for the checkpoint).

**If a backend cannot provide the checkpoint guarantee** — for example it is
offset-based, its cursors expire, or it has no stable "end of history"
token — it returns `newerCheckpoint: null` on every page. Core then treats
newer catch-up as unsupported for that conversation (even if
`capabilities.messageCatchUp` is true — the capability declares intent, the
null checkpoint is the runtime signal that the guarantee doesn't hold) and
uses the `latest`-refresh fallback (§5.4), logging a debug warning. A stale
checkpoint rejected by the backend (adapter returns `validation`/`notFound`
for it) is handled the same way: Core discards the checkpoint and falls back.

### 5.4 Backends without newer-message catch-up

Not every backend can serve a `newer` page. This is a capability, not an
error: `ChatCapabilities.messageCatchUp` (default false, §9). When false —
or when the checkpoint is null (§5.3):

- Core never issues a `newer` request.
- On reconnect it falls back to a fresh `latest` fetch and merges the result
  into the store by id (dedupe, §5.6). This recovers messages only if they
  fall inside the latest page; if more than one page arrived while offline,
  older missed messages are recovered by the user scrolling up (older
  pagination), not silently. This limitation is documented, not hidden.
- The UI shows no error for this — recovery is best-effort by design.

### 5.5 Catch-up limits — incomplete recovery is explicit, never silent

Catch-up is bounded: at most **10 newer pages** per recovery (a fixed v1
constant, documented here — not a host knob). If after 10 pages `hasNewer`
is still true, recovery is **not** marked complete:

- The hub sets `recoveryIncomplete = true` on the conversation's Core store.
- The store exposes `hasPossibleGap` (readable via `MessageListController`).
- `MessageListView` renders a non-blocking gap banner — "Some messages may
  be missing" — with a Refresh action. Refresh re-runs catch-up from the
  stored checkpoint with a fresh 10-page budget; if it completes
  (`hasNewer == false`), the flag clears.
- No code path may mark recovery complete while `hasNewer` is true after the
  limit. The store's completeness claim is exactly: "the store contains
  every message the backend returned through the pages fetched, in order,
  without duplicates" — and when the flag is set, the store additionally says
  so in the UI.

### 5.6 Duplicates across pagination and events

One dedupe point: Core's per-conversation message store, keyed by `localId`
first, then by server `id`.

- A page item whose `localId` matches a pending message **replaces** the
  pending message (reconciliation, §6.3).
- A page item whose server `id` is already in the store is ignored.
- An event for a known server `id` is ignored; an event with a known
  `localId` reconciles the pending message (§6.3).
- Ordering after merge: server timestamp, then server `id`; pending messages
  pinned at the end by local creation time.

## 6. Optimistic sending and retry — ownership

### 6.1 Who owns what

| Piece | Owner |
|---|---|
| The pending message (creation, storage, failure state, retry) | **ConvoKit Core** (`MessageCoordinator` + per-conversation store) |
| Sending one message over the wire | `MessageRepository.sendMessage` — one-shot, stateless |
| Uploading media | `ChatMediaProvider.upload` — one-shot, stateless |
| Retry decisions and retry execution | **Core** (triggered by the UI retry action or `MessageListController.retryFailed`) |
| Idempotency enforcement | Backend, keyed on `localId` |

The adapter never maintains a copy of pending messages. There is no
`retrySend` on any repository: a repository that had to remember pending
messages to retry them would be a second pending-message store, which is the
bug this section exists to prevent.

### 6.2 The send flow

1. The user sends (text or media). Core creates the pending message with a
   fresh `localId` (uuid), `sendState: sending`, `deliveryState: none`,
   stores it, and the UI renders it immediately.
2. For media, Core first runs the upload (§7) and attaches the returned
   `UploadedMedia`. Only then does it call `sendMessage`.
3. Core calls `messages.sendMessage(pendingMessage)`.
4. Success → Core replaces the pending message with the confirmed message
   (same `localId`, server `id` + server timestamp filled in,
   `sendState: sent`).
5. Failure → Core keeps the original pending message, sets
   `sendState: failed` + `failure: ChatError` (`deliveryState` stays `none`),
   and the UI shows retry.
6. Retry → Core calls `sendMessage` again with **the same stored pending
   message object** — same `localId`, same content. The backend dedupes on
   `localId` and must not create a second message.

### 6.3 Reconciliation — the pending message meets the server message

A pending message is reconciled (replaced by the confirmed server message)
whenever Core sees a server message with the same `localId`, from any source:

- the `sendMessage` success response;
- a `MessageReceived` event carrying that `localId` (the echo path — the
  server broadcast the message before the send response arrived);
- a page fetched by pagination containing that `localId`.

Reconciliation is by `localId` first, server `id` second. A reconciled
message keeps its position in the list; only its state/id/timestamps change.
Reconciliation sets `sendState: sent`; it never sets a delivery state.

### 6.4 The lost response

The backend accepted the message but the client never received the response
(network dropped after the send, timeout after persist). The adapter cannot
know the outcome, so it must return
`ChatError(code: unknown, outcomeUnknown: true)` — not a generic failure, and
not success.

Core's handling:

- The pending message is marked `failed` with that error (`deliveryState`
  stays `none`). The UI offers retry (and, for a careful host, a "check"
  that re-fetches the latest page).
- Retry resends the same `localId`. The backend recognises the duplicate and
  the adapter returns success with the already-persisted server message
  (contract obligation, §4). One message exists, one copy is shown.
- Independently, the next pagination fetch or incoming event carrying that
  `localId` reconciles the pending message (§6.3) even before any retry.

The client never invents a server `id` and never assumes the send failed
just because the response was lost.

### 6.5 Upload failure vs send failure — kept apart

The pending entry in Core holds two independent states:

- **Upload state** — the attachment's own `AttachmentState` (§2.2):
  `local` / `uploading` / `uploaded` / `failed`, with progress.
- **Send state** — the message's `SendState` (§2.1).

Retry logic in Core:

- Upload failed → retry re-runs the upload first, then sends, same `localId`.
- Upload succeeded, send failed → retry sends only. The already-uploaded
  `UploadedMedia` is kept on the pending message; the file is never
  uploaded twice for one `localId`.
- Upload cancelled → the pending message is deleted entirely (§2.2).
  Cancellation is not a retryable failure.

## 7. Media provider

Upload and send are separate contracts (§6.5). All media operations return
`ChatResult` — there is no throwing convention for them (§3).

```dart
/// Exactly one source must be supplied. Enforced by the factories + assert.
class UploadRequest {
  final String? localPath;
  final Uint8List? bytes;
  final AttachmentKind kind;
  final String? mimeType;
  final String? name;

  factory UploadRequest.file(
    String localPath, {
    required AttachmentKind kind,
    String? mimeType,
    String? name,
  }) => UploadRequest._(localPath: localPath, kind: kind, ...);

  factory UploadRequest.bytes(
    Uint8List bytes, {
    required AttachmentKind kind,
    String? mimeType,
    String? name,
  }) => UploadRequest._(bytes: bytes, kind: kind, ...);

  UploadRequest._({this.localPath, this.bytes, required this.kind, ...})
      : assert((localPath == null) != (bytes == null),
            'Exactly one of localPath/bytes must be supplied');
}

class UploadedMedia {
  /// Server media id. Core stores it as the attachment's `remoteId`.
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? sizeBytes;
  final String? name;
}

class UploadProgress {
  final int sentBytes;
  final int totalBytes;
  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;
}

class CancellationToken {
  void cancel();
  bool get isCancelled;
}

abstract class ChatMediaProvider {
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  });
  /// Best-effort delete. Backends without delete report
  /// `capabilities.mediaDelete == false` and the UI hides the action.
  Future<ChatResult<void>> delete(String mediaId);
}
```

**Composer flow (library-owned, backend-agnostic):**

1. User picks a file → pending `MediaMessage` appears immediately with an
   attachment in state `local` (`localPath` set, `url` null).
2. `media.upload()` runs; Core moves the attachment to `uploading` and
   progress callbacks drive the progress bar.
3. Success → attachment becomes `uploaded` (`url` + `remoteId` from
   `UploadedMedia`) → `messages.sendMessage()` → server confirms → pending
   reconciles by `localId` (§6.3).
4. Upload failure → attachment state `failed` with `uploadFailure` set;
   retry re-uploads then sends, same `localId`.
5. Send failure after a good upload → message `sendState: failed`,
   attachment stays `uploaded`; retry sends only (§6.5).
6. Cancel → the provider returns `ChatResult.failure(cancelled)`; Core
   deletes the pending message (§2.2).

## 8. Realtime events and centralized lifecycle

### 8.1 The event contract

One inbound stream. The host adapter translates its transport (socket, push,
polling — the library doesn't care) into these events. There is deliberately
no connection event here — connection state has exactly one authority, the
`connectionState` stream (§8.2).

```dart
sealed class ChatEvent {
  final DateTime receivedAt;
}

class MessageReceived extends ChatEvent {
  final ChatMessage message; // a new message (or the echo of our own send)
}
class MessageStatusChanged extends ChatEvent {
  /// The backend-generated delivery state for a message WE sent.
  /// The only status change events can carry in v1 (see §8.5).
  final String conversationId;
  final String messageId;
  final DeliveryState deliveryState; // delivered or read only
}
class MessageDeleted extends ChatEvent {
  final String conversationId;
  final String messageId;
}
class TypingChanged extends ChatEvent {
  final String conversationId;
  final ChatUser user;
  final bool isTyping;
}
class PresenceChanged extends ChatEvent {
  final ChatUser user;
  final UserPresence presence;
}
class ConversationUpdated extends ChatEvent {
  final ChatConversation conversation;
}

enum ConnectionState { connecting, connected, disconnected }

/// The authoritative connection status. `error` is present when the state
/// is `disconnected` because of a failure (see §8.3).
class ConnectionStatus {
  final ConnectionState state;
  final ChatError? error;
  const ConnectionStatus(this.state, {this.error});
}

abstract class ChatEventSource {
  Stream<ChatEvent> get events;
  /// The single authoritative connection-state mechanism (§8.2).
  Stream<ConnectionStatus> get connectionState;
  Future<ChatResult<void>> connect();
  Future<ChatResult<void>> disconnect();
  Future<ChatResult<void>> reconnect();
}
```

**Receipts, stated once and plainly.** The client *reports* delivery/read of
messages it received, via `MessageRepository.markAsDelivered/markAsRead`
(§4). The backend *generates* delivery states for messages the client sent
and delivers them as `MessageStatusChanged` events. The client *consumes*
those events to update sent-message delivery state. The library never
invents a receipt and never assigns the backend's job to the UI. `sendState`
is never set by an event — it is Core-local (§2.1).

### 8.2 Connection-state authority — one mechanism, and whose retries are whose

`connectionState` is the single authoritative source of connection state.
There is no `ConnectionChanged` event. The EventHub subscribes to it once;
widgets never observe it directly (the hub exposes derived UI state through
Core when a widget needs "reconnecting…" vs "offline").

Two different retry mechanisms exist and must not be confused:

| Mechanism | Owner | Behaviour |
|---|---|---|
| **Hub reconnection policy** | EventHub (Core) | On `disconnected`, the hub calls `reconnect()` with backoff 1s → 2s → 5s → 10s → 30s (cap), at most 5 attempts. After that it stays `disconnected` and exposes a manual retry (the hub's `retryConnection()`), which resets the backoff. The hub never calls `reconnect()` while the state is `connecting`. A `connect()` failure (returned `ChatResult.failure`) is treated as `disconnected` with that error. |
| **Adapter transport attempts** | Host adapter (invisible to the library) | The adapter's socket may retry internally — that is its own business. The library only observes `connectionState` transitions. The adapter must report its transport's actual state: it stays `connected`/`connecting` while its internal retries are still in play, and emits `disconnected` only when the transport is actually down. It must not flap: no spurious `disconnected` for a blip it recovers from internally. |

### 8.3 Stream errors — the `ChatResult` convention, applied to streams

Streams cannot return `ChatResult`, so the convention is expressed through
what the streams are allowed to do:

- **Operational failures never surface as stream errors.** A malformed
  single event is dropped by the adapter (it may log it); the stream
  continues. A transport failure surfaces as
  `connectionState == disconnected` with the `ChatError` in
  `ConnectionStatus.error` — not as a stream error.
- **Unexpected termination is a transport failure.** If either stream closes
  (`onDone`) or errors (`onError`) — adapter bug, transport collapse — the
  hub treats it as a transport failure: it cancels the subscription, calls
  `disconnect()`, marks the state `disconnected` with
  `ChatError(code: unknown)`, and follows the reconnect policy (§8.2).
  The hub re-subscribes fresh on every `connect()`/`reconnect()` attempt and
  cancels on `disconnect()`, so a dead stream can never linger.
- **Programming errors inside the adapter** (e.g. a null dereference that
  escapes as a stream error) are bugs, but the library still degrades
  gracefully per the rule above instead of crashing the UI; the error is
  logged in debug builds.
- `connect()` / `disconnect()` / `reconnect()` return `ChatResult<void>` —
  failures there are returned values, consistent with §3.

**Restartable streams — the subscription contract.** The hub subscribes
fresh to `events` and `connectionState` on every `connect()`/`reconnect()`
and cancels on `disconnect()`, so both getters must return broadcast
streams that support repeated sequential subscriptions. A getter that
returns a single-subscription stream, or a stream that is dead/completed
after its first use, violates the contract: the adapter must wrap a
single-subscription transport (e.g. in a broadcast `StreamController`) so
the getter is always re-subscribable. If a getter returns a terminated
stream, the hub treats the immediate termination as a transport failure
(above) and retries per policy; a stream that keeps terminating will keep
failing and is logged in debug. `ChatSession.currentUserStream` carries
the same restartability requirement (§10.2).

### 8.4 Who owns the lifecycle — the EventHub, owned by the scope

Exactly one subscription per `ConvoKit` instance, owned by a Core-level
component, the **EventHub**. Widgets never subscribe to `ChatEventSource`,
never call `connect`/`disconnect`/`reconnect`, and never manage a transport
connection. The hub is owned by the scope (§11), not by any widget.

| Action | Who calls it | When |
|---|---|---|
| `connect()` | EventHub | Scope mounts with a signed-in session; session changes to signed-in (§10) |
| `disconnect()` | EventHub | Scope disposed; session becomes null; identity change teardown (§10) |
| `reconnect()` | EventHub | Per the policy in §8.2 — never while `connecting` |
| Subscribe to `events` / `connectionState` | EventHub, once per `ConvoKit` instance | On `connect()`/`reconnect()`; cancelled on `disconnect()` and on scope dispose |
| Distribute events | EventHub → Core stores | Every event passes through the hub's single dedupe point (§8.5), then fans out to the per-conversation message stores, the conversation-list store, typing and presence registries |

### 8.5 Distribution, dedupe, and the event-vs-truth rules

- Widgets register with **Core stores** (message store, conversation store,
  typing registry), not with the event source. A widget mounting or
  unmounting subscribes/unsubscribes to a store — the transport is untouched.
- Every event passes through the hub's dedupe before distribution: by
  `localId`, then by server `id` (§5.6). A duplicated event can never create
  a duplicated message, because distribution and pagination share the same
  store and the same dedupe keys.
- Typing indicators expire library-side: if no `TypingChanged(isTyping: true)`
  refresh arrives within ~5s, the indicator clears even if no `false` arrives.

Persisted state comes from repository fetches; events are hints that update
the store within strict rules:

- `MessageReceived`: adds the message unless its `localId`/server `id` is
  already known (then it reconciles/ignores, §5.6).
- `MessageStatusChanged`: applies **only** to a message already in the
  store, only moves `deliveryState` forward (`none → delivered → read`),
  and only when that message's `sendState == sent`. An update for an
  unknown id, a backwards move, or an update to a failed/sending message
  is ignored. `sendState` is never set by an event.
- `MessageDeleted`: removes the message from the store (tombstone).
- On any conflict between an event and a fetch result, the fetch wins at the
  next page load.
- **Why one status event:** v3 had `MessageUpdated` (any status change) and
  `ReceiptChanged` (receipt state) overlapping — a receipt change *is* a
  message update. In v1 the only server-driven message change is delivery
  state, so one dedicated event, `MessageStatusChanged`, carries exactly
  that and nothing else. If v1.1 adds editing, it gets its own event type —
  it will not be smuggled into this one.

### 8.6 Reconnect and catch-up coordination; conversations not visible

On `connectionState` transitioning to `connected` after a disconnection:

1. The hub marks recovery in progress and **buffers live events** instead of
   distributing them.
2. For each visible conversation it runs catch-up (§5.2): `newer` pages from
   the stored checkpoint until `hasNewer == false`, bounded by §5.5 (10
   pages; the gap flag if the limit is hit), or — if `messageCatchUp` is
   false or the checkpoint is null — a `latest` refresh + merge (§5.4).
3. It refreshes the conversation list (`listConversations`, latest page).
   **Unread counts come from this refresh — they are backend-authoritative
   and are never computed client-side from events**, because events can be
   missed while disconnected.
4. It applies the buffered events, in order, through the same dedupe.
5. Recovery ends; live distribution resumes.

**Conversations not visible during the disconnection:** their cached copies
are marked stale on reconnect. They are not fetched immediately (that would
be unbounded work); they refresh on next view — the next list load or when
the conversation is opened. Their unread counts refresh with the list
refresh in step 3, which covers all conversations, visible or not.

Missed events are recovered by pagination, never by replay. The host adapter
is never asked to replay history.

## 9. Feature capabilities

One deterministic default. The default constructor is **no capabilities**
(all false). `ChatCapabilities.basic()` is a separately named preset for a
full-featured backend. There is no implicit "everything on". v1 has no
`calls`/`ai` fields — those return in v1.1 with their providers.

```dart
class ChatCapabilities {
  final bool receipts;
  final bool typing;
  final bool media;
  final bool mediaDelete;
  final bool groups;
  final bool search;       // v1: user search only (§4)
  final bool messageCatchUp; // newer-page catch-up after reconnect (§5.4)

  /// No capabilities. The default. Nothing is assumed.
  const ChatCapabilities({
    this.receipts = false,
    this.typing = false,
    this.media = false,
    this.mediaDelete = false,
    this.groups = false,
    this.search = false,
    this.messageCatchUp = false,
  });

  /// A full-featured backend: everything v1 supports.
  factory ChatCapabilities.basic() => const ChatCapabilities(
        receipts: true,
        typing: true,
        media: true,
        mediaDelete: true,
        groups: true,
        search: true,
        messageCatchUp: true,
      );
}
```

**Capability-to-feature table.** "Unavailable" always means the UI hides the
feature — it never renders it broken, and never renders it as if it worked.

| Capability | UI feature | Required repository / provider operation | Required events | When unavailable |
|---|---|---|---|---|
| `receipts` | Sent/delivered/read ticks on own messages; read receipts in lists | `markAsDelivered`, `markAsRead` | `MessageStatusChanged` | No receipt UI at all — not even the single sent tick; a sent message shows no indicator; conversation-list receipt indicators hidden too. Unread counts are unaffected (they are not receipt indicators) |
| `typing` | "X is typing…" indicator; sending own typing | `sendTyping` | `TypingChanged` | No indicator; composer never sends typing |
| `media` | Attach button, image/video/file bubbles, upload progress | `ChatMediaProvider.upload` | — | No attach button; media messages received still render if the backend sends them (rendering is not gated — only sending is) |
| `mediaDelete` | Delete uploaded media | `ChatMediaProvider.delete` | — | No delete action on media |
| `groups` | Groups tab, group conversations, member lists, join/leave | `GroupRepository.*` | `ConversationUpdated` (group changes) | No groups UI at all; direct conversations only |
| `search` (v1: users only) | User search in Users view and member pickers | `UserRepository.searchUsers` | — | No search field; plain lists only |
| `messageCatchUp` | Reconnect catch-up via `newer` pages | `fetchMessages` with direction `newer` | `connectionState` stream | Falls back to `latest` refresh + merge (§5.4); documented best-effort |
| — (v1.1) | Calls | `CallProvider.*` (§14) | `CallEvent` | No call UI anywhere |
| — (v1.1) | AI suggestions | `AiSuggestionsProvider.*` (§14) | — | No AI UI anywhere |
| — (deferred, no capability in v1) | Reactions, threads, message editing, polls, stickers | — (no v1 contract) | — | Not present in v1 at all; no capability flag exists for them until v1.1 defines the contract |

In debug builds, rendering a widget that needs an undeclared capability logs
a warning naming the capability — so a host that forgets `receipts: true`
finds out immediately instead of wondering why receipts never appear.

## 10. Session and authentication boundary

The host owns authentication end to end: login UI, OTP, Google sign-in,
tokens, account management, session restore on app restart. ConvoKit does
not store tokens, does not call a login endpoint, and does not show a login
screen.

**`ChatSession` is read-only observable state** — deliberately. Sign-in,
sign-out, and session restore belong entirely to the host, so they are not
in the contract:

```dart
abstract class ChatSession {
  ChatUser? get currentUser;
  Stream<ChatUser?> get currentUserStream;
}
```

The host flow:

```
Host signs in (own login UI, own auth service)
        │  OTP / password / SSO / anonymous — host's choice
        ▼
Host builds ChatSession (current user) + repositories + event source + media
        │
        ▼
ConvoKitScope(kit: ...) wraps the chat screens
        │
        ▼
Widgets render. EventHub connects (§8.4).
        │
        ▼
Session expires / user signs out (host's auth service):
  session emits null on currentUserStream (or the host rebuilds the
  scope with a signed-out kit) → EventHub disconnects, Core clears all
  cached data, library shows the host-supplied signed-out UI.
        │
        ▼
App restart: the HOST restores its cached session before building the
scope. ConvoKit needs no restore hook — it simply renders whatever
session it is given.
```

### 10.1 Session identity change — one user directly to another

When the current user changes from one non-null identity to another
(account switch, or the host re-authenticating as a different user), the
teardown is total and ordered. It is triggered by either a `ConvoKitScope`
kit replacement (§11) or a `currentUserStream` emission with a different
user id (same-user re-emission is a no-op):

1. **Teardown first, synchronously:** cancel in-flight uploads; discard
   all pending messages (they belong to the old user and must never be
   retried under the new identity); disconnect the old event source;
   cancel the old subscriptions.
2. **Clear all Core stores:** messages, conversations, users cache, typing,
   presence, checkpoints, gap flags. Nothing of the old user remains.
3. **Only then** attach the new kit/session and connect.

Old user data is never accessible after the change: stores are cleared
before any new fetch, so widgets observing stores see empty/loading, never
the old user's data. The old event connection cannot leak: the old
subscription is cancelled and the old kit reference dropped before the new
connection is made; the hub holds exactly one kit at a time. Sign-out
(session → null) and sign-in (null → user) use the same teardown path.
Rapid consecutive changes (A → B → C) are serialized through the same
mechanism as kit replacement (§11.2): each change increments the hub's
generation and enqueues behind the in-flight teardown; intermediate
identities are torn down without ever connecting, and only the latest
generation connects.

### 10.2 The session stream contract

`ChatSession.currentUserStream` has the same restartability requirement as
the event streams (§8.3): it must be a broadcast stream that supports
repeated sequential subscriptions, because the hub subscribes once per
attach and re-subscribes on every reattach. The hub reads `currentUser`
synchronously at attach for the initial value; the stream carries changes
only.

If `currentUserStream` emits an error or terminates unexpectedly
(`onError`/`onDone`), the hub treats the session as unobservable: it
disconnects, clears all Core stores (the sign-out path), and stops
observing the session. It does not crash and does not guess a user. The
library then waits for the host to attach a new kit (a scope rebuild with a
new session object); until then the scope renders the host-supplied
signed-out UI (or the child, if no `signedOutBuilder` was given). A
long-lived session stream is a host obligation; a dying session stream is a
host bug, logged in debug builds.

## 11. Dependency injection, scope lifecycle, and the Core / Presentation / BLoC boundary

### 11.1 The public shape — required vs optional providers

```dart
/// The composition root. A plain Dart holder — it groups the contracts so
/// call sites stay short. It is NOT an interface with methods.
/// Required providers are non-nullable; optional ones are nullable, and
/// "not implemented" is expressed by absence (null), never by a stub.
class ConvoKit {
  // Required in v1.
  final ChatSession session;
  final UserRepository users;
  final ConversationRepository conversations;
  final MessageRepository messages;
  final ChatEventSource events;
  final ChatCapabilities capabilities;
  // Optional in v1 — null means the feature is absent.
  final GroupRepository? groups;    // null ⟺ capabilities.groups == false
  final ChatMediaProvider? media;   // null ⟺ capabilities.media == false

  /// Not const: validation runs in the constructor body, so it throws
  /// `ArgumentError` in release builds too. (Asserts do not run in release —
  /// the v4 assert-only validation would have silently passed there.)
  ConvoKit({
    required this.session,
    required this.users,
    required this.conversations,
    required this.messages,
    required this.events,
    this.capabilities = const ChatCapabilities(),
    this.groups,
    this.media,
  }) {
    if ((groups == null) != !capabilities.groups) {
      throw ArgumentError(
        'groups provider and capabilities.groups disagree: '
        'pass a GroupRepository exactly when capabilities.groups is true.',
      );
    }
    if ((media == null) != !capabilities.media) {
      throw ArgumentError(
        'media provider and capabilities.media disagree: '
        'pass a ChatMediaProvider exactly when capabilities.media is true.',
      );
    }
    if (capabilities.mediaDelete && media == null) {
      throw ArgumentError('mediaDelete requires a media provider.');
    }
  }
}
```

**Constructor validation (fail fast, runtime):** a mismatch between a provider and
its capability is a programming error, thrown as `ArgumentError` **at
`ConvoKit` construction** — not at scope creation (the v4 text said scope
creation; that was wrong — the scope never validates, it only receives an
already-validated kit), not as a `ChatResult` failure at call time, and never
as a throwing stub the host has to write. The checks are plain `if` + `throw`
in the constructor body, not asserts, so they run in release builds too.
Widgets check the capability only; the constructor guarantees the provider
agrees, so no null-checks are scattered through widgets. A host that doesn't
support groups passes `groups: null` with `groups: false` and writes no
`GroupRepository` at all.

### 11.2 The scope — a `StatefulWidget` that owns the EventHub

An `InheritedWidget` alone cannot own a lifecycle (no `initState`,
no `dispose`, no `didUpdateWidget`). The scope is therefore a
`StatefulWidget` that creates the EventHub once and exposes the kit through
an internal inherited provider:

```dart
class ConvoKitScope extends StatefulWidget {
  final ConvoKit kit;
  final Widget child;
  /// Host-supplied signed-out UI. Rendered instead of `child` when the
  /// session has no current user. If null, `child` renders regardless.
  final Widget Function(BuildContext context)? signedOutBuilder;

  const ConvoKitScope({
    super.key,
    required this.kit,
    required this.child,
    this.signedOutBuilder,
  });

  static ConvoKit of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ConvoKitInherited>()!.kit;

  @override
  State<ConvoKitScope> createState() => _ConvoKitScopeState();
}

class _ConvoKitScopeState extends State<ConvoKitScope> {
  /// Created once in initState. Survives rebuilds.
  late final EventHub _hub;

  @override
  void initState() {
    super.initState();
    _hub = EventHub();
    _hub.attach(widget.kit); // subscribes to session stream, connects if signed in
  }

  @override
  void didUpdateWidget(ConvoKitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kit identity change (identical() comparison): full reattach —
    // teardown (§10.1), clear stores, attach new kit, connect if signed in.
    // Hosts must keep the ConvoKit instance stable (e.g. in a provider)
    // and only rebuild it when something actually changed; a new-but-equal
    // kit still triggers reattach.
    if (!identical(widget.kit, oldWidget.kit)) _hub.reattach(widget.kit);
  }

  @override
  void dispose() {
    _hub.dispose(); // disconnect, cancel subscriptions, clear stores
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Internal inherited provider — exposes kit (+ hub, internally) to descendants.
    // Nesting scopes is unsupported and debug-asserted: one scope per subtree.
    ...
  }
}
```

**Lifecycle rules, stated completely:**

- **Creation:** `initState` creates the hub once and attaches the kit; the
  hub subscribes to the session stream and connects if a user is signed in.
- **Replacement:** `didUpdateWidget` with a different kit identity (or a
  session-stream emission with a different user id, §10.1) triggers the full
  reattach: teardown → clear → attach → connect. Rebuilds with the same kit
  identity do nothing.
- **Disposal:** `dispose` disconnects, cancels all subscriptions, and clears
  all Core stores. Nothing outlives the scope.
- **Nesting:** unsupported. A scope built inside another scope's subtree is
  a programming error (debug assert). One scope per app subtree.

**Asynchronous lifecycle safety — generations, serialization, disposal.**
Lifecycle work is asynchronous (`connect()`/`disconnect()` are futures), so
a kit replacement can arrive while an earlier connection is still in
progress. The hub is built to make that safe:

- **Generation token.** The hub holds a generation counter (an `int`,
  starting at 0). Every attach, reattach, and dispose increments it. Every
  asynchronous lifecycle step captures the generation when it starts and
  checks it when it completes; a result arriving under a stale generation
  is discarded. A connect that finishes after a replacement must never mark
  the new session connected or deliver the old source's events.
- **Serialized teardown/reattach.** All teardown/reattach work runs on a
  single future chain. A reattach enqueues behind the in-flight operation;
  two teardowns or two connects never run concurrently. A reattach that
  arrives while a connect is in progress abandons the in-flight connect via
  the generation token (its result is ignored), but the old source's
  `disconnect()` is still awaited (serialized) before the new connect starts.
- **Bounded disconnect wait.** `disconnect()` is awaited for up to 5 seconds;
  after that the hub proceeds — its subscriptions were already cancelled
  synchronously, so the old source cannot deliver events in the meantime.
  (The 5-second bound is a v1 constant, documented here.)
- **Rapid consecutive changes.** Each change increments the generation and
  enqueues a reattach; if a queued reattach's generation is stale by the
  time its teardown completes, its connect is skipped and the next queued
  reattach runs. Intermediate kits are torn down without ever connecting.
  Only the latest generation connects.
- **Disposal guarantees.** `dispose()` synchronously cancels all
  subscriptions, increments the generation (invalidating any in-flight
  asynchronous work), and schedules teardown; `dispose()` never awaits
  network (it is synchronous in Flutter). After `dispose()` returns: no
  event from the old source can reach a store, no stale connect result can
  take effect, and no new connection can start. The `disconnect()` call
  itself runs best-effort after dispose.

**How a host wires it (any state management):** the host creates its
implementations however it likes — in Riverpod providers, in a `ChangeNotifier`,
in `main()` — and passes the finished `ConvoKit` into `ConvoKitScope`.
The library never constructs repositories, never reads a global, never
requires a specific DI package. For tests, the host passes fake
implementations; the example app's `InMemoryChatBackend` is the reference
fake and is the only fake the library ships guidance for (it lives in
`example/`, not in the published package).

**Controllers (plain Dart, no BLoC):** widgets that the host needs to drive
accept an optional controller, e.g. `MessageListController` with
`scrollToMessage(localId)`, `retryFailed(localId)`, `refresh()`, and a
`hasPossibleGap` getter (§5.5). A controller is an object with methods + a
`Stream` of state the host can listen to — usable from Riverpod, Provider,
or plain code. `retryFailed` asks Core to retry (§6.2); it is not a
repository call.

### 11.3 The three layers — and where BLoC actually sits

| Layer | Owns | May import | Must never contain |
|---|---|---|---|
| **Core** (`lib/src/core/`) | Message state, pagination orchestration, optimistic sending, retry, dedupe, ordering, event coordination (EventHub), typing/presence registries, capability gating | `contracts` only; plain Dart — no `flutter/widgets`, no `flutter_bloc` | Widgets, BLoC types, backend types |
| **Presentation** (`lib/src/ui/`) | Widgets, themes, bubbles, animations, l10n, widget-local UI state | `core`, `contracts` | Messaging rules (send/retry/order/dedupe), transport calls, repository calls made directly by widgets |
| **Internal BLoC** (migration only) | Thin adapters: subscribe to a Core store, map Core state → widget state | `core`, `contracts`, `flutter_bloc` | Messaging rules. A bloc that dedupes, retries, or orders messages is a bug — those rules live in Core |

**The honest dependency statement.** In v1, `flutter_bloc` **remains a direct
dependency** of the `convokit` package, used internally by the migration's
thin adapter blocs. "BLoC is not part of the public API" and "the package has
no BLoC dependency" are two different claims — only the first is true in v1,
and the README must say so. A consumer never constructs, imports, or
understands an internal bloc to use a public widget. Core logic is testable
independently of BLoC (plain Dart tests against the stores and the
coordinator, with fake repositories). Removing `flutter_bloc` entirely is a
post-v1 phase (UI-ONLY-PLAN Phase 7): replace the adapter blocs with direct
store observation and delete the dependency.

## 12. Public widget APIs

Widget names are the new names (old → new in §15). Every widget takes a
style object (the existing `*Style` system, unchanged in spirit), data or a
conversation id, and builder overrides — never a BLoC, never an SDK type.
There is no reaction UI in v1 (reactions deferred, §17).

```dart
class ConversationsView extends StatelessWidget {
  const ConversationsView({
    super.key,
    this.style,
    this.onConversationTap,
    this.listItemBuilder,   // override a row
    this.emptyBuilder,
    this.errorBuilder,
  });
}

class MessageListView extends StatelessWidget {
  const MessageListView({
    super.key,
    required this.conversationId,
    this.controller,        // optional MessageListController
    this.style,
    this.onMessageTap,
    this.onMessageLongPress,
    this.messageBuilder,    // override a bubble
  });
}

class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.conversationId,
    this.style,
    this.onSend,            // optional hook; default sends via Core (§6)
  });
}

class MessageHeader extends StatelessWidget {
  const MessageHeader({super.key, required this.conversationId, this.style});
}

class UsersView extends StatelessWidget {
  const UsersView({super.key, this.style, this.onUserTap});
}

class GroupsView extends StatelessWidget {
  const GroupsView({super.key, this.style, this.onGroupTap});
}

/// A full chat screen, composed from the pieces above — the host can also
/// compose them itself (header + list + composer) for custom layouts.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversationId, this.style});
}
```

Styling stays as today: per-widget `*Style` classes extending
`ThemeExtension`, merged at build time from `ConvoKitTheme` / `Theme.of`.
Theming is unchanged — it was already pure UI.

## 13. v1 inclusions and exclusions (explicit)

**In v1:**

- Conversations list, direct + group conversations, users list + user search,
  groups list + membership (join/leave/add/remove member).
- Text + media messages; directional cursor pagination (older + latest, newer
  where the backend supports it, with checkpoint + gap flag); optimistic
  sending with `localId`; retry with idempotency; reconciliation; dedupe;
  ordering.
- Delivery/read receipts (client reports, backend generates, client consumes
  `MessageStatusChanged` events); typing indicators; presence.
- Media upload with progress, cancellation (pending message deleted), and
  delete where supported.
- Message delete (own messages; backend enforces permissions).
- Theming, bubbles, i18n (18 locales), assets.
- InMemory fake backend in `example/` + offline sample app + clean-consumer
  (Riverpod) example app.

**Not in v1 (v1.1 or later):**

- Reactions — deferred by explicit decision (Option B, §18). The current
  library has reaction UI in 53 files (verified 2026-11-19); v1 ships
  without reaction affordances and regains them with the v1.1 contract.
- Message editing — no contract, no UI, no tests in v1. (The current library
  has editing in 43 files; it is cut for v1 like reactions.)
- Threads, polls, stickers, message search, group creation, group admin ops
  beyond add/remove member.
- Calls (`CallProvider`), AI suggestions (`AiSuggestionsProvider`).
- `flutter_bloc` removal (Phase 7) and multi-package split (post-v1 option).

## 14. Deferred ports (sketched now so v1 doesn't block them)

```dart
/// v1.1 — voice/video calling behind a port, mirroring §4's shape.
abstract class CallProvider {
  Future<ChatResult<CallSession>> initiateCall(CallRequest request);
  Future<ChatResult<void>> acceptCall(String callId);
  Future<ChatResult<void>> rejectCall(String callId);
  Future<ChatResult<void>> endCall(String callId);
  Stream<CallEvent> get callEvents;
}

/// v1.1 — AI suggestions behind a port. The view never calls a backend directly.
abstract class AiSuggestionsProvider {
  Future<ChatResult<List<String>>> smartReplies(String conversationId);
  Future<ChatResult<List<String>>> conversationStarters(String conversationId);
  Future<ChatResult<String>> conversationSummary(String conversationId);
}
```

Reactions (v1.1) will need their own contract before implementation: a
reaction model, add/remove operations on `MessageRepository` (or a dedicated
`ReactionRepository`), realtime reaction events, message-model integration,
capability behaviour, UI behaviour, and tests. None of that is defined here
on purpose — defining it now would be scope creep into v1.

## 15. Naming — old → new (no CometChat concepts in the public API)

| Old (CometChat UIKit) | New (ConvoKit) |
|---|---|
| `CometChatUIKit` facade | `ConvoKit` holder + `ChatSession` |
| `CometChatMessageList` | `MessageListView` |
| `CometChatConversations` | `ConversationsView` |
| `CometChatMessageComposer` | `MessageComposer` |
| `CometChatMessageHeader` | `MessageHeader` |
| `CometChatUsers` / `CometChatGroups` | `UsersView` / `GroupsView` |
| `User` / `Group` / `Conversation` | `ChatUser` / `ChatGroup` / `ChatConversation` |
| `BaseMessage` / `TextMessage` / `MediaMessage` | `ChatMessage` (sealed) / `TextMessage` / `MediaMessage` |
| `muid` | `localId` |
| `UIKitSettings` (appId/region/authKey) | deleted — host-owned, never in the library |
| `CometChat*Events` buses | `ChatEventSource.events` via the EventHub |
| `*RequestBuilder` / `*Request` (SDK) | `MessagePageRequest` / `ChatPage` + opaque cursors |
| `cometchat_chat_uikit` package | `convokit` |

Audit note: the strings `CometChat`, `muid`, and `uid` appear in this document
only in this table (as "old"), in the fork-attribution note, and in the
baseline history in the plan. They do not appear in any new public API name,
type, or contract.

## 16. Realistic host-app examples

### A. Minimal app (Riverpod, fake backend — the acceptance-test shape)

```dart
// Host code. No BLoC anywhere. The fake lives in example/.
final kitProvider = Provider<ConvoKit>((ref) {
  final fake = InMemoryChatBackend(); // reference fake, seeded with demo data
  return ConvoKit(
    session: fake.session,
    users: fake.users,
    conversations: fake.conversations,
    messages: fake.messages,
    groups: fake.groups,
    media: fake.media,
    events: fake.events,
    capabilities: ChatCapabilities.basic(),
  );
});

class App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConvoKitScope(
      kit: ref.watch(kitProvider),
      child: MaterialApp(home: ConversationsView(
        onConversationTap: (c) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id)),
        ),
      )),
    );
  }
}
```

### B. Real backend adapter (shape only — the host writes this)

```dart
// A REST + SignalR adapter, sketched. The library never sees Dio/SignalR.
class RestMessageRepository implements MessageRepository {
  RestMessageRepository(this._api, this._currentUserId);

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async {
    final res = await _api.get('/conversations/$conversationId/messages', query: {
      'direction': request.direction.name,
      'cursor': request.cursor,
      'limit': request.limit,
    });
    return ChatResult.success(ChatPage(
      items: (res['items'] as List).map(ChatMessageMapper.fromJson).toList(),
      olderCursor: res['olderCursor'] as String?,
      newerCursor: res['newerCursor'] as String?,
      newerCheckpoint: res['newerCheckpoint'] as String?,
    ));
  }

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) async {
    // localId goes on the wire as the idempotency key.
    final res = await _api.post('/messages', body: {
      'localId': message.localId,
      'conversationId': message.conversationId,
      'text': (message as TextMessage).text,
    });
    return ChatResult.success(ChatMessageMapper.fromJson(res));
  }
  // …remaining methods mirror this shape. No retrySend, no pending store.
}
```

### C. Host-driven control without BLoC

```dart
final controller = MessageListController();

// Host retries a failed message from its own UI (e.g. a snackbar action).
// The retry is executed by Core with the same localId (§6.2).
await controller.retryFailed(failedMessage.localId);

// Host scrolls to a message (e.g. from a search result):
controller.scrollToMessage(message.localId);

// Host reads the catch-up gap flag (§5.5):
final bool gap = controller.hasPossibleGap;

MessageListView(conversationId: id, controller: controller)
```

## 17. Decisions that require Mohammed's approval

The canonical decision list. **This list is identical in `UI-ONLY-PLAN.md`
§9** — one status per decision, in both documents. Anything marked
"Decided" is not re-opened here.

**Decided (not re-opened):** library name ConvoKit; host-driven auth;
no CometChat types/concepts in public APIs; no forced state management;
BLoC internal during migration; opaque backend ids; opaque cursors;
fail-closed capabilities; Core owns UI behaviour, backend owns persistence
and ordering; docs disposition (skills rewrite, calls/AI/migration skills +
`ai_sample_app` deleted for v1, CHANGELOG reset, LICENSE kept + attribution).

**Needs approval (recommended):**

1. **Reactions: defer to v1.1 (Option B)** — instead of including them with
   a full contract now. Reason: smaller, more reliable v1.
2. **Read-only `ChatSession`** (no `restoreSession`/`signOut`). Reason:
   those operations belong entirely to the host.
3. **Directional pagination + checkpoint** (opaque cursors, `olderCursor` /
   `newerCursor` / `newerCheckpoint`, `messageCatchUp` capability). Reason:
   the only way to keep cursors opaque while supporting older history and
   newer catch-up unambiguously.
4. **Sealed `ChatResult`**. Reason: the nullable-pair shape could represent
   invalid states.
5. **Core-owned retry, no `retrySend`**. Reason: adapters must not keep a
   pending-message store.
6. **Capabilities default = none; `basic()` is the preset.** Reason: one
   deterministic default, fail-closed.
7. **`UploadRequest` factories** (file xor bytes, asserted). Reason:
   resolves the ambiguity with an enforceable rule.
8. **v1 search = user search only** (message search v1.1). Reason: keeps
   the v1 scope honest.
9. **Packaging: single package v1** (recommended) vs. multiple packages
   from the start. Reason: easy cross-boundary refactoring during migration.
10. **Idempotency: `localId` as backend obligation**, with the
    `outcomeUnknown` handling defined (§6.4). Reason: the client cannot
    enforce it; the obligation must be explicit.
11. **BLoC endgame: Phase 7 removal** (recommended) vs. keeping `flutter_bloc`
    internal indefinitely. Reason: cleaner, but more work.
12. **`StatefulWidget` scope owning the EventHub** (new in v4). Reason: an
    `InheritedWidget` alone cannot own a lifecycle.
13. **One connection authority: `connectionState` stream only** (new in v4;
    `ConnectionChanged` event deleted). Reason: two mechanisms for one fact
    will disagree.
14. **Send state separated from delivery state** (new in v4). Reason: a
    retried failed send must not violate the monotonic delivery rule.
15. **Attachment state machine + cancel-deletes-pending rule** (new in v4).
    Reason: a pending local file must exist in the model before any URL;
    cancellation had an ambiguous host-choice draft rule.
16. **Stream-error convention** (new in v4). Reason: streams cannot return
    `ChatResult`; the convention had to be stated or failures would be
    silent or fatal.
17. **Optional providers with constructor validation** (new in v4). Reason:
    "implement only what you use" contradicted mandatory providers.
18. **Catch-up limit (10 pages) + explicit gap flag** (new in v4). Reason:
    recovery must never silently claim completeness it doesn't have.
19. **Identity-change teardown** (new in v4). Reason: old user data and old
    connections must not leak into a new session.
20. **`MessageStatusChanged` as the single status event** (new in v4).
    Reason: `MessageUpdated` and `ReceiptChanged` overlapped; v1 has exactly
    one server-driven status change.

## 18. Open questions (for approval, not assumed)

1. Should the InMemory fake ship inside the published package as a
   `convokit_fake` dev helper, or stay in `example/` only? Proposal:
   `example/` only in v1.
2. Message editing / threads / polls / stickers: v1.1 scope, or does v1 need
   any of them for parity with a specific host app? Proposal: v1.1.
3. The catch-up page limit is fixed at 10 in v1. Should it be a `ConvoKit`
   configuration value instead? Proposal: fixed — one less knob until a
   host demonstrates a need.

## 19. What changed vs v4 (revision notes)

- §2: attachment `localPath` rule made consistent — required until upload
  completes, optional afterwards (retained for cache or dropped); the v4
  assert that forced it null when uploaded is removed. Receipt-capability
  precedence stated: `receipts == false` suppresses all receipt UI,
  including the single sent tick and conversation-list indicators.
- §8: restartable-stream subscription contract added (§8.3): `events` and
  `connectionState` getters must return broadcast streams supporting
  repeated sequential subscriptions; the hub subscribes fresh on every
  connect/reconnect.
- §10: session-stream contract added (§10.2): `currentUserStream` must be
  restartable; on error/termination the hub disconnects, clears stores
  (sign-out path), and waits for a new kit. Rapid identity changes
  serialized via the generation mechanism (§10.1).
- §11: `ConvoKit` constructor is no longer `const`; provider/capability
  validation is runtime `if` + `throw ArgumentError` in the constructor
  body (release-safe), and the claim is corrected: validation happens at
  `ConvoKit` construction, not at scope creation. Asynchronous lifecycle
  safety added (§11.2): generation token, serialized teardown/reattach,
  bounded disconnect wait (5s), disposal guarantees.
- §9: receipts row updated to the precedence rule.
- No features added to v1; no other section changed.
