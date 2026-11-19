# ChatUI → UI-Only Library: Revised Phased Plan (v5)

**Repo:** `mohammedbakri123/ChatUI` (copy of CometChat UIKit for Flutter v6.3.0, branch `v6`)
**Goal:** a genuinely backend-agnostic, reusable Flutter messaging UI library —
not a CometChat fork with its API calls replaced.
**Library name:** ConvoKit — decided 2026-11-19. Package `convokit`.
**Status:** planning + API design only. No code changed, no Phase 1, no branches,
no commits, no dependencies removed. Revised 2026-11-19 (v5) from the v4 plan.

Companion document: [`API-DESIGN.md`](API-DESIGN.md) — the full public API
design (models, contracts, events, session, media, pagination, errors,
capabilities, DI, widget APIs, host-app examples). **The API design must be
approved before Phase 1 starts.** The two documents are one design: where
they disagree, the API design wins and the plan must be fixed to match.

## 1. Baseline (preserved from v1 — measured, not estimated)

- Library: `packages/cometchat_uikit/lib` — **843 Dart files, ~200k LOC**
- Whole repo: 1,469 Dart files, ~455k LOC. Tests alone: 446 files / ~216k LOC
  (they test SDK-coupled behaviour — not reusable as-is)
- SDK coupling: **~190/843 lib files import a CometChat SDK directly**
  (`cometchat_sdk` ~175 files, `cometchat_calls_sdk` ~28)
- Wider blast radius: **316 files (37%) touch SDK types** — most arrive via the
  public barrels, which re-export the SDKs wholesale
  (`lib/cometchat_chat_uikit.dart` re-exports all of `cometchat_sdk`)
- 59 files call `CometChat.*` statics directly from widgets/blocs
- Most-coupled files: `message_list_bloc.dart`, `conversations_bloc.dart`,
  `groups_bloc.dart`, `message_template_utils.dart`, the `CometChatUIKit` facade

### Already pure UI (lift as-is)

- Theming: `CometChatColorPalette` / typography / spacing / every `*Style` class
  — pure Flutter `ThemeExtension`s, zero SDK imports
- Generic widgets: avatar, badge, dialogs, typing indicator, the 15 message-bubble types
- i18n: 18 locales, ~33k LOC of pure strings
- Assets (icons, sounds), the message-template registry *pattern*
- BLoC skeleton: `flutter_bloc` + Equatable states + `Result<T>` — reusable once
  the data layer behind it is swapped
- Most of `chat_ui/src/extensions/` views (polls, stickers, link preview, …)

### Verified current mechanics (grounded in the code, 2026-11-19)

These behaviours exist today and the new design must preserve them as
library-owned behaviour, not backend behaviour:

- **Pagination is cursor-by-message-id**: `fetchPrevious` (older, before oldest
  id) / `fetchNext` (newer, after newest id) via `MessagesRequest`.
- **Optimistic sending uses `muid`**: a client-generated id mapped to the list
  index (`_muidIndexMap`) so a pending message is tracked before the server
  assigns an id; receipt notifiers exist per-muid and per-id.
- **Receipts**: `MarkAsRead` / `MarkAsDelivered` use cases, a
  `MessageReceiptStatus` enum, per-message `ValueNotifier`s, and a
  `disableReceipts` flag.
- **Send path**: `SendTextMessageUseCase` / `SendMediaMessageUseCase` in the
  composer bloc, over a datasource with `sendTextMessage` / `sendMediaMessage`.
- **Realtime**: per-BLoC SDK listeners with timestamped ids, removed in `close()`.
- **Reactions exist today in 53 files** (bloc, events, option sheet, action
  overlay, message list, l10n) — deferring them for v1 (§9) is a real scope
  cut, not the absence of a feature.
- **Message editing exists today in 43 files** (composer bloc/state,
  datasource, repository) — it is likewise cut for v1, like reactions.

## 2. Target architecture and ownership

```
┌─────────────────────────────────────────────────────────────────┐
│ Host app (any backend, any state management)                    │
│  Riverpod / Provider / BLoC / setState — the library doesn't care│
├─────────────────────────────────────────────────────────────────┤
│ ConvoKit UI (Presentation)                                      │
│  widgets, themes, bubbles, animations, l10n — widget-local UI    │
│  state only. Never contains messaging rules.                    │
├─────────────────────────────────────────────────────────────────┤
│ ConvoKit Core                                                   │
│  models (split send/delivery state, attachment state machine),  │
│  MessageCoordinator + per-conversation stores, EventHub (one    │
│  event subscription per instance), pagination orchestration,    │
│  dedupe, ordering, optimistic state machine, capability gating. │
│  Plain Dart — no flutter/widgets, no BLoC.                      │
├─────────────────────────────────────────────────────────────────┤
│ Public Contracts (plain Dart interfaces — see API-DESIGN.md)    │
│  repositories, event source, session (read-only), media         │
├─────────────────────────────────────────────────────────────────┤
│ Host adapters    REST, SignalR, Firebase, Supabase, custom…     │
│                  (written by the host, or shipped as examples)  │
├─────────────────────────────────────────────────────────────────┤
│ Backend          ASP.NET Core / Firebase / Supabase / …         │
│                  (the library must never know it exists)        │
└─────────────────────────────────────────────────────────────────┘
```

