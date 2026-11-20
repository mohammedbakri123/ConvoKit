# ConvoKit Phase 7: CometChat SDK Footprint Inventory

Date: 2026-11-20
Measured on branch: `convokit/phase-7` (forked from `convokit/phase-6` at fbdba20)

## 1. Summary of Measured Footprint

- **Lib files importing SDK/Cards:** 147 files
  - `package:cometchat_sdk/`: 146 files
  - `package:cometchat_cards/`: 2 files (1 overlaps with SDK import)
  - `package:cometchat_calls_sdk/`: 0 files
- **Test files importing SDK/Cards:** 86 files
  - `package:cometchat_sdk/`: 86 files
  - `package:cometchat_cards/`: 1 file
- **Sample app / Clean Consumer:** 0 files importing SDK/Cards
- **Pubspec dependencies to remove:** `cometchat_sdk: ^5.1.1`, `cometchat_cards: ^1.0.1`
- **Key identifier usages in lib:**
  - `CometChatException`: 270 occurrences across lib
  - `CometChatSdkAdapter`: 158 occurrences across lib
  - `src/adapters/` imports in lib: 40 files

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
