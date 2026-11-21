# ConvoKit Showcase App

Offline, 100% library-component Flutter showcase for **`convokit` `0.1.0`** (Phase 7 SDK-free & BLoC-free), redesigned in 2026 around **iOS 26 Liquid Glass**, **Material 3 Expressive**, and **UI/UX Pro Max v2.0** quality rules. Every messaging screen, directory, search flow, extension bubble, media viewer, and atomic primitive is composed exclusively from `package:convokit/convokit.dart` and `package:convokit/convokit_uikit.dart` — zero custom `messageBuilder`, zero hand-rolled message bubbles, and zero hand-rolled `ListView`s.

## Quick Start

Run from `examples/showcase_app/` (Dart `>=3.10.8 <4.0.0`, Flutter `>=3.38.9`):

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

### Repository-Wide Verification Gates

Run from the repository root to verify zero SDK/BLoC dependencies alongside the Showcase suite:

```bash
# 1. Library analyzer, Criterion-2 No-SDK Gate & additive L1–L6 + overflow tests
cd packages/cometchat_uikit
flutter analyze
flutter test test/convokit/criterion_2_no_sdk_dependencies_test.dart \
  test/convokit/zero_calls_sdk_test.dart \
  test/shared_ui/avatar_monogram_palette_test.dart \
  test/chat_ui/message_list_tail_and_padding_test.dart \
  test/chat_ui/message_composer_glass_style_test.dart \
  test/chat_ui/message_header_glass_style_test.dart \
  test/chat_ui/directory_list_padding_test.dart \
  test/chat_ui/message_list_motion_test.dart \
  test/chat_ui/extensions/sticker_keyboard_overflow_test.dart \
  test/convokit/message_list_view_overflow_test.dart
bash tool/count_sdk_imports.sh --check

# 2. Showcase analyzer, tests & Android debug APK
cd ../../examples/showcase_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## 2026 Design System Architecture (Liquid Glass + M3 Expressive + UI/UX Pro Max)

The Showcase applies a **Master + Overrides** design-system-first architecture tuned to **Variance 5 / Motion 6 / Density 5**:

- **iOS 26 Liquid Glass (Navigation & Control Layer ONLY):** `GlassSurface` (`lib/widgets/glass_surface.dart`, `.regular` fill at 78% opacity, `blurSigma: 24`, specular hairline border, subtle ambient shadow) is strictly restricted to `FloatingGlassTabBar`, `CollapsingGlassHeader`, `ConvoKitMessageHeader`, and the floating pill `ConvoKitMessageComposer`. Content cards, list rows, message bubbles, and media containers **never** use glass (enforced by automated static guardrail tests in `test/coverage_audit_test.dart`).
- **Material 3 Expressive (`surfaceContainer` Depth Ladder & One Hero Moment Per Screen):** Screens establish hierarchy through the 5-step `surfaceContainerLowest` -> `surfaceContainerHighest` tonal ladder, concentric corner radii (`30` outer nav capsule / `22` active pill, `24` hero card / `16` nested card, `28` sheets, `999` full-pill buttons), and **one expressive hero moment per screen** (`UpdatesTab` Studio Showcase Hero Card, `CallsTab` Status Hero Card, `SettingsTab` Nadia Haddad Profile Hero Card) while keeping all supporting sections calm.
- **UI/UX Pro Max v2.0 Quality Guardrails (Priority 1–10):**
  - **Accessibility & Contrast:** `>=4.5:1` WCAG 2.1 contrast across Light and Dark modes (verified by `ShowcaseTokens.contrastRatio`), explicit `tooltip` / `Semantics(label: ...)` on every icon-only button, decorative dividers/tails wrapped in `ExcludeSemantics`, and presence/delivery status paired with text labels and distinct receipt tick geometry.
  - **Touch & Spacing:** Minimum `44x44` logical px hit targets (`ShowcaseTokens.minTouchTargetSize`) and `>=8px` spacing between adjacent controls.
  - **Icons & Visual Discipline:** Material vector icons only — zero emoji as UI chrome (emoji appear strictly as user chat/reaction content).
  - **Purposeful Spring Motion:** `150–300ms` transitions (`enterDuration: 240ms`, `exitDuration: 160ms`, `tapDuration: 180ms`) with expressive/crisp `SpringDescription` physics, honoring `MediaQuery.disableAnimationsOf(context)` via `ShowcaseMotion.effectiveDuration`.

### Master Design Tokens (`lib/theme/showcase_tokens.dart` & `lib/theme/showcase_theme.dart`)

`ConvoKitColorPalette`, `ConvoKitTypography`, `ConvoKitSpacing`, `ConvoKitAvatarStyle`, and `ConvoKitStatusIndicatorStyle` are registered as Flutter `ThemeExtension`s on `ThemeData.extensions` and consumed via `ConvoKitThemeHelper`. Screen files under `lib/screens/` consume semantic tokens only (`0` raw `Color(0xFF...)` literals).

| Semantic Token | Light Mode (Default) | Dark Mode (OLED) | Wired Via |
| --- | --- | --- | --- |
| Primary Brand Green | `#16A34A` | `#1DD18B` | `ConvoKitColorPalette.primary` / `ColorScheme.primary` |
| Header / Highlight | `#0F7A5A` | `#00A884` | `ConvoKitColorPalette.textHighlight` / `ColorScheme.secondary` |
| Primary Container (Hero) | `#D8F5E3` (on: `#0A3826`) | `#0C3B2E` (on: `#D6F7E8`) | `ColorScheme.primaryContainer` |
| Surface Ladder (`Lowest` -> `Highest`) | `#FFFFFF` -> `#F7F9F8` -> `#F1F5F3` -> `#E7EEEA` -> `#DCE5E0` | `#0D151B` -> `#121C23` -> `#17232B` -> `#1F2D36` -> `#283944` | `ColorScheme.surfaceContainer*` |
| Chat Canvas | `#EFEAE2` | `#0B141A` | `ConvoKitMessageListStyle.backgroundColor` |
| Outgoing Bubble | `#DCF8C6` | `#005C4B` | `ConvoKitMessageListStyle.outgoingMessageBubbleStyle` |
| Outgoing Text (`>=4.5:1`) | `#0F1F18` (`>12:1`) | `#F2F7F5` (`>7.2:1`) | `ConvoKitMessageListStyle.outgoingTextColor` |
| Outgoing Timestamp (`>=4.5:1`) | `#3B5248` (`>6.5:1`) | `#CCE3DD` (`>5.6:1`) | `outgoingMessageBubbleStyle.messageBubbleDateStyle` |
| Incoming Bubble | `#FFFFFF` (text `#111B21`, ts `#4E6069`) | `#1F2D36` (text `#F2F5F7`, ts `#A5B4BE`) | `ConvoKitMessageListStyle.incomingMessageBubbleStyle` |
| Liquid Glass (`.regular`) | `rgba(255,255,255,0.78)`, `blurSigma: 24` | `rgba(22,33,41,0.78)`, `blurSigma: 24` | `GlassSurface`, `messageHeaderStyle`, `messageComposerStyle` |
| Avatar Monogram Palette | 8 WCAG-safe studio hues + `#FFFFFF` monogram | 8 WCAG-safe studio hues + `#FFFFFF` monogram | `ConvoKitAvatarStyle.monogramPalette` |