**Ownership map** (who owns what — the whole migration is judged against this):

| Piece | Owner |
|---|---|
| Pending messages, retry, reconciliation, dedupe, ordering, pagination orchestration, event coordination, capability gating | ConvoKit Core |
| Rendering, themes, bubbles, widget-local state | Presentation |
| Thin state adapters during migration (Core store → widget state) | Internal BLoC — no messaging rules inside blocs, ever |
| One-shot send/upload/fetch, transport, transport-level retries | Host adapters |
| Persistence, ordering authority, idempotency enforcement, receipt fan-out, auth | Backend / host |
| Login UI, tokens, session restore, sign-out | Host app (never the library) |
| Scope lifecycle (creation, kit replacement, disposal) and the EventHub | `ConvoKitScope` (`StatefulWidget`) + EventHub |

**Single package in v1 — with clean internal boundaries.** The library ships as
one Dart package (`convokit`) with internal directories:

- `lib/src/ui/` — widgets, themes, bubbles, l10n (imports core + contracts only)
- `lib/src/core/` — models, coordinator, stores, EventHub (imports contracts
  only; plain Dart, no `flutter/widgets`, no `flutter_bloc`)
- `lib/src/contracts/` — the public interfaces (imports nothing from ui/core)
- The InMemory fake lives in `example/`, **not** in the shipped package.

Boundaries are enforced by a dependency-rule test (a Dart test that scans
imports and fails if `ui` imports an adapter, if `contracts` imports
`ui`/`core` implementation details, or if `core` imports `flutter_bloc` or
`flutter/widgets`). Splitting into multiple packages (`convokit_core`,
`convokit_ui`, …) is deferred until the API is stable.

**Trade-offs of single-package-first:**

| | Single package (v1) | Multiple packages now |
|---|---|---|
| Refactoring during migration | Easy — move code across boundaries freely | Slow — every boundary move is a cross-package change + version bump |
| Versioning | One version | Coordinated versions from day one |
| Boundary enforcement | Convention + import test (weaker) | Compiler-enforced (stronger) |
| Consumer install | One dependency | Several, must stay in sync |
| Risk | A lazy import can quietly re-couple layers | Premature boundaries freeze a wrong API shape |

Recommendation: single package for v1, multi-package as a post-v1 option once
the public API has survived real adapters. This is a decision for approval (§9).

**Hard rule:** the library never knows about ASP.NET Core, SignalR, Firebase,
Supabase, or CometChat — no imports, no type names, no host strings, no
concepts (no `muid`, no `CometChat*`, no `uid`-as-identity beyond an opaque `id`).

## 3. Contracts — split by responsibility, kept small

No single `ChatBackend` god-interface. Focused contracts (full signatures in
`API-DESIGN.md` §§3–5, 7–8):

| Contract | Responsibility | Key methods |
|---|---|---|
| `ChatSession` (read-only) | Who is signed in (observable state) | `currentUser`, `currentUserStream` — no `signIn`/`signOut`/`restoreSession`; those are the host's |
| `UserRepository` | People | `getUser(id)`, `listUsers(page)`, `searchUsers(query)` |
| `ConversationRepository` | Conversation list | `listConversations(page)`, `getConversation(id)`, `markAsRead(id)`, `deleteConversation(id)` |
| `MessageRepository` | Messages in one conversation | `fetchMessages(conversationId, MessagePageRequest)`, `sendMessage(message)` (one-shot, no `retrySend`), `deleteMessage(id)`, `markAsDelivered/markAsRead`, `sendTyping(...)` |
| `GroupRepository` (optional) | Groups + membership | `listGroups`, `getGroup`, `listMembers`, `joinGroup`, `leaveGroup`, `addMembers`, `removeMember` |
| `ChatEventSource` | Realtime inbound | `events`, `connectionState` (`Stream<ConnectionStatus>` — the single connection authority), `connect()`, `disconnect()`, `reconnect()` — all returning `ChatResult` |
| `ChatMediaProvider` (optional) | Uploads (separate — §4) | `upload(...)` → `ChatResult<UploadedMedia>`, `delete(mediaId)` → `ChatResult<void>` |
| `ChatCapabilities` | What the backend supports | Value object; default = none, `basic()` = preset; no `calls`/`ai` fields in v1 |
| `ChatResult<T>` / `ChatError` | The one error convention | Sealed success/failure; returned everywhere, never thrown for operational failures |

