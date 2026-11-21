## 0.1.0

- Initial backend-agnostic release of `convokit`, forked from CometChat UIKit for Flutter v6.3.0 (MIT).
- Removed all CometChat SDK dependencies (`cometchat_sdk`, `cometchat_cards`, `cometchat_calls_sdk`) and all `package:cometchat_*` imports/exports across `lib/`, `test/`, and `examples/`.
- Removed `flutter_bloc` and `bloc_test` dependencies; all chat widgets now observe plain-Dart ConvoKit Core stores (`ConversationStore`, `MessageStore`, `UserStore`, `GroupStore`, `GroupMemberStore`, `PresenceRegistry`, `TypingRegistry`) and `MessageCoordinator` directly via `ConvoKitScope`.
- Shipped offline-ready `examples/sample_app` (backed by `InMemoryChatBackend`) and BLoC-free Riverpod `examples/clean_consumer`.
- Added permanent Acceptance Criterion 2 guardrails enforcing zero CometChat SDK and zero BLoC dependencies.
- Added optional `outgoingTextColor` (`Color?`, default `null`) to `ConvoKitMessageListStyle`, `MessageTemplateUtils.buildDefaultBubbleContent`, and `MessageTemplateUtils.getDeleteMessageBubble`.