## 4-Tab Architecture Overview

`ShowcaseApp` (`lib/app.dart`) wraps the application in `ConvoKitScope(kit: _backend.kit, child: ...)` backed by the offline in-memory **`StudioBackend`** (`lib/backend/studio_backend.dart`), then mounts `ShowcaseShell` (`Scaffold(extendBody: true)`) with `IndexedStack` scrolling full-bleed beneath `FloatingGlassTabBar` (4 destinations, `<=5` nav rule):

| Tab | Screen | Purpose |
| --- | --- | --- |
| **Chats** | `ChatsTab` | Full-bleed `ConvoKitConversations` beneath `CollapsingGlassHeader` (`34pt -> 17pt`) and `FloatingGlassTabBar`, compose/directory entry (`PeopleGroupsScreen`), read-only search bar (`SearchScreen`), and push navigation into `ChatScreen` -> `ThreadScreen`. |
| **Updates** | `UpdatesTab` | `CollapsingGlassHeader`, **Atelier Studio Showcase Hero Card** (live interactive `CometChatPollsBubble` + full-pill launchers for `CoreViewsDemoScreen` and `SavedMessagesScreen`), and 3 calm `surfaceContainerLow` gallery sections mounting all remaining library widgets. |
| **Calls** | `CallsTab` | `CollapsingGlassHeader` and a dignified centered status hero built strictly from `CometChatCard` + two pill `ConvoKitActionBubble` badges transparently documenting Phase-7 Call UI removal. |
| **Settings** | `SettingsTab` | `CollapsingGlassHeader`, **Nadia Haddad Profile Hero Card** (`64px` `ConvoKitAvatar`, ringed `ConvoKitStatusIndicator` + `Online` text, live Light/Dark switch), calm grouped `surfaceContainerLow` cards for Saved Messages, atomic components (`ConvoKitBadge`, `ConvoKitDate`, `ConvoKitReceipt`, `ConvoKitShimmerEffect`, `SwipeTile`), `ConvoKitConfirmDialog` demo reset, and `ChatCapabilities.basic()` diagnostics. |

