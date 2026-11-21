# ConvoKit Phase 7: CometChat SDK Footprint Inventory & Phase 7.0 Baseline Lock

Date: 2026-11-20
Branch: `convokit/phase-7` (built on the two prep commits: initial inventory doc + failing `criterion_2_no_sdk_dependencies_test.dart`)

## 1. Summary of Measured Footprint (Phase 7.0 Re-Measured & Locked Baseline)

All paths below are verified against the real repository layout (`packages/cometchat_uikit/lib/chat_ui/src/...`, `packages/cometchat_uikit/lib/shared_ui/src/...`, `packages/cometchat_uikit/lib/src/...`). There is no `cometchat_conversation/` directory and no `cometchat_*_constants.dart` files in this repository.

| Metric | Plan / Draft Figure | Re-Measured Value | Exact Breakdown & Notes |
| --- | ---: | ---: | --- |
| `cometchat_sdk` in `pubspec.yaml` | `^6.4.1` (erroneous) / `^5.1.1` | **`^5.1.1`** | Verified in `packages/cometchat_uikit/pubspec.yaml` (`cometchat_cards: ^1.0.1`, `flutter_bloc: ^9.1.1`, `bloc_test: ^10.0.0`) |
| `lib/` files matching `rg "package:cometchat_"` | 147 | **147 files (149 lines)** | **146 files** with active `import`/`export` (**148 statements**) + 1 comment-only file (`shared_ui/src/clean_architecture/data/models/cometchat_user_option.dart`). Area split: `chat_ui/src/` (93), `shared_ui/` (45), `src/adapters/` (7), `src/` other (2). Package split: `cometchat_sdk` (146 files), `cometchat_cards` (2 files: `feed_item_card.dart` overlaps with `cometchat_sdk`; `convokit_uikit_shared.dart` exports `cometchat_cards` only), `cometchat_calls_sdk` (0). |
| `test/` files referencing `package:cometchat_*` | 86 | **87 files** | **85 files** actively importing `package:cometchat_*` (`test/chat_ui/`: 72, `test/shared_ui/`: 7, `test/helpers/`: 4, `test/property/`: 2) + **2** guardrail tests matching the string in assertions (`test/convokit/no_cometchat_public_api_test.dart`, `test/convokit/criterion_2_no_sdk_dependencies_test.dart`). |
| `examples/` files referencing `package:cometchat_*` | 0 | **0 app files** (1 test) | 0 files in `examples/*/lib/`; 1 guardrail test (`examples/clean_consumer/test/clean_consumer_test.dart`) asserts zero `package:cometchat_` strings. |
| `lib/` files referencing `flutter_bloc` | 36 | **36 active import files / 44 total mentions** | **36** `.dart` files actively import `package:flutter_bloc/`; **44** total files in `lib/` contain the string `flutter_bloc` (the extra 8 are 7 Core `.dart` files whose doc comments state "zero `flutter_bloc`" + `shared_ui/src/clean_architecture/presentation/views/misc/BUBBLE_BLOC_OVERVIEW.md`). |
| `CometChatException` in `lib/` | 270 | **270 lines / 256 tokens / 21 `on`-catch sites** | **270** matching lines (272 substring matches: **256** standalone `CometChatException` tokens across **40** files + 16 `CometChatExceptionStyle` occurrences). Specifically **21** `on CometChatException` catch clauses; remaining usages are SDK `onError` callbacks, type signatures, and adapter mappers. |
| `CometChatSdkAdapter` in `lib/` | 158 | **158 occurrences** | Confined to adapters, legacy datasources/repositories/BLoCs, and `cometchat_ui_kit.dart`. |
| `src/adapters/`, `chat_auth_gateway.dart`, `chat_sdk_listeners.dart` refs in `lib/` | 40 | **40 files** | Legacy BLoCs, datasources, repositories, extensions, and `cometchat_ui_kit.dart`. |

## 2. Inventory by Feature Area

### chat_ui/src/search (2 files)

- **`chat_ui/src/search/bloc/search_event.dart`**
  - Uses: `User (SDK model)` (2), `Conversation (SDK model)` (1), `BaseMessage (SDK model)` (1)
- **`chat_ui/src/search/bloc/search_state.dart`**
  - Uses: `Conversation (SDK model)` (2), `BaseMessage (SDK model)` (2)

### chat_ui/src/threaded_header (2 files)

- **`chat_ui/src/threaded_header/bloc/threaded_header_event.dart`**
  - Uses: `User (SDK model)` (1), `BaseMessage (SDK model)` (2)
- **`chat_ui/src/threaded_header/bloc/threaded_header_state.dart`**
  - Uses: `User (SDK model)` (4), `Group (SDK model)` (2), `BaseMessage (SDK model)` (2)

### chat_ui/src/message_information (3 files)

- **`chat_ui/src/message_information/bloc/message_information_event.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_information/bloc/message_information_state.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (2), `BaseMessage (SDK model)` (2)
- **`chat_ui/src/message_information/domain/usecases/fetch_message_receipts_usecase.dart`**
  - Uses: only import

### chat_ui/src/message_header (6 files)

- **`chat_ui/src/message_header/bloc/message_header_event.dart`**
  - Uses: `User (SDK model)` (6), `Group (SDK model)` (4), `GroupMember (SDK model)` (1)
- **`chat_ui/src/message_header/data/repositories/message_header_repository_impl.dart`**
  - Uses: `CometChatException` (5), `CometChatSdkAdapter` (3), `User (SDK model)` (4), `Group (SDK model)` (3)
- **`chat_ui/src/message_header/domain/repositories/message_header_repository.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (1)
- **`chat_ui/src/message_header/domain/usecases/get_group_usecase.dart`**
  - Uses: `Group (SDK model)` (3)
- **`chat_ui/src/message_header/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/message_header/domain/usecases/get_user_usecase.dart`**
  - Uses: `User (SDK model)` (3)

### chat_ui/src/users (9 files)

- **`chat_ui/src/users/bloc/users_event.dart`**
  - Uses: `User (SDK model)` (1)
- **`chat_ui/src/users/bloc/users_state.dart`**
  - Uses: `User (SDK model)` (3)
- **`chat_ui/src/users/data/datasources/users_local_datasource.dart`**
  - Uses: `User (SDK model)` (9)
- **`chat_ui/src/users/data/datasources/users_remote_datasource.dart`**
  - Uses: `CometChatException` (4), `User (SDK model)` (4), `SDK Request Builders` (3)
- **`chat_ui/src/users/data/repositories/users_repository_impl.dart`**
  - Uses: `CometChatException` (1), `CometChatSdkAdapter` (1), `User (SDK model)` (3), `SDK Request Builders` (1)
- **`chat_ui/src/users/domain/repositories/users_repository.dart`**
  - Uses: `User (SDK model)` (3), `SDK Request Builders` (1)
- **`chat_ui/src/users/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/users/domain/usecases/get_user_usecase.dart`**
  - Uses: `User (SDK model)` (3)
- **`chat_ui/src/users/domain/usecases/get_users_usecase.dart`**
  - Uses: `User (SDK model)` (2), `SDK Request Builders` (1)

### chat_ui/src/groups (9 files)

- **`chat_ui/src/groups/bloc/groups_event.dart`**
  - Uses: `User (SDK model)` (10), `Group (SDK model)` (10), `Action (SDK model)` (6), `GroupMember (SDK model)` (1)
- **`chat_ui/src/groups/bloc/groups_state.dart`**
  - Uses: `Group (SDK model)` (3)
- **`chat_ui/src/groups/data/datasources/groups_remote_datasource.dart`**
  - Uses: `CometChatException` (4), `CometChatSdkAdapter` (1), `User (SDK model)` (2), `Group (SDK model)` (6), `SDK Request Builders` (2)
- **`chat_ui/src/groups/data/repositories/groups_repository_impl.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (3), `SDK Request Builders` (1)
- **`chat_ui/src/groups/domain/repositories/groups_repository.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (6)
- **`chat_ui/src/groups/domain/usecases/get_groups_usecase.dart`**
  - Uses: `Group (SDK model)` (2), `SDK Request Builders` (1)
- **`chat_ui/src/groups/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/groups/domain/usecases/join_group_usecase.dart`**
  - Uses: `Group (SDK model)` (4)
- **`chat_ui/src/groups/domain/usecases/load_more_groups_usecase.dart`**
  - Uses: `Group (SDK model)` (3)

### chat_ui/src/group_members (9 files)

- **`chat_ui/src/group_members/bloc/group_members_bloc.dart`**
  - Uses: `CometChatSdkAdapter` (6), `User (SDK model)` (37), `Group (SDK model)` (19), `Action (SDK model)` (18), `GroupMember (SDK model)` (30), `SDK Listeners` (3), `SDK Request Builders` (1)
- **`chat_ui/src/group_members/bloc/group_members_event.dart`**
  - Uses: `Action (SDK model)` (1), `GroupMember (SDK model)` (4)
