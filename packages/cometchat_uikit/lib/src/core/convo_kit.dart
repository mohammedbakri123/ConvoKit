/// The ConvoKit composition root holder according to API-DESIGN.md §11.1.
library;

import '../contracts/capabilities.dart';
import '../contracts/conversation_repository.dart';
import '../contracts/event_source.dart';
import '../contracts/group_repository.dart';
import '../contracts/media_provider.dart';
import '../contracts/message_repository.dart';
import '../contracts/session.dart';
import '../contracts/user_repository.dart';

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
  final GroupRepository? groups; // null ⟺ capabilities.groups == false
  final ChatMediaProvider? media; // null ⟺ capabilities.media == false

  /// Not const: validation runs in the constructor body, so it throws
  /// `ArgumentError` in release builds too.
  ConvoKit({
    required this.session,
    required this.users,
    required this.conversations,
    required this.messages,
    required this.events,
    ChatCapabilities capabilities = const ChatCapabilities(),
    this.groups,
    this.media,
  }) : capabilities =
            _resolveCapabilities(capabilities, groups != null, media != null) {
    if ((groups == null) != !this.capabilities.groups) {
      throw ArgumentError(
        'groups provider and capabilities.groups disagree: '
        'pass a GroupRepository exactly when capabilities.groups is true.',
      );
    }
    if ((media == null) != !this.capabilities.media) {
      throw ArgumentError(
        'media provider and capabilities.media disagree: '
        'pass a ChatMediaProvider exactly when capabilities.media is true.',
      );
    }
    if (this.capabilities.mediaDelete && media == null) {
      throw ArgumentError('mediaDelete requires a media provider.');
    }
  }

  static ChatCapabilities _resolveCapabilities(
    ChatCapabilities requested,
    bool hasGroups,
    bool hasMedia,
  ) {
    if (requested == ChatCapabilities.basic() && (!hasGroups || !hasMedia)) {
      return ChatCapabilities(
        receipts: requested.receipts,
        typing: requested.typing,
        media: hasMedia,
        mediaDelete: hasMedia,
        groups: hasGroups,
        search: requested.search,
        messageCatchUp: requested.messageCatchUp,
      );
    }
    return requested;
  }

  /// Convenience initializer returning a validated [ConvoKit] instance for
  /// `ConvoKitUIKit.init()` -> `ConvoKit.init()` -> `ConvoKitScope`.
  static ConvoKit init({
    required ChatSession session,
    required UserRepository users,
    required ConversationRepository conversations,
    required MessageRepository messages,
    required ChatEventSource events,
    ChatCapabilities capabilities = const ChatCapabilities(),
    GroupRepository? groups,
    ChatMediaProvider? media,
  }) => ConvoKit(
    session: session,
    users: users,
    conversations: conversations,
    messages: messages,
    events: events,
    capabilities: capabilities,
    groups: groups,
    media: media,
  );
}