### Offline `StudioBackend` ("Atelier Studio")

Implements all 7 frozen ConvoKit contracts in pure Dart with deterministic cursor pagination, dynamic relative timestamps anchored to `DateTime.now()` (zero hardcoded May 2026 dates), and dense 10–14 message primary conversations (**Design Systems**, **Tariq Mansour**, **Brand Refresh 2026**, **Claire Laurent**):

- **`StudioSession`** (`ChatSession`) — current user **Nadia Haddad** (Design Director) + broadcast `currentUserStream`.
- **`StudioUserRepository`** (`UserRepository`) — 8 studio teammates with `getUser`, paginated `listUsers`, and case-insensitive `searchUsers`.
- **`StudioConversationRepository`** (`ConversationRepository`) — 5 direct + 3 group seeded conversations kept in sync with sent/received messages and unread counts.
- **`StudioMessageRepository`** (`MessageRepository`) — directional `MessagePageRequest` pagination, idempotent `localId` `sendMessage`, delayed `delivered`/`read` receipts, thread-reply lookups, pinned/saved collections, and in-memory poll voting.
- **`StudioGroupRepository`** (`GroupRepository`) — 3 studio groups (**Design Systems** `public`, **Brand Refresh 2026** `private`, **Studio Lounge** `passwordProtected`) with membership and role updates.
- **`StudioMediaProvider`** (`ChatMediaProvider`) — simulated offline `upload` with `UploadProgress` ticks, `CancellationToken` support, and `delete`.
- **`StudioEventSource`** (`ChatEventSource`) — broadcast `events` and `connectionState` streams (`MessageReceived`, `MessageStatusChanged`, `MessageDeleted`, `TypingChanged`, `PresenceChanged`, `ConversationUpdated`).

## Minimal Additive Library Fixes (L1–L6 + R5 Carry-Forward Overflow Fixes)

Every edit to `packages/cometchat_uikit/` is strictly additive, defaults to `null`/`false` (leaving default rendering and all 19 known golden tests untouched), and ships with a focused unit/widget test:

| ID | Library Files | Additive Enhancement / Fix | Focused Test |
| --- | --- | --- | --- |
| **L1** | `shared_ui/.../avatar/cometchat_avatar_style.dart`, `cometchat_avatar.dart` | Optional `monogramPalette`, `backgroundGradient`, `boxShadow` on `ConvoKitAvatarStyle`; deterministic per-name color hash and `asset:` URI support. | `test/shared_ui/avatar_monogram_palette_test.dart` |
| **L2** | `chat_ui/src/message_list/cometchat_message_list_style.dart`, `widgets/cometchat_message_list.dart` | Optional `listPadding`, `showBubbleTail` (directional `CustomPaint` tail with `ExcludeSemantics`), `bubbleShadow`, and style forwarding for `avatarStyle`, bubble `border`, and `messageReceiptStyle`. | `test/chat_ui/message_list_tail_and_padding_test.dart` |
| **L3** | `chat_ui/src/message_composer/cometchat_message_composer_style.dart`, `widgets/cometchat_message_composer.dart` | Optional `blurSigma`, `outerMargin`, and `boxShadow` on `ConvoKitMessageComposerStyle` for the floating Liquid Glass pill composer (`ClipRRect` + `BackdropFilter`). | `test/chat_ui/message_composer_glass_style_test.dart` |
| **L4** | `chat_ui/src/message_header/cometchat_message_header_style.dart`, `cometchat_message_header.dart` | Optional `blurSigma` and `boxShadow` on `ConvoKitMessageHeaderStyle` for frosted Liquid Glass translucency spanning status bar + header. | `test/chat_ui/message_header_glass_style_test.dart` |
| **L5** | `chat_ui/src/users/cometchat_users.dart` + `users_list.dart`, `groups/cometchat_groups.dart` + `groups_list.dart`, `group_members/cometchat_group_members.dart` | Optional `listPadding` on `ConvoKitUsers`, `ConvoKitGroups`, and `ConvoKitGroupMembers` for safe bottom/glass clearance. | `test/chat_ui/directory_list_padding_test.dart` |
| **L6** | `chat_ui/src/message_list/cometchat_message_list_style.dart`, `widgets/cometchat_message_list.dart` | Optional `messageEntryCurve` and `messageEntryDuration` on `ConvoKitMessageListStyle` (defaults `null` = instant; auto-skips animation when `MediaQuery.disableAnimationsOf(context)` is true). | `test/chat_ui/message_list_motion_test.dart` |
| **R5 Overflow #1** | `chat_ui/src/extensions/stickers/sticker_keyboard.dart` | Wrapped `CometChatStickerKeyboard` empty/error state content in `SingleChildScrollView` inside `Expanded` so compact heights (e.g. `160px`) render without `RenderFlex` vertical overflow. | `test/chat_ui/extensions/sticker_keyboard_overflow_test.dart` |
| **R5 Overflow #2** | `src/ui/views/message_list_view.dart` | Wrapped message bubble containers in `Flexible` inside the `MessageListView` `Row` so long message text wraps cleanly on narrow mobile/split-pane viewports without horizontal `RenderFlex` overflow. | `test/convokit/message_list_view_overflow_test.dart` |