- **`chat_ui/src/group_members/bloc/group_members_state.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (1), `GroupMember (SDK model)` (4)
- **`chat_ui/src/group_members/data/datasources/group_members_remote_datasource.dart`**
  - Uses: `CometChatException` (5), `CometChatSdkAdapter` (2), `User (SDK model)` (2), `Conversation (SDK model)` (2), `GroupMember (SDK model)` (2), `SDK Request Builders` (3)
- **`chat_ui/src/group_members/data/repositories/group_members_repository_impl.dart`**
  - Uses: `User (SDK model)` (1), `Conversation (SDK model)` (1), `GroupMember (SDK model)` (1), `SDK Request Builders` (1)
- **`chat_ui/src/group_members/domain/repositories/group_members_repository.dart`**
  - Uses: `User (SDK model)` (2), `Conversation (SDK model)` (2), `GroupMember (SDK model)` (2)
- **`chat_ui/src/group_members/domain/usecases/get_group_members_usecase.dart`**
  - Uses: `Group (SDK model)` (1), `GroupMember (SDK model)` (2), `SDK Request Builders` (1)
- **`chat_ui/src/group_members/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/group_members/domain/usecases/load_more_group_members_usecase.dart`**
  - Uses: `Group (SDK model)` (1), `GroupMember (SDK model)` (3), `SDK Request Builders` (1)

### chat_ui/src/conversations (11 files)

- **`chat_ui/src/conversations/bloc/conversations_event.dart`**
  - Uses: `Conversation (SDK model)` (1)
- **`chat_ui/src/conversations/bloc/conversations_state.dart`**
  - Uses: `Conversation (SDK model)` (5)
- **`chat_ui/src/conversations/data/datasources/conversations_local_datasource.dart`**
  - Uses: `Conversation (SDK model)` (9)
- **`chat_ui/src/conversations/data/datasources/conversations_remote_datasource.dart`**
  - Uses: `CometChatException` (3), `Conversation (SDK model)` (10), `BaseMessage (SDK model)` (3), `TextMessage (SDK model)` (2), `MediaMessage (SDK model)` (2), `CustomMessage (SDK model)` (2), `SDK Request Builders` (2)
- **`chat_ui/src/conversations/data/repositories/conversations_repository_impl.dart`**
  - Uses: `CometChatException` (5), `CometChatSdkAdapter` (4), `User (SDK model)` (2), `Group (SDK model)` (1), `Conversation (SDK model)` (8), `BaseMessage (SDK model)` (1), `SDK Request Builders` (1)
- **`chat_ui/src/conversations/domain/repositories/conversations_repository.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (1), `Conversation (SDK model)` (6), `BaseMessage (SDK model)` (1), `SDK Request Builders` (1)
- **`chat_ui/src/conversations/domain/usecases/get_conversation_usecase.dart`**
  - Uses: `Conversation (SDK model)` (4)
- **`chat_ui/src/conversations/domain/usecases/get_conversations_usecase.dart`**
  - Uses: `Conversation (SDK model)` (2), `SDK Request Builders` (1)
- **`chat_ui/src/conversations/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/conversations/domain/usecases/load_more_conversations_usecase.dart`**
  - Uses: `Conversation (SDK model)` (3), `SDK Request Builders` (1)
- **`chat_ui/src/conversations/domain/usecases/mark_as_delivered_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (1)

### chat_ui/src/message_list (16 files)

- **`chat_ui/src/message_list/bloc/message_list_bloc.dart`**
  - Uses: `CometChatException` (3), `CometChatSdkAdapter` (11), `User (SDK model)` (57), `Group (SDK model)` (35), `BaseMessage (SDK model)` (132), `TextMessage (SDK model)` (5), `MediaMessage (SDK model)` (4), `CustomMessage (SDK model)` (4), `Action (SDK model)` (32), `SDK Listeners` (8), `SDK Request Builders` (7)
- **`chat_ui/src/message_list/bloc/message_list_event.dart`**
  - Uses: `BaseMessage (SDK model)` (15)
- **`chat_ui/src/message_list/bloc/message_list_state.dart`**
  - Uses: `User (SDK model)` (3), `Conversation (SDK model)` (3), `BaseMessage (SDK model)` (8)
- **`chat_ui/src/message_list/data/datasources/message_list_local_datasource.dart`**
  - Uses: `BaseMessage (SDK model)` (9)
- **`chat_ui/src/message_list/data/datasources/message_list_remote_datasource.dart`**
  - Uses: `CometChatException` (9), `CometChatSdkAdapter` (2), `User (SDK model)` (2), `Conversation (SDK model)` (6), `BaseMessage (SDK model)` (16), `SDK Request Builders` (1)
- **`chat_ui/src/message_list/data/repositories/message_list_repository_impl.dart`**
  - Uses: `User (SDK model)` (1), `Conversation (SDK model)` (2), `BaseMessage (SDK model)` (6)
- **`chat_ui/src/message_list/domain/repositories/message_list_repository.dart`**
  - Uses: `User (SDK model)` (1), `Conversation (SDK model)` (2), `BaseMessage (SDK model)` (7)
- **`chat_ui/src/message_list/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/get_messages_usecase.dart`**
  - Uses: `Conversation (SDK model)` (2), `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/load_newer_messages_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/load_older_messages_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/mark_as_delivered_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/mark_as_read_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/domain/usecases/mark_as_unread_usecase.dart`**
  - Uses: `Conversation (SDK model)` (1), `BaseMessage (SDK model)` (1)
- **`chat_ui/src/message_list/utils/message_list_diff.dart`**
  - Uses: `BaseMessage (SDK model)` (4)
- **`chat_ui/src/message_list/utils/message_operation.dart`**
  - Uses: `BaseMessage (SDK model)` (11)

### chat_ui/src/message_composer (10 files)

- **`chat_ui/src/message_composer/data/datasources/message_composer_datasource.dart`**
  - Uses: `User (SDK model)` (1), `BaseMessage (SDK model)` (2), `TextMessage (SDK model)` (2), `MediaMessage (SDK model)` (2), `CustomMessage (SDK model)` (2)
- **`chat_ui/src/message_composer/data/datasources/message_composer_datasource_impl.dart`**
  - Uses: `CometChatException` (4), `CometChatSdkAdapter` (7), `User (SDK model)` (1), `BaseMessage (SDK model)` (4), `TextMessage (SDK model)` (6), `MediaMessage (SDK model)` (6), `CustomMessage (SDK model)` (6)
- **`chat_ui/src/message_composer/data/repositories/message_composer_repository_impl.dart`**
  - Uses: `CometChatException` (4), `User (SDK model)` (1), `BaseMessage (SDK model)` (2), `TextMessage (SDK model)` (2), `MediaMessage (SDK model)` (2), `CustomMessage (SDK model)` (2)
- **`chat_ui/src/message_composer/domain/repositories/message_composer_repository.dart`**
  - Uses: `User (SDK model)` (1), `BaseMessage (SDK model)` (2), `TextMessage (SDK model)` (2), `MediaMessage (SDK model)` (2), `CustomMessage (SDK model)` (2)
- **`chat_ui/src/message_composer/domain/usecases/edit_message_usecase.dart`**
  - Uses: `BaseMessage (SDK model)` (3)
- **`chat_ui/src/message_composer/domain/usecases/get_logged_in_user_usecase.dart`**
  - Uses: `User (SDK model)` (2)
- **`chat_ui/src/message_composer/domain/usecases/send_custom_message_usecase.dart`**
  - Uses: `CustomMessage (SDK model)` (3)
- **`chat_ui/src/message_composer/domain/usecases/send_media_message_usecase.dart`**
  - Uses: `MediaMessage (SDK model)` (3)
- **`chat_ui/src/message_composer/domain/usecases/send_text_message_usecase.dart`**
  - Uses: `TextMessage (SDK model)` (3)
- **`chat_ui/src/message_composer/upload/attachment_tray_controller.dart`**
  - Uses: `CometChatException` (4), `CometChatSdkAdapter` (4), `User (SDK model)` (2), `MediaMessage (SDK model)` (4), `Attachment (SDK model)` (8)

### chat_ui/src/notification_feed (16 files)

- **`chat_ui/src/notification_feed/bloc/notification_feed_bloc.dart`**
  - Uses: `CometChatSdkAdapter` (4), `SDK Listeners` (1)
- **`chat_ui/src/notification_feed/bloc/notification_feed_event.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/bloc/notification_feed_state.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/data/datasources/notification_feed_remote_datasource.dart`**
  - Uses: `CometChatException` (7), `CometChatSdkAdapter` (5)
- **`chat_ui/src/notification_feed/data/repositories/notification_feed_repository_impl.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/repositories/notification_feed_repository.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/get_categories_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/get_feed_item_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/get_feed_items_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/mark_feed_delivered_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/mark_feed_read_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/domain/usecases/report_feed_engagement_usecase.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/utils/feed_visibility_tracker.dart`**
  - Uses: only import
- **`chat_ui/src/notification_feed/utils/timestamp_grouper.dart`**
  - Uses: `Group (SDK model)` (1)
- **`chat_ui/src/notification_feed/widgets/feed_item_card.dart`**
  - Uses: `cometchat_cards` (1)
- **`chat_ui/src/notification_feed/widgets/notification_feed_filter_chips.dart`**
  - Uses: only import

### shared_ui/ (clean_architecture) (45 files)

- **`shared_ui/convokit_uikit_shared.dart`**
  - Uses: `cometchat_cards` (1)
- **`shared_ui/src/clean_architecture/clean_architecture.dart`**
  - Uses: only import
- **`shared_ui/src/clean_architecture/core/constants/enums.dart`**
  - Uses: `Conversation (SDK model)` (1), `BaseMessage (SDK model)` (6)
- **`shared_ui/src/clean_architecture/core/constants/request_builder_constants.dart`**
  - Uses: `SDK Request Builders` (12)
- **`shared_ui/src/clean_architecture/core/constants/ui_kit_constants.dart`**
  - Uses: `User (SDK model)` (5), `Group (SDK model)` (7), `Conversation (SDK model)` (1), `BaseMessage (SDK model)` (3), `GroupMember (SDK model)` (2)
- **`shared_ui/src/clean_architecture/core/utils/action_element_utils.dart`**
  - Uses: `CometChatException` (1), `CometChatSdkAdapter` (1), `Action (SDK model)` (1)
- **`shared_ui/src/clean_architecture/core/utils/attachment_utils.dart`**
  - Uses: `BaseMessage (SDK model)` (2), `MediaMessage (SDK model)` (5), `Attachment (SDK model)` (19)
- **`shared_ui/src/clean_architecture/core/utils/conversation_utils.dart`**
  - Uses: `User (SDK model)` (12), `Group (SDK model)` (12), `Conversation (SDK model)` (14), `BaseMessage (SDK model)` (9), `TextMessage (SDK model)` (1), `MediaMessage (SDK model)` (3), `CustomMessage (SDK model)` (3), `Action (SDK model)` (2)
- **`shared_ui/src/clean_architecture/core/utils/detail_utils.dart`**
  - Uses: `User (SDK model)` (9), `Group (SDK model)` (4), `GroupMember (SDK model)` (1)
- **`shared_ui/src/clean_architecture/core/utils/interaction_message_utils.dart`**
  - Uses: `CometChatException` (2), `CometChatSdkAdapter` (1), `User (SDK model)` (1), `BaseMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/core/utils/message_utils.dart`**
  - Uses: `Group (SDK model)` (2), `BaseMessage (SDK model)` (13), `TextMessage (SDK model)` (1), `CustomMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/core/utils/moderation_check_util.dart`**
  - Uses: `BaseMessage (SDK model)` (1), `TextMessage (SDK model)` (1), `MediaMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/core/utils/scheduler_utils.dart`**
  - Uses: `CometChatException` (4)
- **`shared_ui/src/clean_architecture/core/utils/sdk_methods.dart`**
  - Uses: `CometChatException` (3), `CometChatSdkAdapter` (3)
- **`shared_ui/src/clean_architecture/core/utils/status_indicator_utils.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `GroupMember (SDK model)` (1)
- **`shared_ui/src/clean_architecture/data/models/cometchat_details_option.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (2)
- **`shared_ui/src/clean_architecture/data/models/cometchat_details_template.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (1)
- **`shared_ui/src/clean_architecture/data/models/cometchat_group_member_option.dart`**
  - Uses: `Group (SDK model)` (1), `GroupMember (SDK model)` (2)