**How a host provides them (public DI):** the host builds one plain Dart
composition root and hands it to the library — no service locator, no global
singletons, no BLoC required. Required providers are non-nullable; optional
ones (`groups`, `media`) are nullable, and "not implemented" is expressed by
absence (null) — never by a throwing stub. The `ConvoKit` constructor
validates provider/capability agreement and throws `ArgumentError` on
mismatch at `ConvoKit` construction (runtime validation in the constructor
body, release-safe — see `API-DESIGN.md` §11.1; the v4 text said "at scope
creation", which was wrong):

```dart
final kit = ConvoKit(
  session: MySession(...),
  users: MyUserRepository(...),
  conversations: MyConversationRepository(...),
  messages: MyMessageRepository(...),
  groups: MyGroupRepository(...),   // or omit → groups absent
  media: MyMediaProvider(...),      // or omit → media absent
  events: MyEventSource(...),
  capabilities: ChatCapabilities.basic(),
);
```

Widgets read the kit from context (`ConvoKitScope`, a `StatefulWidget` that
owns the EventHub lifecycle — see §5) or accept repositories explicitly per
widget. `ConvoKit` is a holder, not an interface with methods — it groups the
contracts so call sites stay short, without becoming the god-interface this
section forbids.

**Injection points, in order of preference:**

1. `ConvoKitScope` at the app root — the normal path.
2. Per-widget constructor overrides (e.g. a `MessageListView` wired to a
   different `MessageRepository`) — for embedding and testing.
3. Internal blocs (kept during migration) are constructed by the widgets from
   the repositories — consumers never see them (§5).

## 4. Media is a separate provider

`ChatMediaProvider` is independent of message sending, and returns `ChatResult`
like every other contract (no throwing convention). Upload and send are two
steps; the composer knows neither storage nor backend. Attachments carry an
explicit state machine (`local` → `uploading` → `uploaded` / `failed`, with
asserted invariants — see `API-DESIGN.md` §2.2):

- **Uploads:** images, video, files — `UploadRequest` via two factories,
  `UploadRequest.file(path, …)` or `UploadRequest.bytes(bytes, …)`; exactly
  one source is supplied (asserted). Returns `UploadedMedia` metadata
  (`id` → the attachment's `remoteId`, `url`, `thumbnailUrl?`, `mimeType`,
  `sizeBytes`, `name`).
- **Progress:** `UploadProgress {sentBytes, totalBytes}` callbacks; the composer
  renders the progress bar from these, not from backend knowledge.
- **Failure:** upload failure returns `ChatError(code: uploadFailed)` and the
  attachment moves to state `failed` (local file kept); retry re-uploads,
  then re-sends — same `localId`. Send failure after a good upload returns
  `sendFailed` with the attachment still `uploaded`; retry sends only, never
  re-uploads (§6).
- **Cancellation (defined, no ambiguity):** cancelling an upload aborts it,
  the provider returns `ChatError(code: cancelled)`, and Core **deletes the
  pending message entirely**. No draft is kept; there is no host-choice or
  draft-capability flag. Hosts that want drafts implement draft storage
  themselves, outside ConvoKit.
- **Delete:** best-effort where the storage supports it; unsupported backends
  report `capabilities.mediaDelete: false` and the UI hides the action.

**Composer flow:** pick file → pending message with attachment state `local`
→ `media.upload()` (attachment `uploading`, progress drives the bar) → on
success attachment `uploaded` (`url` + `remoteId`) → `messages.sendMessage()`
→ server confirms → pending message reconciles by `localId`. Upload failure
and send failure are distinct states with distinct retry actions.

## 5. No forced BLoC — and what "internal" honestly means

- The library **may keep `flutter_bloc` internally during migration** — it is
  the existing state backbone and ripping it out mid-migration would double
  the risk.
- **Consumers must never see it.** No bloc types in public constructors, no
  bloc types in public exports, no `BlocProvider` required in host apps.
  Widgets accept plain data + repositories + optional plain-Dart controllers
  (e.g. `MessageListController` for host-driven scroll/retry — no bloc).
- **Riverpod / Provider / any state management works** because the public API
  is plain Dart objects + `Stream`s + `InheritedWidget` scope. A Riverpod host
  creates the repositories in providers and passes the resulting `ConvoKit`
  into `ConvoKitScope`; the library does not know or care.
- **Scope lifecycle is not BLoC and not a bare `InheritedWidget`.**
  `ConvoKitScope` is a `StatefulWidget`: `initState` creates the EventHub
  once and attaches the kit; `didUpdateWidget` with a different kit identity
  (or a session-stream emission with a different user id) triggers the full
  reattach (teardown → clear → attach → connect, §6); `dispose`
  disconnects, cancels all subscriptions, and clears all Core stores.
  Nesting scopes is unsupported (debug assert). Hosts must keep the
  `ConvoKit` instance stable and only rebuild it when something actually
  changed — a new-but-equal kit still triggers reattach. Lifecycle work is
  asynchronous, so replacement while a connect is in progress is handled
  by the hub's generation token and serialized teardown/reattach
  (`API-DESIGN.md` §11.2): stale connect results are discarded,
  intermediate kits are torn down without connecting, and `dispose()`
  synchronously cancels all subscriptions and invalidates in-flight work.
- **Core is testable without BLoC.** The coordinator, stores, EventHub, and
  pagination logic are plain Dart and are tested with fake repositories —
  no bloc in the test.
- **The honest dependency statement.** In v1, `flutter_bloc` **remains a
  direct dependency** of the `convokit` package, used internally by thin
  adapter blocs. "BLoC is not part of the public API" and "the package has no
  BLoC dependency" are different claims — only the first is true in v1, and
  the README must say so. Do not claim the dependency is removed until
  Phase 7 removes it.
- **The boundary rule for new code:** a bloc may subscribe to a Core store
  and map Core state to widget state. A bloc that dedupes, retries, orders,
  or reconciles messages is a bug — those rules live in Core. Phase 7
  (post-v1) replaces the adapter blocs with direct store observation and
  deletes the dependency.

## 6. Messaging behaviour — the contract, not just the calls

The UI library owns the **client-side message lifecycle**; the backend owns
persistence and authority. The split (full definitions in `API-DESIGN.md`
§§5–6, 8):

| Behaviour | Library owns (Core) | Backend owns |
|---|---|---|
| Cursor pagination | Orchestration: directional requests (`latest`/`older`/`newer`), append/merge, `hasOlder`/`hasNewer`; stores the `newerCheckpoint` from the latest fetch | Cursor + checkpoint semantics, page contents, ordering authority. Cursors/checkpoints are opaque; Core never parses them |
| Catch-up limits | Bounded loop (max 10 newer pages); if the limit is hit with `hasNewer` still true, recovery is NOT complete — sets the gap flag, shows the banner, offers refresh | Serve the catch-up / latest page |
| Optimistic send | Create pending message with client `localId`, render immediately, reconcile on ack/echo/page | Accept `localId` as idempotency key, echo it back, assign server `id` |
| Retry | Core re-calls `sendMessage` with the same stored pending message (same `localId`) | Dedupe on `localId` — retry must not create a duplicate; a retry of an already-persisted `localId` returns success with the server message |
| Lost response | Mark failed with `outcomeUnknown: true`; retry or reconcile via later fetch/event | Persist once; answer duplicate `localId` with the existing message |
| IDs | `localId` always present (client uuid); `id` nullable until confirmed | Server `id`, server timestamps |
| Message state | Two fields: `SendState` (sending/sent/failed, Core-local) and `DeliveryState` (none/delivered/read, backend-driven, forward-only). A failed→retry move touches send state only | Generate delivery states for sent messages |
| Ordering | Display order: server timestamp, then server `id`; pending pinned at end by local time | Canonical order |
| Dedupe / idempotency | Single dedupe point in Core's store, by `localId` then server `id`, shared by pagination and events | Enforce `localId` uniqueness per sender |
| Receipts | Render states from `MessageStatusChanged` events; report received messages via `markAsDelivered/markAsRead` — when `receipts` is true; when false, no receipt UI of any kind, including the single sent tick and conversation-list indicators | Generate delivery states; deliver as `MessageStatusChanged` events |
| Typing | Show indicator, expire after ~5s without refresh | Relay typing signals |
| Reconnect / recovery | EventHub buffers live events, runs catch-up (or `latest` refresh + merge when catch-up is unavailable), refreshes the conversation list for unread counts, then resumes live distribution | Serve the catch-up / latest page |
| Identity change | Total teardown first (cancel uploads, discard pending, disconnect, clear all stores), then attach the new session — serialized via the generation token; rapid changes A→B→C connect only the latest | Nothing — the library never carries old-user state forward |
| Events vs truth | Events are hints within strict rules; on conflict, the fetch wins | Persisted truth |

**Capability negotiation:** every behaviour above is gated by
`ChatCapabilities` (default = none, `basic()` = preset). A backend that
doesn't support receipts reports `receipts: false` and receipt UI is hidden
— not rendered broken, not faked. In debug builds, requesting an unsupported
feature logs a warning instead of failing silently.

## 7. Revised phases

### Phase 0 — Freeze, measure, API design (this document + API-DESIGN.md)
- Branch off v6.3.0, keep it green. Record the baseline (§1) as the scoreboard.
- Produce and get approval for the API design before any implementation.
- Write one failing test: sample app builds against a fake backend.
- **Deliverables:** this plan (v4) + `API-DESIGN.md` (v4) + the decision
  summary in the approval message.
- **Gate:** API design approved by Mohammed, including the §9 decisions.
  **Nothing is implemented in this phase.**

### Phase 1 — Own models + cut the barrels & facade
- Introduce own model classes (`ChatUser`, `ChatGroup` with member rules,
  `ChatConversation` with direct/group factory invariants, `ChatMessage`
  sealed hierarchy with split `SendState`/`DeliveryState`, `ChatAttachment`
  with its state machine and asserted invariants).
- Introduce the §3 contracts + sealed `ChatResult`/`ChatError` +
  `ConvoKit` holder (required + optional providers, constructor validation) +
  `ConvoKitScope` as a `StatefulWidget` owning the EventHub skeleton.
- Remove SDK re-exports from the public barrels; replace the `CometChatUIKit`
  static facade with the host-supplied read-only `ChatSession`. Keep the SDK
  behind one internal adapter package so existing behaviour still works.
- **No widget changes yet.**
- **Deliverables:** models, contracts, scope + hub skeleton, barrels cut.
- **Gate:** library compiles with no `cometchat_sdk` import in any public
  file; sample app builds against a fake in-memory backend for auth + lists;
  the dependency-rule test exists and passes for the new directories.
- **Tests:** model invariant tests (conversation factories, attachment state
  asserts, send/delivery transition rules); contract compilation test (a
  consumer file importing only the public API compiles); no-`cometchat`-in-
  public-API grep test; `ConvoKit` constructor-validation tests (provider/
  capability mismatches throw `ArgumentError`, including in release builds —
  runtime checks, not asserts).

### Phase 2 — Data layer swap (per feature, one at a time)
- Replace each `*RemoteDataSourceImpl` with an implementation over the §3
  contracts. Repositories, use cases and blocs keep their shape — only
  datasources change. Order: conversations → users/groups → messages →
  message composer (composer last: it touches media + send).
- Add the media provider (§4) and rewire the composer onto it (upload and
  send as separate steps, attachment state machine, distinct failure states,
  cancel-deletes-pending).
- Migrate message templates to own message types.
- Remove reaction UI and message-editing UI from the migrated widgets
  (deferred, §9) — do not leave half-wired affordances behind.
- **Deliverables:** all list widgets rendering from a fake backend; media
  upload/send split in the composer; reactions + editing removed from v1 UI;
  optional providers wired (groups/media absent ⟺ capability false).
- **Gate:** no `CometChat.*` static calls remain in `chat_ui/` or `shared_ui/`;
  SDK-import count re-measured and recorded; fake-backend list tests pass.
- **Tests:** per-feature fake-backend tests (lists render, pagination older
  direction, search users); media upload-failure vs send-failure tests (§8);
  attachment state-transition tests.

### Phase 3 — Realtime, events & the message lifecycle
- Replace per-BLoC SDK listeners with the EventHub (`API-DESIGN.md` §8):
  one subscription, `connectionState` as the single authority, hub reconnect
  policy vs adapter transport attempts, stream-error handling, session-change
  and dispose handling, identity-change teardown, reconnect buffering +
  catch-up coordination (checkpoint, 10-page bound, gap flag).
- Implement the §6 lifecycle in Core: optimistic send, reconcile-by-`localId`,
  dedupe, ordering, receipts (report/consume split via `MessageStatusChanged`),
  typing, reconnect gap-fill.
- Provide a simulated event source in the sample app.
- **Deliverables:** EventHub wired; Core coordinator + stores; fake event
  source driving live updates; gap banner in `MessageListView`.
- **Gate:** the fake backend drives live updates (typing, presence, receipts,
  new messages) in the sample app; §8 lifecycle tests pass against the fake.
- **Tests:** optimistic send; failed send + retry same `localId`;
  idempotency (duplicate `localId` returns one message); reconciliation via
  echo event and via page; lost-response (`outcomeUnknown`) retry; older
  pagination; newer catch-up from a stored checkpoint (including a latest
  fetch that sets the checkpoint while `hasNewer` is false); checkpoint-null
  fallback; catch-up limit → gap flag set, banner shown, refresh completes;
  reconnect recovery + event/pagination dedupe; receipt forward-only updates
  via `MessageStatusChanged`; identity change A→B (old data gone, old
  connection closed, pending discarded); scope dispose (disconnect + clear);
  stream termination treated as transport failure with reconnect; kit
  replacement while a connect is in progress (stale connect result
  discarded, old source disconnected first); rapid identity changes A→B→C
  (only C connects, A/B torn down without connecting); scope dispose during
  a connect (no event reaches a store afterwards); event/session streams
  re-subscribed after termination (fresh subscription delivers new events);
  `currentUserStream` error/termination (disconnect, clear stores, wait for
  a new kit).

### Phase 4 — Calling: cut (v1) — port later
- **Decision (agreed direction, to confirm): cut for v1.** Remove `call_ui/` +
  `lib/src/call*` + the 3 touchpoints (message-header button, message-list
  call templates, facade lifecycle) and ship chat-only.
- The port design (`CallProvider`) is sketched in `API-DESIGN.md` §14 so the
  cut doesn't paint v1.1 into a corner.
- **Deliverables:** call code + touchpoints removed; no call UI reachable.
- **Gate:** chat-only build has zero `cometchat_calls_sdk` references.
- **Tests:** grep test for zero calls-SDK references; sample app has no call
  buttons.

### Phase 5 — AI: disable (v1) — port later
- **Decision (agreed direction, to confirm): disable for v1.** AI views call
  the SDK directly in `initState`; they are removed from the default build.
- The port design (`AiSuggestionsProvider`) is sketched in `API-DESIGN.md` §14.
- AI-assistant chat in v1.1 becomes plain messages to a user with a
  marker role, over the normal message port.
- **Deliverables:** AI views unreachable; AI skill content removed (§6 table).
- **Gate:** no AI view reachable in the v1 sample app; no SDK calls from views.
- **Tests:** sample-app navigation test asserting no AI entry points.

### Phase 6 — Sample app, docs, tests, publish
- Rebuild the sample app on the fake/local backend (extend the existing
  `assets/sample_data.json` superhero data to users/groups/conversations/
  messages — the fake-user pattern already exists, reuse it).
- Add the clean-consumer example app (Riverpod, no BLoC) — acceptance test 12/13.
- Rewrite README + `skills/` (they currently assume a live CometChat app).
- Rewrite the test suite (current 446 files test SDK behaviour).
- Rename the package, set version 0.1.0 (new library, not a continuation of 6.3.0).
- State the honest `flutter_bloc` dependency position in the README (§5).
- **Deliverables:** offline sample app; clean-consumer example; rewritten
  README/skills; rewritten tests; package 0.1.0.
- **Gate:** all §8 acceptance tests pass; docs show host integration with a
  fake backend; package publishes clean.

#### Non-code inventory — delete or rewrite? (decided 2026-11-19)

| Item | Verdict | Why |
|---|---|---|
| `skills/` (15 Kiro-style `SKILL.md` docs, ~250K) | **Rewrite** | They are agent guidance for *using* the library — genuinely useful, but every one is CometChat-specific: triggers on `CometChatUIKit`/`UIKitSettings`, install via CometChat's Cloudsmith URL, dashboard/App-ID steps. Rewrite to ConvoKit contracts: `convokit-*` skills for components, conversations, messages, theming, customization, events, users-groups, core, features, placement, troubleshooting (all rewritten, no CometChat concepts) |
| `skills/cometchat-flutter-calls`, `…-v5-to-v6-migration` | **Delete for v1** | Calls deferred (Phase 4); v5→v6 migration is CometChat history, meaningless for ConvoKit |
| AI-related skill content | **Delete for v1** | AI deferred (Phase 5); returns with the `AiSuggestionsProvider` port |
| `examples/ai_sample_app/` | **Delete for v1** | AI deferred; nothing in it works without the AI port. Git history keeps it |
| `examples/sample_app/` | **Rewrite** | Rebuilt on the fake/local backend (§6 above); login/credentials screens replaced by the fake session |
| `CHANGELOG.md` | **Reset, keep a fork note** | Current file is CometChat's v6.3.0 release history — not ConvoKit history. New file starts at 0.1.0 with one line: "Forked from CometChat UIKit for Flutter v6.3.0 (MIT)" |
| `README.md` | **Rewrite** | New name, new install, new host-integration example with a fake backend, honest `flutter_bloc` statement (§5) |
| `LICENSE` | **Keep + attribute** | MIT stays; add "Based on CometChat UIKit for Flutter, © CometChat, MIT" |
| `test/` (446 files) | **Rewrite per phase** | SDK-coupled tests are deleted as their feature migrates and replaced by contract/fake-based tests — not one big delete at the end |
| `.github/` (issue/PR templates, CODEOWNERS) | **Keep, update names** | Templates only, no workflows; update `CometChat` → `ConvoKit`, CODEOWNERS stays |
| `images/`, `assets/`, `analysis_options.yaml` | **Keep** | Pure UI assets and lint config; no backend in them |
| Root `pubspec.yaml` | **Rename** | Name `convokit`, version 0.1.0, `publish_to` stays none until publish |

### Phase 7 (post-v1) — Internal BLoC removal + multi-package (optional)
- Replace internal adapter blocs with direct Core-store observation;
  delete the `flutter_bloc` dependency.
- Re-evaluate splitting into `convokit_core` / `convokit_ui` packages.
- Port calls (`CallProvider`) and AI (`AiSuggestionsProvider`); define and
  implement the reactions contract (model, ops, events, UI, tests).
- **Gate:** decided separately after v1 ships; not a v1 blocker.

## 8. Acceptance criteria & release gates (aligned to the v1 scope)

The InMemory fake backend must prove actual independence. Each criterion is a
test, not a claim. Every criterion maps to a feature or responsibility defined
in `API-DESIGN.md` — nothing here tests a feature outside the v1 scope
(no message editing, no reactions, no calls, no AI).

1. **Offline sample app** — the sample app runs fully offline against the
   InMemory fake (run with network disabled; the fake records every call it
   receives; assert zero real network requests).
2. **No CometChat SDK dependencies** — `pubspec.yaml` contains no `cometchat_*`;
   `flutter pub deps` shows none; grep finds zero `package:cometchat_` imports.
3. **No CometChat types in public APIs** — the public barrels export no symbol
   from any `cometchat` package; a test compiles a consumer app importing only
   the public API and asserts no `cometchat` symbol resolves.
4. **No requests to CometChat infrastructure** — no `cometchat.io` /
   `cometchat.com` host strings anywhere in `lib/`; the offline run (§8.1)
   makes zero external requests.
5. **Optimistic sending, retry, idempotency, reconciliation** — send appears
   instantly as pending (`sending`); injected send failure shows failed state
   with retry; retry resends the same `localId`; the fake returns the
   already-persisted message for a duplicate `localId` and exactly one message
   is shown; a pending message is reconciled by an echo event and by a fetched
   page; a lost response (`outcomeUnknown`) retries to the same single message;
   a retried failed send leaves `deliveryState` at `none` throughout.
6. **Older pagination** — 105 fake messages, page size 30: scrolling up loads
   all pages, no duplicates, stable order, `hasOlder` false at the end.
7. **Newer catch-up + checkpoint** — a `latest` fetch sets `newerCheckpoint`
   even when `hasNewer` is false; after injecting 5 messages while
   "disconnected", reconnect catch-up from the stored checkpoint via `newer`
   pages delivers exactly those 5, no duplicates, in order. With a null
   checkpoint, catch-up falls back to the `latest` refresh with no duplicates.
8. **Catch-up limit + gap flag** — inject 400 messages (page size 30, limit
   10 pages): recovery ends with the gap flag set and the banner visible, and
   is NOT reported complete; tapping refresh completes recovery and all
   messages are present, in order, without duplicates.
9. **Reconnect recovery + dedupe** — disconnect, inject messages + duplicate
   events, reconnect: no message appears twice, no message is lost, unread
   counts re-sync from the list refresh.
10. **Receipts** — fake emits `MessageStatusChanged` delivered then read;
    ticks advance monotonically (`none → delivered → read`); a stale/backwards
    update is ignored; an update for an unknown message id is ignored; with
    `receipts: false` no receipt UI renders at all, including the single sent
    tick on sent messages and conversation-list receipt indicators.
11. **Media failures, separately** — the fake fails the Nth upload: UI shows
    upload-failed state, retry re-uploads then sends, same `localId`; the
    fake fails the Nth send after a good upload: UI shows send-failed state,
    retry sends only (assert the upload is not repeated); cancelling an
    upload deletes the pending message entirely.
12. **Unsupported capabilities hide UI** — with `ChatCapabilities()` (none):
    no attach button, no receipt UI of any kind (including the single sent
    tick), no typing indicator, no groups tab, no search field, no call/AI
    entry points. Each hidden feature is asserted. With `groups: null` +
    `groups: false` (and the same for media) the app builds and runs with no
    stubs; a mismatched provider/capability pair throws `ArgumentError` at
    `ConvoKit` construction (not at scope creation, and in release builds
    too).
13. **Consumer without BLoC** — the clean-consumer example app uses Riverpod,
    contains zero `flutter_bloc` imports, and renders conversations + messages.
14. **Clean Flutter app integration** — `flutter create` + add ConvoKit via path
    + render a conversation list against the fake backend; widget test green.
15. **Boundary test** — the dependency-rule test (§2) passes: no `ui` →
    adapter imports, no `contracts` → implementation imports, no `core` →
    `flutter_bloc`/`flutter/widgets` imports.
16. **No CometChat naming in public API** — grep over `lib/` public surface:
    zero occurrences of `CometChat`, `muid`, `CometChatUIKit` outside a
    clearly-marked historical note in docs.
17. **Scope lifecycle + identity change** — replacing the kit disposes the old
    EventHub (old connection closed, old data cleared) and connects the new
    one; changing user A → B discards A's pending messages and uploads,
    clears all stores, and never shows A's data afterwards; disposing the
    scope disconnects and clears everything; replacing the kit while a
    connect is in progress discards the stale result and disconnects the old
    source first; rapid A→B→C changes connect only C; disposing the scope
    during a connect leaves no event able to reach a store.
18. **Stream errors** — terminating either stream is treated as a transport
    failure (disconnect + reconnect policy), a malformed event is dropped
    without killing the stream, and an operational failure surfaces as a
    `disconnected` `ConnectionStatus`, never as a stream error; after
    termination the hub re-subscribes fresh on reconnect and new events
    arrive; a `currentUserStream` error/termination disconnects, clears
    stores, and waits for a new kit.
19. **Message updates are status updates only** — a `MessageStatusChanged`
    event moves a known message's delivery state forward; no edit behaviour
    exists or is tested in v1.

**Release gates:** Phase 0 gate (API approved) → Phase 1 gate → Phase 2 gate →
Phase 3 gate (§6/§8 tests) → Phase 4/5 gates (zero SDK references) → Phase 6
gate (all §8 tests + docs + publish). A phase is not "done" when it compiles;
it is done when its gate tests pass.

## 9. Decisions

The canonical decision list. **This list is identical in `API-DESIGN.md`
§17** — one status per decision, in both documents. (v3 listed single-package
under both "already decided" and "still needs approval" — that contradiction
is fixed here: it appears only below, as needing approval.)

### Decided (not re-opened)

- Library name ConvoKit, package `convokit`.
- Host-driven auth; ConvoKit stores no tokens.
- No CometChat types/concepts in public APIs; no forced state management;
  BLoC internal during migration; opaque backend ids; opaque cursors;
  fail-closed capabilities; Core owns UI behaviour, backend owns persistence
  and ordering.
- Docs disposition (skills rewrite, calls/AI/migration skills + `ai_sample_app`
  deleted for v1, CHANGELOG reset, LICENSE kept + attribution).

### Needs approval (recommended)

1. **Reactions: defer to v1.1 (Option B)** — instead of including them with
   a full contract now. Reason: smaller, more reliable v1.
2. **Read-only `ChatSession`** (no `restoreSession`/`signOut`). Reason:
   those operations belong entirely to the host.
3. **Directional pagination + checkpoint** (opaque cursors, `olderCursor` /
   `newerCursor` / `newerCheckpoint`, `messageCatchUp` capability). Reason:
   the only way to keep cursors opaque while supporting older history and
   newer catch-up unambiguously, with a resume token that exists even when
   nothing is newer yet.
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
    `outcomeUnknown` handling defined (`API-DESIGN.md` §6.4). Reason: the
    client cannot enforce it; the obligation must be explicit.
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

## 10. Risks & trade-offs

- **Split contracts raise the adapter author's burden.** A host must implement
  ~8 small interfaces instead of one. Mitigation: the InMemory fake is a
  complete reference implementation, and `ConvoKit` groups them so call sites
  stay short. Do not "fix" this by re-introducing a god-interface.
- **Own models = the biggest mechanical migration.** Every public signature
  changes; nothing from CometChat code is source-compatible. That is the
  point — but it means Phase 1 is the long pole and cannot be rushed.
- **Fail-closed capabilities can hide features silently.** A host that forgets
  to declare `receipts: true` gets no receipts UI and may think it's broken.
  Mitigation: debug-mode warnings when a widget is asked to render an
  unsupported feature.
- **Idempotency depends on the backend.** If a backend ignores `localId`,
  retries can duplicate. Client-side dedupe covers the echo path, not a
  backend that persists twice. This must be documented as a backend obligation.
  The `outcomeUnknown` case makes this visible instead of silent: a retry
  after a lost response is exactly where a non-deduping backend duplicates.
- **Catch-up fallback is best-effort.** With `messageCatchUp: false` or a
  null checkpoint, a reconnect recovers only what fits in the latest page;
  older missed messages wait for scroll-up. The gap flag makes the limit
  visible instead of silent — but a host that needs guaranteed catch-up must
  implement `newer` pages and a stable checkpoint.
- **Checkpoints can be missing or stale.** A backend that returns null
  checkpoints, or rejects a stored one, silently degrades catch-up to the
  latest-refresh fallback. Mitigation: debug warning when the fallback is
  used, and the acceptance test covering the null-checkpoint path.
- **Identity change discards work in progress.** Pending sends and in-flight
  uploads belonging to the old user are discarded, not retried under the new
  identity. Correct, but a host doing rapid account switching will see sends
  disappear — documented, not hidden.
- **Stale async lifecycle work.** A connect that completes after its kit was
  replaced could mark the wrong session connected or deliver the old source's
  events. Mitigation: the generation token (`API-DESIGN.md` §11.2) — specified,
  and covered by the Phase 3 tests.
- **Streams that cannot restart.** An adapter returning a single-subscription
  event stream breaks every reconnect after the first. Mitigation: the
  restartability contract (§8.3) — the fake backend implements it, and the
  acceptance tests re-subscribe after termination.
- **Single package = weaker boundary enforcement.** Only the import test guards
  the layers; discipline can slip. If the test is skipped, coupling returns.
- **BLoC stays a hard dependency in v1.** Consumers will see `flutter_bloc`
  in the dependency tree even though they never import it. Acceptable for v1;
  Phase 7 removes it. The risk is a consumer assuming the library is
  bloc-based — the README must state the position plainly (§5).
- **Cutting reactions + editing + calls + AI for v1 narrows the first release.**
  The library ships chat-only, without reactions or editing that the current
  code has. The risk is scope creep back in ("just one reaction button") —
  the Phase 2/4/5 gates exist to hold the line.
- **Honest sizing (unchanged from v1):** this is a re-platforming, not a
  refactor — ~200k LOC, ~a third of files touching SDK types. Phase 1 is the
  decision that determines everything else. The liftable-as-is core (theming,
  generic widgets, bubbles, i18n, assets, BLoC skeleton) is maybe a quarter of
  the library; the rest is data plumbing that has to be re-pointed, not deleted.

## 11. Rules for the work

- **No big-bang rewrite.** One phase at a time, sample app working after each.
- **Widgets last.** Models → contracts → datasources → events → widgets.
- **Measure after every phase:** re-run the SDK-import / SDK-token counts and
  record them. If a phase doesn't move the numbers, it didn't decouple anything.
- **No new `CometChat.*` static calls, ever.** New code talks to contracts only.
- **Contracts are small and plain Dart:** data in, streams out, no Flutter,
  no SDK types in signatures.
- **API design first:** no implementation change lands before its contract is
  written in `API-DESIGN.md` and approved.
- **No messaging rules in blocs.** Core owns send/retry/order/dedupe/reconcile;
  a bloc that re-implements any of them is reverted.
- **No feature added to v1 during corrections.** A correction that needs a new
  feature is a scope change and needs Mohammed's approval first.

## 12. What changed vs v4 (revision notes)

- §3: the scope-creation validation claim corrected — validation happens at
  `ConvoKit` construction (runtime, release-safe), not at scope creation.
- §5: async lifecycle safety added (generation token, serialized
  teardown/reattach, disposal guarantees).
- §6: receipt-capability precedence (no receipt UI of any kind when
  `receipts == false`, including the single sent tick and list indicators);
  identity-change row notes serialized rapid changes.
- §7: Phase 1 tests cover release-safe validation; Phase 3 tests cover
  async lifecycle and restartable streams.
- §8: tests 10, 12, 17, 18 updated to the v5 rules.
- §10: new risks added (stale async lifecycle work, streams that cannot
  restart).
- No features added to v1; no other section changed.