## Screen-to-Library-Widget Mapping

| Showcase Screen / Sheet | Mounted Library Widgets |
| --- | --- |
| `ShowcaseApp` / `ShowcaseShell` (`lib/app.dart`) | `ConvoKitScope`, `ConvoKitColorPalette`, `ConvoKitTypography`, `ConvoKitSpacing`, `ConvoKitAvatarStyle`, `ConvoKitStatusIndicatorStyle` |
| `ChatsTab` (`lib/screens/chats/chats_tab.dart`) | `ConvoKitConversations` |
| `ChatScreen` (`lib/screens/chat/chat_screen.dart`) | `ConvoKitMessageHeader`, `ConvoKitMessageList`, `ConvoKitMessageComposer`, `CometChatVoiceNoteBubble` (via `addTemplate`), `CometChatMediaViewer`, `ConvoKitListItem` |
| `ThreadScreen` (`lib/screens/chat/thread_screen.dart`) | `ConvoKitThreadedHeader`, `ConvoKitMessageList` (`parentMessageId`), `ConvoKitMessageComposer` (`parentMessageId`), `CometChatMediaViewer` |
| `PinnedMessagesSheet` (`lib/screens/chat/pinned_messages_sheet.dart`) | `ConvoKitPinnedMessages` |
| `MessageInfoSheet` (`lib/screens/chat/message_info_sheet.dart`) | `CometChatMessageInformation` |
| `CreatePollSheet` (`lib/screens/chat/create_poll_sheet.dart`) | `CometChatCreatePoll` |
| `PeopleGroupsScreen` (`lib/screens/directory/people_groups_screen.dart`) | `ConvoKitUsers`, `ConvoKitGroups` |
| `GroupMembersScreen` (`lib/screens/directory/group_members_screen.dart`) | `ConvoKitGroupMembers`, `ConvoKitChangeScope`, `ConvoKitUsers` (`SelectionMode.multiple`) |
| `SearchScreen` (`lib/screens/search/search_screen.dart`) | `CometChatSearch` |
| `UpdatesTab` (`lib/screens/updates/updates_tab.dart`) | `CometChatPollsBubble`, `CometChatCreatePoll`, `CometChatStickerBubble`, `CometChatStickerKeyboard`, `StickerAuxiliaryButton`, `MessageTranslationBubble`, `CometChatLinkPreviewBubble`, `ImageModerationFilter`, `CometChatCollaborativeBubble`, `CometChatCollaborativeWebView`, `ConvoKitCardView`, `CometChatCard`, `CometChatTextBubble`, `CometChatVoiceNoteBubble`, `CometChatAudioPlayer`, `CometChatImageBubble`, `CometChatImagesBubble`, `CometChatVideoBubble`, `CometChatVideosBubble`, `CometChatAudiosBubble`, `CometChatFileBubble`, `CometChatFilesBubble`, `CometChatMediaGrid`, `CometChatMediaCaption`, `CometChatMediaPlaceholder`, `CometChatVideoFirstFrame`, `ConvoKitDeletedBubble`, `ConvoKitActionBubble`, `CometChatMediaViewer`, `ImageViewer`, `VideoPlayer`, `CometChatReactions`, `CometChatReactionList`, `ConvoKitMessagePreview`, `ConvoKitEmojiKeyboard`, `CometChatMediaRecorder`, `CometChatQuickView`, `CometChatSingleSelect`, `CometChatTimeSlotSelector`, `CometChatDecoratedContainer`, `DottedBorder`, `CometChatMarquee`, `SectionSeparator`, `GetMenuView`, `SearchFilterChip`, `CometChatAttachmentOptionSheet`, `CometchatMessageOptionSheet`, `CometChatWebView`, `ConvoKitListItem` |
| `CoreViewsDemoScreen` (`lib/screens/updates/core_views_demo_screen.dart`) | `ConversationsView`, `MessageListView` (`package:convokit/convokit.dart`) |
| `SavedMessagesScreen` (`lib/screens/updates/saved_messages_screen.dart`) | `ConvoKitSavedMessages` |
| `CallsTab` (`lib/screens/calls/calls_tab.dart`) | `CometChatCard`, `ConvoKitActionBubble` |
| `SettingsTab` (`lib/screens/settings/settings_tab.dart`) | `ConvoKitListItem`, `ConvoKitAvatar`, `ConvoKitStatusIndicator`, `ConvoKitBadge`, `ConvoKitDate`, `ConvoKitReceipt`, `ConvoKitShimmerEffect`, `SwipeTile`, `ConvoKitConfirmDialog`, `ConvoKitActionBubble`, `SectionSeparator` |