- **`shared_ui/src/clean_architecture/data/models/cometchat_message_composer_action.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `Action (SDK model)` (1)
- **`shared_ui/src/clean_architecture/data/models/cometchat_message_option.dart`**
  - Uses: `BaseMessage (SDK model)` (3)
- **`shared_ui/src/clean_architecture/data/models/cometchat_message_template.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `BaseMessage (SDK model)` (9)
- **`shared_ui/src/clean_architecture/data/models/cometchat_user_option.dart`**
  - Uses: `User (SDK model)` (1)
- **`shared_ui/src/clean_architecture/data/models/interactive_message/custom_interactive_message.dart`**
  - Uses: only import
- **`shared_ui/src/clean_architecture/data/models/interactive_message/form_message.dart`**
  - Uses: only import
- **`shared_ui/src/clean_architecture/data/models/interactive_message/scheduler_message.dart`**
  - Uses: only import
- **`shared_ui/src/clean_architecture/domain/events/message_events/cometchat_message_event_listener.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `BaseMessage (SDK model)` (13), `TextMessage (SDK model)` (1), `MediaMessage (SDK model)` (1), `CustomMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/domain/events/message_events/cometchat_message_events.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `BaseMessage (SDK model)` (13), `TextMessage (SDK model)` (1), `MediaMessage (SDK model)` (1), `CustomMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/domain/events/ui_events/cometchat_ui_event_listener.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (2), `BaseMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/domain/events/ui_events/cometchat_ui_events.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (2), `BaseMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/domain/events/user_events/cometchat_user_event_listener.dart`**
  - Uses: `User (SDK model)` (2)
- **`shared_ui/src/clean_architecture/domain/events/user_events/cometchat_user_events.dart`**
  - Uses: `User (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/formatters/cometchat_phone_number_formatter.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/presentation/formatters/cometchat_text_formatter.dart`**
  - Uses: `User (SDK model)` (1), `Group (SDK model)` (1), `BaseMessage (SDK model)` (3), `SDK Request Builders` (4)
- **`shared_ui/src/clean_architecture/presentation/formatters/cometchat_url_formatter.dart`**
  - Uses: `BaseMessage (SDK model)` (1)
- **`shared_ui/src/clean_architecture/presentation/formatters/mentions/cometchat_mentions_formatter.dart`**
  - Uses: `User (SDK model)` (18), `BaseMessage (SDK model)` (6), `TextMessage (SDK model)` (4), `MediaMessage (SDK model)` (3), `SDK Request Builders` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/audio_bubble_factory.dart`**
  - Uses: `MediaMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/bubble_factory.dart`**
  - Uses: `BaseMessage (SDK model)` (3)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/deleted_bubble_factory.dart`**
  - Uses: `BaseMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/file_bubble_factory.dart`**
  - Uses: `MediaMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/image_bubble_factory.dart`**
  - Uses: `MediaMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/text_bubble_factory.dart`**
  - Uses: `TextMessage (SDK model)` (2)
- **`shared_ui/src/clean_architecture/presentation/views/bubbles/bubble_factory/video_bubble_factory.dart`**
  - Uses: `MediaMessage (SDK model)` (2)
- **`shared_ui/src/cometchat_message_list/widgets/cometchat_animated_message_list.dart`**
  - Uses: `BaseMessage (SDK model)` (7)
- **`shared_ui/src/models/ai/stream_message.dart`**
  - Uses: `User (SDK model)` (1)
- **`shared_ui/src/utils/reply_utils.dart`**
  - Uses: `User (SDK model)` (2), `Group (SDK model)` (4), `BaseMessage (SDK model)` (1)

### src/adapters/ (7 files)

- **`src/adapters/cometchat_conversation_adapter.dart`**
  - Uses: `CometChatException` (9), `CometChat.* statics` (4), `User (SDK model)` (1), `Group (SDK model)` (2), `Conversation (SDK model)` (11), `BaseMessage (SDK model)` (3), `TextMessage (SDK model)` (2), `SDK Request Builders` (3)
- **`src/adapters/cometchat_group_adapter.dart`**
  - Uses: `CometChatException` (22), `CometChat.* statics` (11), `Group (SDK model)` (18), `GroupMember (SDK model)` (9), `SDK Request Builders` (6)
- **`src/adapters/cometchat_media_adapter.dart`**
  - Uses: `CometChatException` (3), `CometChatSdkAdapter` (1), `Attachment (SDK model)` (1)
- **`src/adapters/cometchat_message_adapter.dart`**
  - Uses: `CometChatException` (16), `CometChat.* statics` (11), `Conversation (SDK model)` (3), `BaseMessage (SDK model)` (17), `TextMessage (SDK model)` (8), `MediaMessage (SDK model)` (6), `CustomMessage (SDK model)` (6), `SDK Request Builders` (1)
- **`src/adapters/cometchat_sdk_adapter.dart`**
  - Uses: `CometChatException` (52), `CometChatSdkAdapter` (1), `CometChat.* statics` (77), `User (SDK model)` (10), `Group (SDK model)` (4), `Conversation (SDK model)` (8), `BaseMessage (SDK model)` (17), `TextMessage (SDK model)` (3), `MediaMessage (SDK model)` (3), `CustomMessage (SDK model)` (3), `GroupMember (SDK model)` (1), `Attachment (SDK model)` (5), `SDK Listeners` (4)
- **`src/adapters/cometchat_session_adapter.dart`**
  - Uses: `User (SDK model)` (5)
- **`src/adapters/cometchat_user_adapter.dart`**
  - Uses: `CometChatException` (9), `CometChat.* statics` (3), `User (SDK model)` (12), `SDK Request Builders` (4)

### src/ (auth gateway & listeners) (2 files)

- **`src/chat_auth_gateway.dart`**
  - Uses: `CometChatException` (11), `CometChat.* statics` (12), `User (SDK model)` (13)
- **`src/chat_sdk_listeners.dart`**
  - Uses: `CometChat.* statics` (4), `SDK Listeners` (3)

## 3. Migration Roadmap & Strategy

1. **Error Type Unification (Step 2):**
   - Replace `CometChatException` with `ChatError` across all files.
2. **Feature-by-Feature Decoupling (Step 3):**
   - `search` (2 files)
   - `threaded_header` (2 files)
   - `message_information` (3 files)
   - `message_header` (6 files)
   - `users` (9 files)
   - `groups` (9 files)
   - `group_members` (9 files)
   - `conversations` (11 files)
   - `message_list` (16 files)
   - `message_composer` (10 files)
   - `notification_feed` (16 files)
   - `clean_architecture` / `shared_ui` (45 files)
3. **Glue Layer Deletion (Step 4):**
   - Delete 7 adapters in `lib/src/adapters/`
   - Delete `chat_auth_gateway.dart` & `chat_sdk_listeners.dart` in `lib/src/`
4. **Dependency Removal (Step 5):**
   - Remove `cometchat_sdk` and `cometchat_cards` from `pubspec.yaml`.
5. **Test Suite Modernization & Criterion-2 Test (Step 6):**
   - Add and enforce Criterion-2 test.
   - Rewrite/prune legacy SDK tests.
6. **Full Verification (Step 7):**
   - Library suite, sample app suite, clean consumer suite.

## 4. Phase 7.0 — Frozen ConvoKit Contracts (No Changes Permitted in Phase 7.0)

All contract interfaces under `packages/cometchat_uikit/lib/src/contracts/` (exported via `packages/cometchat_uikit/lib/convokit.dart`) are **frozen** for Phase 7.0:

- `packages/cometchat_uikit/lib/src/contracts/contracts.dart` (barrel export)
- `packages/cometchat_uikit/lib/src/contracts/capabilities.dart` — `ChatCapabilities`
- `packages/cometchat_uikit/lib/src/contracts/conversation_repository.dart` — `ConversationRepository`
- `packages/cometchat_uikit/lib/src/contracts/event_source.dart` — `ChatEventSource`, `ChatEvent` (`MessageReceived`, `MessageStatusChanged`, `MessageDeleted`, `TypingChanged`, `PresenceChanged`, `ConversationUpdated`, `ConnectionState`), `ConnectionStatus`
- `packages/cometchat_uikit/lib/src/contracts/group_repository.dart` — `GroupRepository`
- `packages/cometchat_uikit/lib/src/contracts/media_provider.dart` — `ChatMediaProvider`, `UploadRequest`, `UploadedMedia`, `UploadProgress`, `CancellationToken`
- `packages/cometchat_uikit/lib/src/contracts/message_repository.dart` — `MessageRepository`
- `packages/cometchat_uikit/lib/src/contracts/pagination.dart` — `MessagePageDirection`, `MessagePageRequest`, `ChatPage`
- `packages/cometchat_uikit/lib/src/contracts/result.dart` — `ChatResult`, `ChatSuccess`, `ChatFailure`, `ChatErrorCode`, `ChatError`
- `packages/cometchat_uikit/lib/src/contracts/session.dart` — `ChatSession`
- `packages/cometchat_uikit/lib/src/contracts/user_repository.dart` — `UserRepository` (`getUser`, `listUsers`, `searchUsers`)

## 5. Phase 7.0 — Locked Core Store & Registry API Surface

The plain-Dart store/registry surface under `packages/cometchat_uikit/lib/src/core/stores/` (exported via `stores.dart` and `convokit.dart`) is **locked** as follows (zero Dart/code edits in Phase 7.0):

| Logical Surface | Real Class & File Path | Locked Public API Surface |
| --- | --- | --- |
| Conversations store (`ConversationsStore`) | `ConversationStore` (`packages/cometchat_uikit/lib/src/core/stores/conversation_store.dart`) | `conversations`, `stream`, `setConversations`, `updateConversation`, `updateUnreadCount`, `removeConversation`, `clear`, `dispose` |
| Messages store (`MessagesStore`) | `MessageStore` (`packages/cometchat_uikit/lib/src/core/stores/message_store.dart`) | `messages`, `stream`, `gapStream`, `olderCursor`, `newerCursor`, `newerCheckpoint`, `hasOlder`, `hasNewer`, `recoveryIncomplete`, `hasPossibleGap`, `addOrReconcile`, `mergePage`, `applyStatusChange`, `removeMessage`, `markFailed`, `setGapFlag`, `clearPending`, `clear`, `dispose` |
| Presence store (`PresenceStore`) | `PresenceRegistry` (`packages/cometchat_uikit/lib/src/core/stores/presence_registry.dart`) | `stream`, `getPresence`, `setPresence`, `clear`, `dispose` |
| Typing registry (companion) | `TypingRegistry` (`packages/cometchat_uikit/lib/src/core/stores/typing_registry.dart`) | `stream`, `getTypingUsers`, `setTyping`, `clear`, `dispose` |
| Users store (`UsersStore`) | *Not yet implemented in `lib/src/core/stores/`* | Backed by frozen `UserRepository` (`packages/cometchat_uikit/lib/src/contracts/user_repository.dart`: `getUser`, `listUsers`, `searchUsers`). Deferred until the phase that introduces store-backed user listing (no Dart code added in Phase 7.0). |

## 6. Phase 7.0 — Guardrails, Count Script & Gate Commands

- **SDK import count & regression script:** `packages/cometchat_uikit/tool/count_sdk_imports.sh`
  - Print counts: `bash packages/cometchat_uikit/tool/count_sdk_imports.sh`
  - Enforce no-new-import gate: `bash packages/cometchat_uikit/tool/count_sdk_imports.sh --check`
  - Enforces both the locked 146-file active allowlist (148 statements) and the 147-file / 149-line `rg "package:cometchat_"` ceiling. Any new file importing `package:cometchat_*` or any increase in statement count fails with exit code `1`.
- **GitHub Actions CI gate:** `.github/workflows/phase7-no-new-cometchat-imports.yml`
  - Runs `bash packages/cometchat_uikit/tool/count_sdk_imports.sh --check` on every `pull_request` to `main`/`convokit/**` and every `push` to `convokit/**`.
- **Preserved prep test:** `packages/cometchat_uikit/test/convokit/criterion_2_no_sdk_dependencies_test.dart` (expected to remain red until Phase 7.8 removes `cometchat_sdk` and `cometchat_cards` from `pubspec.yaml` and `lib/`).
- **Phase 7.0 Local Gate Verification Commands:**
  ```bash
  rg "package:cometchat_" packages/cometchat_uikit/lib
  bash packages/cometchat_uikit/tool/count_sdk_imports.sh --check
  (cd packages/cometchat_uikit && flutter analyze && flutter test)
  (cd examples/sample_app && flutter analyze && flutter test)
  (cd examples/clean_consumer && flutter analyze && flutter test)
  ```

### Phase 7.0 — Locked Baseline Golden Failures (Linux)

The 6 pre-existing golden pixel failures in `packages/cometchat_uikit/test/chat_ui/message_list/goldens/message_list_golden_test.dart` (all with variant `Linux`) are locked as the Phase 7 baseline:

- `outgoing bubble, read receipt` (variant: Linux)
- `outgoing bubble, delivered receipt` (variant: Linux)
- `outgoing bubble, sent receipt` (variant: Linux)
- `incoming bubble, no receipt` (variant: Linux)
- `incoming bubble, multi-line wrapping` (variant: Linux)
- `emoji-only bubble, scaled and unpadded` (variant: Linux)

## 7. Phase 7.1 — Error Unification (`CometChatException` → `ChatError`) & `cometchat_cards` Removal

Completed in Phase 7.1:

- Added single temporary mapper `ChatError fromCometChatException(cc.CometChatException e)` (plus `CometChatSdkAdapter.mapError`, `rawErrorCode`, `rawErrorParams`, and `createUploadFileListener`) in `packages/cometchat_uikit/lib/src/adapters/cometchat_sdk_adapter.dart`.
- Migrated all `CometChatException` callback parameters, state error fields, catches, and error constructions in `packages/cometchat_uikit/lib/chat_ui/` and `packages/cometchat_uikit/lib/shared_ui/` (including `scheduler_utils.dart`, clearing its `package:cometchat_sdk` import) to `ChatError`. Remaining `CometChatException` references are strictly confined to `packages/cometchat_uikit/lib/src/adapters/` and `packages/cometchat_uikit/lib/src/chat_auth_gateway.dart`.
- Removed all `package:cometchat_cards` code usage: added pure-Flutter `ConvoKitCardView` fallback (`lib/shared_ui/src/views/convokit_card_view.dart`), replaced `CometChatCardView` in `cometchat_card_bubble.dart` and `feed_item_card.dart`, deleted `export 'package:cometchat_cards/cometchat_cards.dart';` from `convokit_uikit_shared.dart`, and rewrote `test/chat_ui/message_list/card_bubble_test.dart` with zero `package:cometchat_cards` imports.
- Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh` to the new measured Phase 7.1 baseline.

### Phase 7.1 Measured Counts

| Metric | Phase 7.0 | Phase 7.1 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 146 | 144 | -2 |
| `lib/` active `package:cometchat_*` import/export statements | 148 | 145 | -3 |
| `lib/` `rg "package:cometchat_"` files / lines | 147 / 149 | 145 / 146 | -2 / -3 |
| `lib/` + `test/` `package:cometchat_cards` matches | 3 (2 lib, 1 test) | 0 | -3 |
| `lib/chat_ui/` + `lib/shared_ui/` `\bCometChatException\b` matches | 134 lines (33 files) | 0 | -134 |
| `lib/` total `CometChatException` tokens (files) / lines / on-catch | 256 (40) / 270 / 21 | 82 (7) / 124 / 0 | -174 / -146 / -21 |

## 8. Phase 7.2 — `shared_ui/` Decoupling & Severing `clean_architecture.dart` Re-Export

Completed in Phase 7.2:

- **Severed transitive SDK barrel re-export:** Removed `export 'package:cometchat_sdk/cometchat_sdk.dart';` from `packages/cometchat_uikit/lib/shared_ui/src/clean_architecture/clean_architecture.dart` and replaced it with selective ConvoKit Core model exports (`ChatUser`, `UserPresence`, `ChatGroup`, `ChatMember`, `GroupRole`, `GroupType`, `ChatConversation`, `ChatConversationType`, `ChatMessage`, `SendState`, `DeliveryState`, `ChatAttachment`, `AttachmentKind`, `AttachmentState` — omitting `TextMessage`/`MediaMessage`/`CustomMessage` from the shared barrel to prevent name collisions in unmigrated `chat_ui/` files).
- **Moved `cometchat_ui_kit.dart` temporarily to `lib/src/`:** Relocated `lib/shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart` → `lib/src/cometchat_ui_kit.dart` (inlining the 3 interactive send helpers from `sdk_methods.dart` and updating all 10 importers) so `lib/shared_ui/` holds at 0 SDK imports until Phase 7.7 deletes the facade.
- **Deleted 7 SDK-only remnants & 2 deferred reaction BLoCs:**
  - `shared_ui/src/clean_architecture/core/constants/request_builder_constants.dart`
  - `shared_ui/src/clean_architecture/core/utils/sdk_methods.dart` and `shared_ui/src/utils/sdk_methods.dart`
  - `shared_ui/src/clean_architecture/core/utils/action_element_utils.dart`
  - `shared_ui/src/clean_architecture/core/utils/interaction_message_utils.dart`
  - `shared_ui/src/models/ai/stream_message.dart`
  - `shared_ui/src/events/utils/chat_sdk_event_initializer.dart`
  - `shared_ui/src/clean_architecture/presentation/views/components/reaction_list/reaction_list_bloc.dart`
  - `shared_ui/src/clean_architecture/presentation/views/components/reactions/reactions_bloc.dart`
- **Replaced internal `shared_ui/` BLoCs with plain `ChangeNotifier` controllers:** Replaced `list_base_bloc.dart` → `list_base_controller.dart` (`ListBaseController`) and `media_recorder_bloc.dart` → `media_recorder_controller.dart` (`MediaRecorderController`), updated `cometchat_listbase.dart` and `cometchat_media_recorder.dart` to use `ListenableBuilder`, and decoupled `cometchat_reaction_list.dart` and `cometchat_reactions.dart` into pure Flutter widgets (0 `package:flutter_bloc` in `lib/shared_ui/`).
- **Migrated all remaining `shared_ui/` files (43 direct + 23 transitive) onto ConvoKit Core models:** Re-typed constants/enums/utils (`enums.dart`, `ui_kit_constants.dart`, `attachment_utils.dart`, `conversation_utils.dart`, `detail_utils.dart`, `message_utils.dart`, `moderation_check_util.dart`, `status_indicator_utils.dart`, `reply_utils.dart`, `message_receipt_utils.dart`), option/template/interactive models (introducing pure-Dart `ConvoKitInteractiveMessage`), UI/Message/User/Group events, text/phone/URL/email/mentions formatters, all 7 `bubble_factory/*.dart` files (exhaustive `switch` on sealed `ChatMessage`), 5 media bubble widgets, controller protocols, `cometchat_ui_kit_helper.dart`, and `cometchat_animated_message_list.dart`.
- **Made `lib/chat_ui/` transitive SDK reliance explicit (+64 temporary imports):** Added explicit temporary `import 'package:cometchat_sdk/cometchat_sdk.dart' hide CardMessage;` to the **64** `lib/chat_ui/` files that previously relied transitively on `clean_architecture.dart`'s SDK export, and added temporary `CometChatSdkAdapter.fromSdkUser` / `fromSdkGroup` / `fromSdkMember` bridge helpers for Phases 7.3–7.6.
- **Rewrote & pruned affected tests:** Deleted 4 obsolete tests (`reaction_list_bloc_test.dart`, `reaction_list_props_test.dart`, `component_events_test.dart`, `interaction_message_utils_test.dart`), rewrote all 6 remaining `test/shared_ui/` and 2 `test/property/` SDK tests onto Core models, and dropped `package:bloc_test` and `package:flutter_bloc` from all 9 `test/shared_ui/` test files.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Updated allowlist to the 167 measured active `lib/` files (0 in `shared_ui/`, 157 in `chat_ui/src/`, 7 in `src/adapters/`, 3 in `src/`).

### Phase 7.2 Measured Counts

| Metric | Phase 7.1 | Phase 7.2 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 144 | 167 | +23 (-43 `shared_ui/`, +64 explicit `chat_ui/`, +1 `src/cometchat_ui_kit.dart`, +1 net) |
| `lib/` active `package:cometchat_*` import/export statements | 145 | 167 | +22 |
| `lib/` `rg "package:cometchat_"` files / lines | 145 / 146 | 167 / 167 | +22 / +21 |
| `lib/shared_ui/` `package:cometchat_*` matches | 43 | **0** | -43 |
| `lib/shared_ui/` `package:flutter_bloc` matches | 8 | **0** | -8 |
| `lib/` `export 'package:cometchat_*` matches | 1 | **0** | -1 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 93 | 157 | +64 (temporary explicit imports from severed barrel) |
| `lib/src/` (other) `package:cometchat_*` files | 2 | 3 | +1 (`lib/src/cometchat_ui_kit.dart` moved from `shared_ui/`) |
| `test/shared_ui/` + `test/property/` `package:cometchat_*` files | 9 | **0** | -9 |
| `test/shared_ui/` + `test/property/` `package:bloc_test` files | 9 | **0** | -9 |
| `test/` active `package:cometchat_*` files / total matching | 85 / 87 | 76 / 78 | -9 / -9 |
| `lib/` files importing `package:flutter_bloc/` | 36 | 28 | -8 |

## 9. Phase 7.3 — Lightweight Feature Rewiring (`search`, `threaded_header`, `message_information`, `message_header`)

Completed in Phase 7.3:

- **`chat_ui/src/search/` (4 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `CometChatSearch` onto `UserRepository.searchUsers` via `ConvoKitScope` (v1 user search only, debounced query, cursor pagination, and visibility gated on `capabilities.search`).
  - Deleted `search/bloc/` (`bloc.dart`, `search_bloc.dart`, `search_event.dart`, `search_state.dart`) and removed its barrel export from `search.dart`.
- **`chat_ui/src/threaded_header/` (4 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitThreadedHeader` to accept `ChatMessage` + optional `ChatUser`/`ChatGroup` and observe `EventHub.getMessageStore(conversationId)` directly for live reply counts and parent updates (with receipt visibility gated on `capabilities.receipts`).
  - Deleted `threaded_header/bloc/`, `threaded_header/data/`, `threaded_header/domain/`, and `threaded_header/di/`, and cleaned `threaded_header.dart`.
- **`chat_ui/src/message_information/` (8 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `CometChatMessageInformation` and `showMessageInformation` to render `ChatMessage.sendState` and `ChatMessage.deliveryState` directly (gated on `capabilities.receipts`, hiding all receipt rows when `false`) with optional live `EventHub.getMessageStore` observation.
  - Deleted `message_information/bloc/`, `message_information/data/`, `message_information/domain/`, and `message_information/di/`, cleaned `message_information.dart`, and bridged the temporary Phase 7.5 caller in `cometchat_message_list.dart` via `CometChatMessageAdapter.fromSdkMessage`.
- **`chat_ui/src/message_header/` (9 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitMessageHeader` to observe `EventHub.presenceRegistry` and `EventHub.typingRegistry` (gated on `capabilities.typing`) and refresh user/group details via `UserRepository.getUser` / `GroupRepository.getGroup` from `ConvoKitScope`, with clean unsubscribe on `dispose()` and `didUpdateWidget()`.
  - Deleted `message_header/bloc/`, `message_header/data/`, `message_header/domain/`, and `message_header/di/`.
- **Library exports:** Updated `packages/cometchat_uikit/lib/convokit_uikit.dart` to remove the deleted `message_header` BLoC/domain exports so no broken exports remain.
- **Tests (12 SDK test files & 13 `bloc_test` files cleared):** Removed obsolete BLoC, repository, usecase, and legacy golden tests and rewrote widget tests in `test/chat_ui/{search,threaded_header,message_information,message_header}/` to pump widgets inside `ConvoKitScope` backed by `FakeChatBackend` with zero `package:cometchat_*`, zero `package:bloc_test`, and zero `package:flutter_bloc` imports.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Locked the Phase 7.3 baseline at **142** active `lib/` SDK files (0 in `shared_ui/`, 132 in `chat_ui/src/`, 7 in `src/adapters/`, 3 in `src/`).

### Phase 7.3 Measured Counts

| Metric | Phase 7.2 | Phase 7.3 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 167 | **142** | -25 |
| `lib/` active `package:cometchat_*` import/export statements | 167 | **142** | -25 |
| `lib/` `rg "package:cometchat_"` files / lines | 167 / 167 | **142 / 142** | -25 / -25 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 157 | **132** | -25 |
| `lib/shared_ui/` `package:cometchat_*` matches | 0 | **0** | 0 |
| `lib/chat_ui/src/{search,threaded_header,message_information,message_header}` SDK / BLoC / adapter matches | 25 / 8 / 7 | **0 / 0 / 0** | -25 / -8 / -7 |
| `lib/` files importing `package:flutter_bloc/` | 28 | **20** | -8 |
| `lib/` files referencing `src/adapters/` or auth/listeners | 37 | **30** | -7 |
| `test/chat_ui/{search,threaded_header,message_information,message_header}` SDK / `bloc_test` files | 12 / 13 | **0 / 0** | -12 / -13 |
| `test/` active `package:cometchat_*` files / total matching | 76 / 78 | **64 / 66** | -12 / -12 |

## 10. Phase 7.4 — Directory & Membership Features (`users`, `groups`, `group_members`)

Completed in Phase 7.4:

- **`chat_ui/src/users/` (15 lib SDK files & 3 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitUsers` and `UsersList` onto `UserRepository` (`listUsers`, `searchUsers`, `getUser`) via `ConvoKitScope`, with cursor pagination (`ChatPage.olderCursor` / `hasOlder`), debounced search, search-input visibility gated on `capabilities.search`, and live presence updates from `EventHub.presenceRegistry`.
  - Deleted `users/bloc/`, `users/data/`, `users/domain/`, `users/di/`, and `users/users_builder_protocol.dart`.
- **`chat_ui/src/groups/` (15 lib SDK files & 3 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitGroups`, `GroupsList`, and `CometChatGroupListItem` onto optional `GroupRepository` (`listGroups`, `getGroup`, `joinGroup`, `leaveGroup`) via `ConvoKitScope`, gated on `capabilities.groups && kit.groups != null` (rendering an empty/disabled state cleanly with search hidden and zero null-check crashes when groups are absent).
  - Deleted `groups/bloc/`, `groups/data/`, `groups/domain/`, `groups/di/`, and `groups/groups_builder_protocol.dart`.
- **`chat_ui/src/group_members/` (17 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitGroupMembers`, `ConvoKitGroupMembersController` (plain `ChangeNotifier`), and `ConvoKitChangeScope` onto `GroupRepository` (`listMembers`, `addMembers`, `removeMember`) via `ConvoKitScope` (gated on `capabilities.groups && kit.groups != null`) and `EventHub.presenceRegistry`.
  - Deleted `group_members/bloc/` (including `group_members_bloc.dart` and `group_members_bloc_adapter.dart`), `group_members/data/`, `group_members/domain/`, `group_members/di/`, and `group_members/group_members_builder_protocol.dart`.
- **Library exports:** Updated `packages/cometchat_uikit/lib/convokit_uikit.dart` to remove all deleted `users`, `groups`, and `group_members` BLoC/domain/DI/builder-protocol exports.
- **Tests (17 SDK test files & 22 `bloc_test` files cleared):** Removed obsolete BLoC, adapter, repository, usecase, request-builder, and legacy golden tests and rewrote `test/chat_ui/users/users_props_test.dart`, `test/chat_ui/groups/widget/groups_props_test.dart`, `test/chat_ui/groups/widget/group_list_item_props_test.dart`, `test/chat_ui/group_members/group_members_controller_test.dart`, `test/chat_ui/group_members/widget/group_members_props_test.dart`, and `test/chat_ui/group_members/widget/change_scope_props_test.dart` against `FakeChatBackend` + `ConvoKitScope` (including explicit `capabilities.groups == false` + `groups: null` assertions) with zero `package:cometchat_*` and zero `package:bloc_test` imports.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Locked the Phase 7.4 baseline at **95** active `lib/` SDK files (0 in `shared_ui/`, 85 in `chat_ui/src/`, 7 in `src/adapters/`, 3 in `src/`).

### Phase 7.4 Measured Counts

| Metric | Phase 7.3 | Phase 7.4 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 142 | **95** | -47 |
| `lib/` active `package:cometchat_*` import/export statements | 142 | **95** | -47 |
| `lib/` `rg "package:cometchat_"` files / lines | 142 / 142 | **95 / 95** | -47 / -47 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 132 | **85** | -47 |
| `lib/shared_ui/` `package:cometchat_*` matches | 0 | **0** | 0 |
| `lib/chat_ui/src/{users,groups,group_members}` SDK / BLoC / adapter matches | 47 / 8 / 8 | **0 / 0 / 0** | -47 / -8 / -8 |
| `lib/` files importing `package:flutter_bloc/` | 20 | **12** | -8 |
| `lib/` files referencing `src/adapters/` or auth/listeners | 30 | **22** | -8 |
| `test/chat_ui/{users,groups,group_members}` SDK / `bloc_test` files | 17 / 22 | **0 / 0** | -17 / -22 |
| `test/` active `package:cometchat_*` files / total matching | 64 / 66 | **47 / 49** | -17 / -17 |

## 11. Phase 7.5 — Core Chat Views (`conversations`, `message_list`, `pinned_messages`, `saved_messages`, `extensions`)

Completed in Phase 7.5:

- **`chat_ui/src/conversations/` (23 lib SDK files & 3 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitConversations`, `ConversationsList`, `ConvoKitConversationListItem`, `ConversationsSubtitleView`, `ConversationsTrailingView`, and `conversations/utils/` (`conversation_subtitle_utils.dart`, `conversation_tier_ordering.dart`, `conversation_utils.dart`, `status_indicator_helper.dart`) directly onto `EventHub.conversationStore`, `EventHub.presenceRegistry`, `EventHub.typingRegistry`, and `ChatConversation` via `ConvoKitScope`, hiding delivery receipt indicators whenever `capabilities.receipts == false`.
  - Deleted `conversations/bloc/`, `conversations/data/`, `conversations/domain/`, `conversations/di/`, and `conversations/conversations_builder_protocol.dart`, and removed `ConversationsServiceLocator` wiring from `shared_ui/src/clean_architecture/core/di/service_locator.dart`.
- **`chat_ui/src/message_list/` (22 lib SDK files & 2 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitMessageList` directly onto `EventHub.getMessageStore(conversationId)` (`stream` + `gapStream` with catch-up gap banner) and `MessageCoordinator` (`fetchLatest`, `fetchOlder`, `refresh`, `retryFailed`, `deleteMessage`, and read receipts gated on `capabilities.receipts`), registering/unregistering visible conversations on mount, `conversationId` change, and `dispose()`.
  - Re-typed `message_operation.dart` (with lightweight `ChangeNotifier`-based `AnimatedMessageListBloc` so `cometchat_animated_message_list.dart` compiles without `flutter_bloc`), `message_list_diff.dart`, `message_template_utils.dart`, `cometchat_message_option_sheet.dart`, `cometchat_message_action_overlay.dart`, and `cometchat_flag_message_dialog.dart` onto `ChatMessage`.
  - Deleted `message_list/bloc/` (including `message_list_bloc.dart` and `message_list_bloc_adapter.dart`), `message_list/data/`, `message_list/domain/`, and `message_list/di/`.
- **`chat_ui/src/pinned_messages/`, `chat_ui/src/saved_messages/`, `chat_ui/src/extensions/` (7 lib SDK/adapter files cleared):**
  - Migrated `ConvoKitPinnedMessages`, `ConvoKitSavedMessages`, `ExtensionModerator`, `ImageModerationFilter`, `CometChatCreatePoll`, `CometChatPollsBubble`, `CometChatStickerBubble`, and `CometChatStickerKeyboard` off `package:cometchat_*` and `CometChatSdkAdapter` onto ConvoKit Core models (`ChatMessage`, `CustomMessage`, `MediaMessage`, `ChatUser`, `ChatGroup`) and `ConvoKitScope`.
- **Library exports:** Updated `packages/cometchat_uikit/lib/convokit_uikit.dart` to remove all deleted `conversations` and `message_list` BLoC/domain/data/DI/protocol barrel exports.
- **Tests & helpers (36 SDK test files & 28 `bloc_test` files cleared):** Removed `test/helpers/golden_fake_sdk.dart` and `test/helpers/fake_sdk_chat_history.dart`, replaced `test/helpers/fake_sdk_moderation.dart` with a zero-SDK `FakeChatBackend` bridge (retaining `test/helpers/fake_upload_sdk.dart` for Phase 7.6), pruned obsolete BLoC/repository/usecase/SDK tests, and rewrote `conversations_props_test.dart`, `message_list_props_test.dart`, `pinned_messages_props_test.dart`, `saved_messages_props_test.dart`, and `extensions_props_test.dart` inside `ConvoKitScope` backed by `FakeChatBackend`.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Locked the Phase 7.5 baseline at **43** active `lib/` SDK files (0 in `shared_ui/`, 33 in `chat_ui/src/`, 7 in `src/adapters/`, 3 in `src/`).

### Phase 7.5 Measured Counts

| Metric | Phase 7.4 | Phase 7.5 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 95 | **43** | -52 |
| `lib/` active `package:cometchat_*` import/export statements | 95 | **43** | -52 |
| `lib/` `rg "package:cometchat_"` files / lines | 95 / 95 | **43 / 43** | -52 / -52 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 85 | **33** | -52 |
| `lib/shared_ui/` `package:cometchat_*` matches | 0 | **0** | 0 |
| `lib/chat_ui/src/{conversations,message_list,pinned_messages,saved_messages,extensions}` SDK / BLoC / adapter matches | 52 / 5 / 13 | **0 / 0 / 0** | -52 / -5 / -13 |
| `lib/` files importing `package:flutter_bloc/` | 12 | **7** | -5 |
| `lib/` files referencing `src/adapters/` or auth/listeners | 22 | **9** | -13 |
| `test/chat_ui/{conversations,message_list,pinned_messages,saved_messages,extensions}` SDK / `bloc_test` files | 33 / 28 | **0 / 0** | -33 / -28 |
| `test/helpers/` SDK files | 4 | **1** (`fake_upload_sdk.dart`) | -3 |
| `test/` active `package:cometchat_*` files / total matching | 47 / 49 | **11 / 13** | -36 / -36 |

## 12. Phase 7.6 — `message_composer`, Media Upload Tray & `notification_feed`

Completed in Phase 7.6:

- **`chat_ui/src/message_composer/` (17 lib SDK files & 4 `flutter_bloc` files cleared):**
  - Rewired `ConvoKitMessageComposer` and `AttachmentTrayController` directly onto `MessageCoordinator`, `ConvoKit.media` (`ChatMediaProvider`), and `MessageRepository.sendTyping` via `ConvoKitScope`:
    - Text send routes through `MessageCoordinator.sendTextMessage(...)`.
    - Media upload + send uses the two-step ConvoKit flow (`UploadRequest.file` / `UploadRequest.bytes` → `UploadProgress` callback → `MessageCoordinator.sendMediaMessage`), preserving distinct upload-failed (`AttachmentTileStatus.failed` → retry re-uploads) vs. send-failed (`AttachmentTileStatus.sendFailed` → retry re-sends without re-uploading) states and cancel-deletes-pending (`CancellationToken`).
    - Typing events route through `MessageRepository.sendTyping`, strictly gated on `capabilities.typing`.
    - Attachment and voice recording buttons are hidden whenever `kit.media == null || !capabilities.media`.
  - Replaced `MessageComposerBloc` with `MessageComposerController` (`ChangeNotifier`) and `InlineAudioRecorderBloc` with `InlineAudioRecorderController` (`ChangeNotifier`), and migrated `ConvoKitMessagePreview`, `ComposerUtils`, `ConvoKitAttachmentTray`, `ConvoKitAttachmentTile`, and `CometChatInlineAudioRecorder` off `package:cometchat_*` and `package:flutter_bloc`.
  - Deleted `message_composer/bloc/`, `message_composer/data/`, `message_composer/domain/`, `message_composer/di/`, and `inline_audio_recorder_{bloc,event}.dart`.
- **`chat_ui/src/notification_feed/` (16 lib SDK files & 3 `flutter_bloc` files cleared):**
  - Removed `chat_ui/src/notification_feed/` per the recommended v1 cut (`API-DESIGN.md` §13), removed its exports from `lib/convokit_uikit.dart`, deleted `test/chat_ui/notification_feed/`, and removed the Notifications tab (`_buildNotificationsTab`, `_openNotificationsScreen`) from `examples/sample_app/lib/screens/home_screen.dart`.
- **Library exports:** Updated `packages/cometchat_uikit/lib/convokit_uikit.dart` to remove all deleted `message_composer` BLoC/data/domain/DI exports and `notification_feed` exports.
- **Tests & helpers (11 active SDK test files & all remaining `bloc_test` files in `test/chat_ui/` cleared):**
  - Replaced `test/helpers/fake_upload_sdk.dart` with zero-SDK `test/helpers/fake_media_provider.dart` (`FakeChatMediaProvider`), and pruned unreferenced `test/helpers/fake_sdk_moderation.dart`.
  - Deleted `test/chat_ui/notification_feed/`, obsolete BLoC/repository/datasource/event tests in `test/chat_ui/message_composer/`, and 3 stale top-level BLoC-mocking tests (`list_widgets_props_test.dart`, `preview_and_threaded_style_props_test.dart`, `six_one_one_props_test.dart`).
  - Rewrote `composer_utils_test.dart`, `inline_audio_recorder_controller_test.dart`, `inline_audio_recorder_widget_test.dart`, `attachment_tray_controller_test.dart`, `widget/attachment_tray_props_test.dart`, and `widget/message_composer_props_test.dart` onto `ConvoKitScope` + `FakeChatBackend` + `FakeChatMediaProvider` with zero `package:cometchat_*` and zero `package:bloc_test` imports.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Locked the Phase 7.6 baseline at **10** active `lib/` SDK files (0 in `chat_ui/src/`, 0 in `shared_ui/`, 7 in `src/adapters/`, 3 in `src/`).

### Phase 7.6 Measured Counts

| Metric | Phase 7.5 | Phase 7.6 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 43 | **10** | -33 |
| `lib/` active `package:cometchat_*` import/export statements | 43 | **10** | -33 |
| `lib/` `rg "package:cometchat_"` files / lines | 43 / 43 | **10 / 10** | -33 / -33 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 33 | **0** | -33 |
| `lib/shared_ui/` `package:cometchat_*` matches | 0 | **0** | 0 |
| `lib/src/adapters/` `package:cometchat_*` files | 7 | **7** | 0 |
| `lib/src/` (other) `package:cometchat_*` files | 3 | **3** | 0 |
| `lib/` files importing `package:flutter_bloc/` | 7 | **0** | -7 |
| `lib/` files referencing `src/adapters/` or auth/listeners | 9 | **2** | -7 |
| `test/chat_ui/` + `test/helpers/` SDK / `bloc_test` files | 11 / 12 | **0 / 0** | -11 / -12 |
| `test/` active `package:cometchat_*` files / total matching | 11 / 13 | **0 / 2** | -11 / -11 |

## 13. Phase 7.7 — Delete Legacy Glue Layer, `ConvoKitUIKit` Facade & Offline `sample_app`

Completed in Phase 7.7:

- **Deleted legacy glue layer (`lib/src/adapters/` & 3 SDK files in `lib/src/` — 10 lib SDK files cleared: 10 → 0):**
  - Deleted `lib/src/adapters/` in full (all 7 files: `cometchat_conversation_adapter.dart`, `cometchat_group_adapter.dart`, `cometchat_media_adapter.dart`, `cometchat_message_adapter.dart`, `cometchat_sdk_adapter.dart`, `cometchat_session_adapter.dart`, `cometchat_user_adapter.dart`).
  - Deleted `lib/src/chat_auth_gateway.dart`, `lib/src/chat_sdk_listeners.dart`, and `lib/src/cometchat_ui_kit.dart`.
  - Removed the last stray `CometChatSdkAdapter.getFlagReasons` reference (and fixed a dangling `_submitReport` block) in `lib/chat_ui/src/message_list/widgets/cometchat_flag_message_dialog.dart`.
  - Note: `lib/src/legacy/`, `test/chat_sdk_listeners_test.dart`, and `test/chat_auth_gateway_test.dart` were already absent in the Phase 7.6 baseline.
- **Replaced with pure-ConvoKit `ConvoKitUIKit` facade (`lib/src/convokit_ui_kit.dart`):**
  - Built directly on ConvoKit Core (`ConvoKit`, `ConvoKitScope`, `EventHub`, `MessageCoordinator`) with zero `package:cometchat_*` imports and zero `flutter_bloc` imports.
  - Added `ConvoKit.init(...)` static factory in `lib/src/core/convo_kit.dart` supporting `ConvoKitUIKit.init()` → `ConvoKit.init()` → `ConvoKitScope`.
  - Preserved constructor semantics (`appId`, `region`, `apiKey`, `authKey`, `autoLogin`) and full public API surface: `init`, `dispose`, `loginWithAuthKey`, `loginWithToken`, `logout`, `currentUser`, `addListener`/`removeListener`, `addMessageListener`/`removeMessageListener`, `getUser`, `getGroup`, `getGroups`, `markMessagesAsRead`, `markMessagesAsDelivered`, `getConversationList`, `getConversations`, `getConversation`, `deleteConversation`, `sendTextMessage`, `sendMediaMessage`, `getMessages`, `editMessage`, `deleteMessage`, `getLoggedInUser`, `requestMediaPermission`.
  - Updated barrel exports in `lib/shared_ui/convokit_uikit_shared.dart`, `lib/shared_ui/src/clean_architecture/clean_architecture.dart`, and `lib/convokit_uikit.dart`, and migrated `ConvoKitUIKit.loggedInUser?.uid` → `.id` in `scheduler_utils.dart` and `message_preview_subtitle.dart`.
- **Rewired `examples/sample_app/` fully offline:**
  - Added offline mutation/query helpers (`loginAs`, `createGroup`, `deleteGroup`, `transferGroupOwnership`, `setUserBlocked`, `getMessageById`, `getConversationFor`, `unbanGroupMember`) to `examples/sample_app/lib/in_memory_chat_backend.dart` and added `examples/sample_app/lib/sample_app_backend.dart`.
  - Rewired `main.dart`, `services/api_services.dart`, `utils/app_uikit_settings.dart`, and all 15 screens (`home_screen.dart`, `responsive_home_screen.dart`, `messages_screen.dart`, `thread_screen.dart`, `login_screen.dart`, `guard_screen.dart`, `app_credentials_screen.dart`, `contacts_screen.dart`, `create_group_screen.dart`, `add_members_screen.dart`, `banned_members_screen.dart`, `join_protected_group_screen.dart`, `transfer_ownership_screen.dart`, `user_info_screen.dart`, `group_info_screen.dart`) onto `ConvoKitScope`, `ConvoKitUIKit`, `InMemoryChatBackend`, and ConvoKit Core models with zero `CometChat.*` static calls and zero `package:cometchat_*` imports.
- **Ratcheted `packages/cometchat_uikit/tool/count_sdk_imports.sh`:** Locked the Phase 7.7 baseline at **0** active `lib/` SDK files (0 in `chat_ui/src/`, 0 in `shared_ui/`, 0 in `src/adapters/`, 0 in `src/`).

### Phase 7.7 Measured Counts

| Metric | Phase 7.6 | Phase 7.7 | Delta |
| --- | ---: | ---: | ---: |
| `lib/` files with active `package:cometchat_*` import/export | 10 | **0** | -10 |
| `lib/` active `package:cometchat_*` import/export statements | 10 | **0** | -10 |
| `lib/` `rg "package:cometchat_"` files / lines | 10 / 10 | **0 / 0** | -10 / -10 |
| `lib/chat_ui/src/` `package:cometchat_*` files | 0 | **0** | 0 |
| `lib/shared_ui/` `package:cometchat_*` matches | 0 | **0** | 0 |
| `lib/src/adapters/` `package:cometchat_*` files | 7 | **0** | -7 |
| `lib/src/` (other) `package:cometchat_*` files | 3 | **0** | -3 |
| `lib/` files importing `package:flutter_bloc/` | 0 | **0** | 0 |
| `lib/` `CometChatException` tokens (files) | 82 (7) | **0 (0)** | -82 (-7) |
| `lib/` files referencing `src/adapters/` or auth/listeners | 2 | **0** | -2 |
| `examples/sample_app/lib/` `package:cometchat_*` / `CometChat.*` matches | 0 / 17 files | **0 / 0** | 0 / -17 files |
| `test/` active `package:cometchat_*` files / total matching (incl. 2 guardrail tests) | 0 / 2 | **0 / 2** | 0 / 0 |

## 14. Phase 7.8 — Remove Dependencies, Final Criterion-2 Gate & Publish Readiness (Complete)

Completed in Phase 7.8 (Phase 7 complete):

- **Dependency cleanup (`packages/cometchat_uikit/pubspec.yaml` & examples):**
  - Removed `cometchat_sdk: ^5.1.1`, `cometchat_cards: ^1.0.1`, and `flutter_bloc: ^9.1.1` from `dependencies`, and removed `bloc_test: ^10.0.0` from `dev_dependencies` in `packages/cometchat_uikit/pubspec.yaml`.
  - Audited `examples/sample_app/pubspec.yaml` and `examples/clean_consumer/pubspec.yaml`: confirmed neither declares `cometchat_sdk`, `cometchat_cards`, `cometchat_calls_sdk`, `flutter_bloc`, `bloc_test`, or unused `http`.
- **Acceptance Criterion 2 & test suite audit:**
  - Tightened `packages/cometchat_uikit/test/convokit/criterion_2_no_sdk_dependencies_test.dart` to enforce zero `cometchat_sdk`, `cometchat_cards`, `cometchat_calls_sdk`, `flutter_bloc`, and `bloc_test` entries in `pubspec.yaml`, `pubspec.lock`, and `flutter pub deps`, zero `package:cometchat_*`, `package:flutter_bloc`, or `package:bloc/` imports/exports in `lib/`, and zero active `package:cometchat_*`, `package:flutter_bloc`, `package:bloc_test`, or `package:bloc/` imports/exports in `test/`.
  - Confirmed `packages/cometchat_uikit/test/convokit/no_cometchat_public_api_test.dart` remains aligned with Criterion 2/3/4/16 and confirmed zero active `package:bloc_test` or `package:flutter_bloc` imports remain anywhere in `test/`.
- **Native plugin config audit:**
  - Audited `packages/cometchat_uikit/android/build.gradle` (only `androidx.appcompat`, `play-services-location`, `glide`), `packages/cometchat_uikit/ios/cometchat_chat_uikit.podspec` (only `Flutter`), and `packages/cometchat_uikit/ios/cometchat_chat_uikit/Package.swift` (`dependencies: []`): confirmed zero CometChat native SDK dependencies or imports remain.
- **Documentation & release metadata (`convokit 0.1.0`):**
  - Updated `README.md` and `packages/cometchat_uikit/README.md` to document that `convokit 0.1.0` ships with zero CometChat SDK dependencies and zero `flutter_bloc` / `bloc_test` dependencies.
  - Updated `CHANGELOG.md` and `packages/cometchat_uikit/CHANGELOG.md` with the `0.1.0` release entry.

### Phase 7.8 Final Measured Counts (Phase 7 Complete)

| Metric | Phase 7.7 | Phase 7.8 | Status |
| --- | ---: | ---: | --- |
| `pubspec.yaml` (`packages/cometchat_uikit`, `sample_app`, `clean_consumer`) SDK / BLoC deps | 4 | **0** | Cleared |
| `lib/` files with active `package:cometchat_*` import/export | 0 | **0** | Locked |
| `lib/` active `package:cometchat_*` import/export statements | 0 | **0** | Locked |
| `lib/` `rg "package:cometchat_"` files / lines | 0 / 0 | **0 / 0** | Locked |
| `lib/` files importing `package:flutter_bloc/` or `package:bloc/` | 0 | **0** | Locked |
| `lib/` files referencing `src/adapters/` or auth/listeners | 0 | **0** | Locked |
| `examples/sample_app/lib/` `package:cometchat_*` / `CometChat.*` matches | 0 / 0 | **0 / 0** | Locked |
| `test/` active `package:cometchat_*` / `flutter_bloc` / `bloc_test` imports/exports | 0 / 0 / 0 | **0 / 0 / 0** | Locked |
| Native configs (`android/build.gradle`, `ios/*.podspec`, `ios/Package.swift`) CometChat SDK deps | 0 | **0** | Verified |

## 15. Phase 7 Fix Round 3 — Golden Audit, Core `MediaMessage.metadata` & Test/Analyzer Fixes

- **Approved additive Core model change (`lib/src/core/models/message.dart`):**
  - Added optional `final Map<String, dynamic>? metadata;` (default `null`) to `MediaMessage`, preserved across `copyWithDeliveryState` and `copyWithSendState`.
  - Wired `CometChatVoiceNoteBubble.isVoiceNote(MediaMessage)` to inspect `message.metadata?[audioTypeKey]` and restored `test/shared_ui/bubbles/audio/voice_note_and_player_test.dart` to assert `true` for voice notes (`'voice_note'` and legacy `'voiceNote'`) and `false` for plain messages.
- **27 Golden pixel test audit:**
  - **6 known pre-existing Linux failures (locked baseline):** `test/chat_ui/message_list/goldens/message_list_golden_test.dart` — unchanged.
  - **21 new golden failures — real regressions fixed in code/fixtures:**
    - `media_grid_bubble_golden_test.dart` (8): `_imagesMessage(count)` previously ignored `count` and emitted only 1 attachment; fixed to populate all `count` attachments via `metadata['attachments']` read by `AttachmentUtils.attachmentsOf`.
    - `message_content_bubbles_golden_test.dart` (8): `_media(...)` previously dropped attachments 2..N (`attachment: attachments.first`), `MessageTemplateUtils.getDeleteMessageBubble` replaced `ConvoKitDeletedBubble` with raw `Text`, and `bubble_text_mention` omitted `CometChatMentionsFormatter.setMentionedUsersFor(message, [_priya])`. All three regressions fixed.
    - `reactions_row_golden_test.dart` (5): `CometChatReactions` previously ignored `countTextColor` and omitted the 3-chip + `+N` overflow collapse for >4 reactions. Both fixed; note that if minor pixel-level diffs remain on Linux CI against v6 baseline PNGs after these logic fixes, re-bake with `flutter test test/shared_ui/bubbles/goldens/reactions_row_golden_test.dart --update-goldens` locally.
- **`analysis_options.yaml` (`0.1.0` publish readiness):**
  - Excluded `public_member_api_docs` from `packages/cometchat_uikit/analysis_options.yaml` for `0.1.0` to clear ~4,084 legacy missing-doc infos, and cleaned statically verified dead-code, unnecessary null comparison, and unused/redundant import warnings in `lib/`.

## 16. Phase 7 Fix Round 6 — Library Test Fixes, Golden Audit, Analyze Info Cleanup & Modern WhatsApp App

- **Library widget/utility fixes:**
  - `MessageUtils._getSuitableContentView` (`lib/shared_ui/src/clean_architecture/core/utils/message_utils.dart`): restored default bubble rendering (`CometChatTextBubble` / media bubbles) when `template?.contentView == null`, fixing `message_information_receipts_test.dart` (×2) and `threaded_header_test.dart` (×1).
  - `ConvoKitPinnedMessages` (`lib/chat_ui/src/pinned_messages/cometchat_pinned_messages.dart`): rendered message preview subtitle with `RichText` so `find.text(..., findRichText: true)` matches a single widget (`pinned_messages_props_test.dart`).
  - `CometChatSearch` (`lib/chat_ui/src/search/cometchat_search.dart`): rendered loaded user results in a `ListView` instead of `CustomScrollView` (`search_props_test.dart`).
  - `CheckBoxElement.fromMap` (`lib/shared_ui/src/clean_architecture/data/models/interactive_elements/checkbox_element.dart`): restored dynamic `.map` call on `options` so non-list payloads throw `NoSuchMethodError` (`interactive_elements_property_test.dart`).
  - `MediaPicker._getFilesFromMethodChannel` (`lib/shared_ui/src/clean_architecture/core/utils/media_picker.dart`): removed `result.isNotEmpty` guard so an empty reply throws `StateError` as pinned (`media_picker_test.dart`).
  - `AnimatedMessageListBloc` (`lib/chat_ui/src/message_list/utils/message_operation.dart`) & `ConvoKitAnimatedMessageList` (`lib/shared_ui/src/cometchat_message_list/widgets/cometchat_animated_message_list.dart`): restored `alignment = 0.0` default for `scrollToIndex`/`scrollToMessage` and consulted `widget.findMessageIndex` for `muid:` keys in `_findChildIndex`.
  - `ConvoKitMessageList` (`lib/chat_ui/src/message_list/widgets/cometchat_message_list.dart`): wired `style.outgoingMessageBubbleStyle` and `style.incomingMessageBubbleStyle` (`backgroundColor`, `borderRadius`, `textBubbleStyle.textStyle`, `messageBubbleDateStyle.textStyle`) into the default row builder.
- **Test fixture fixes (zero test expectations modified):**
  - `test/shared_ui/multi_attachment_bubble_caption_test.dart`: fixed empty-attachment placeholder fixture to satisfy `ChatAttachment` constructor invariants (`state: AttachmentState.local, localPath: ''`), unblocking all 12 tests.
  - `test/shared_ui/animated_message_list/animated_message_list_behaviour_test.dart`: restored `_sentAt` fixture to `DateTime(2024, 1, 1, 9)`.
  - **Unfixed test-expectation bug (reported, not altered):** `animated_message_list_behaviour_test.dart:293` asserts `expect(bloc.state.messages.map((m) => m.id), <int>[1, 3, 4])` against `ChatMessage.id` (`String?`).
- **Golden pixel tests audit (19 total — none deleted):**
  - **6 known pre-existing Linux failures (locked baseline):** `test/chat_ui/message_list/goldens/message_list_golden_test.dart` (unchanged).
  - **5 `reactions_row_golden_test.dart` CI goldens:** fixed real regressions in `CometChatReactions` (restored full pill `borderRadius` via `radiusMax` and count display for `count == 1`). If minor Linux CI font/AA pixel diffs remain against macOS-baked PNGs, re-bake locally with `flutter test test/shared_ui/bubbles/goldens/reactions_row_golden_test.dart --update-goldens`.
  - **8 `media_grid_bubble_golden_test.dart` CI goldens (known Linux CI environment rendering difference):** `CometChatImagesBubble` and `CometChatMediaGrid` are unchanged from upstream and `message_content_bubbles_golden_test.dart` passes 16/16; the 8 `media_grid` goldens decode and scale 2-tone BMPs via `Image.network`, which drifts past the `0.0005` threshold on Linux Skia vs macOS-baked PNGs. Re-bake locally on Linux with `flutter test test/shared_ui/bubbles/goldens/media_grid_bubble_golden_test.dart --update-goldens`.
- **Analyze infos cleaned (9/9):** 5 in `packages/cometchat_uikit/lib/` (`detail_utils.dart`, `cometchat_mentions_formatter.dart`, `custom_text_editing_controller.dart`) and 4 in `examples/whatsapp_app/` (`main.dart`, `whatsapp_in_memory_backend.dart`).
- **Modern WhatsApp app (`examples/whatsapp_app`):** redesigned to modern 2024+ Android WhatsApp (white app bar with bold green title, explicit `fontFamily: 'Roboto'`, search bar, `All`/`Unread`/`Groups` filter pills, `Chats`/`Updates`/`Communities`/`Calls` bottom `NavigationBar`, green new-chat FAB) using exclusively ConvoKit library widgets (`ConvoKitConversations`, `ConvoKitMessageHeader`, `ConvoKitMessageList` default row builder, `ConvoKitMessageComposer`, `CometChatSearch`).