## Phase-7 Backlog Gaps (Documented Honestly, Not Worked Around)

Per the 100% library-component rule, none of these functional gaps are faked with custom `messageBuilder`, hand-rolled bubbles, or hand-rolled `ListView`s. They remain tracked transparently as Phase-8+ library backlog items:

1. **No Call UI Widgets (`CallsTab`):** `cometchat_calls_sdk` and `lib/call_ui/` were removed in Phase 7 (`zero_calls_sdk_test.dart`: 4/4). Zero call log lists or incoming/outgoing/ongoing call screens exist in `convokit_uikit.dart`.
2. **No Message Search in `CometChatSearch` or `MessageRepository`:** `CometChatSearch` only searches users via `UserRepository.searchUsers`; `SearchFilterChip` is exported but not wired to message search.
3. **No Chats Filter Pills or Pinned-Conversation Persistence:** `ConvoKitConversations` has no built-in filter bar (All / Unread / Groups), `ChatConversation` has no `isPinned` field, and `ConversationRepository` has no `pinConversation` contract.
4. **No Live Reactions in `ChatMessage` / `ConvoKitMessageList`:** `ChatMessage` has no `reactions` field and `MessageRepository` has no reaction contract; standalone `CometChatReactions` and `CometChatReactionList` are demonstrated in `UpdatesTab` instead.
5. **No-Op Poll Voting Inside `MessageTemplateUtils._buildCustomContent`:** Default poll bubbles inside `ConvoKitMessageList` use a no-op `choosePoll` callback because `MessageRepository` has no poll-voting contract. Interactive voting is demonstrated on standalone `CometChatPollsBubble` in `UpdatesTab`.
6. **No `StickerProvider` or Injectable Sticker Sets on `CometChatStickerKeyboard`:** `CometChatStickerKeyboard` initializes with empty sticker sets in Phase 7 and has no constructor parameter to inject offline stickers; it renders its empty state cleanly.
7. **Default Media & Extension Templates in `MessageTemplateUtils`:** Default media rendering uses simple icon + text rows for video/audio/file messages rather than `CometChatVoiceNoteBubble`, `CometChatFileBubble`, or `CometChatVideoBubble`, and does not auto-detect URLs for `CometChatLinkPreviewBubble` or wire live `MessageTranslationBubble`. (Voice notes are wired in `ChatScreen` via `addTemplate` referencing `CometChatVoiceNoteBubble`.)
8. **No Built-In Sliver AppBar, Detail Chevrons, or Swipe Actions on `ConvoKitConversations`:** `ChatsTab` hides the default Material `AppBar` (`hideAppbar: true`) to float `CollapsingGlassHeader` above it; `ConvoKitConversationListItem` has no detail-chevron slot or built-in `SwipeTile` actions.
9. **Offline Asset Limitations in Network-Only Bubbles & WebViews:** `CometChatImageBubble`, `CometChatStickerBubble`, and `CometChatLinkPreviewBubble` rely on network URLs without local `AssetImage` support (L1 adds `asset:` URI support to `ConvoKitAvatar` only), and `CometChatCollaborativeWebView` / `CometChatWebView` require live URLs; offline demos use `defaultImage`, `CometChatMediaPlaceholder`, and `ConvoKitAvatar` monogram fallbacks.
10. **Stale Theming Snippet in `skills/convokit-theming/SKILL.md`:** The skill references `ConvoKitTheme(data: ConvoKitThemeData(palette: ConvoKitColorPalette.light(...)))`, whereas Phase 7 uses `ThemeData(extensions: [ConvoKitColorPalette(...)])` read via `ConvoKitThemeHelper`. Real library source in `packages/cometchat_uikit/lib/` is authoritative.
