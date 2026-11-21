import 'package:convokit/convokit.dart';

import 'studio_conversation_repository.dart';
import 'studio_event_source.dart';
import 'studio_group_repository.dart';
import 'studio_media_provider.dart';
import 'studio_message_repository.dart';
import 'studio_seed_data.dart';
import 'studio_session.dart';
import 'studio_user_repository.dart';

/// Composition root assembling all 7 frozen ConvoKit contracts into a ready-to-use
/// offline "Atelier Studio" [ConvoKit] instance with [ChatCapabilities.basic()].
class StudioBackend {
  StudioBackend._({
    required this.seedSnapshot,
    required this.session,
    required this.events,
    required this.users,
    required this.conversations,
    required this.messages,
    required this.groups,
    required this.media,
    required this.kit,
    DateTime? anchorTime,
  }) : _anchorTime = anchorTime;

  /// Creates a fresh offline [StudioBackend] populated with [StudioSeedData].
  ///
  /// Pass [anchorTime] in tests for deterministic timestamps; omit to anchor
  /// seeded messages relative to [DateTime.now].
  factory StudioBackend.create({
    Duration deliveredReceiptDelay = const Duration(milliseconds: 120),
    Duration readReceiptDelay = const Duration(milliseconds: 300),
    Duration mediaUploadStepDelay = const Duration(milliseconds: 20),
    int mediaUploadProgressSteps = 4,
    DateTime? anchorTime,
  }) {
    final snapshot = StudioSeedData.create(anchorTime: anchorTime);
    final session = StudioSession(initialUser: snapshot.currentUser);
    final events = StudioEventSource();
    final users = StudioUserRepository(
      initialUsers: snapshot.users,
      eventSource: events,
    );
    final conversations = StudioConversationRepository(
      initialConversations: snapshot.conversations,
      eventSource: events,
    );
    final messages = StudioMessageRepository(
      initialMessages: snapshot.messagesByConversation,
      initialPinnedMessages: snapshot.pinnedByConversation,
      initialSavedMessages: snapshot.savedMessages,
      session: session,
      eventSource: events,
      conversationRepository: conversations,
      deliveredReceiptDelay: deliveredReceiptDelay,
      readReceiptDelay: readReceiptDelay,
    );
    final groups = StudioGroupRepository(
      initialGroups: snapshot.groups,
      session: session,
      userRepository: users,
      conversationRepository: conversations,
    );
    final media = StudioMediaProvider(
      stepDelay: mediaUploadStepDelay,
      progressSteps: mediaUploadProgressSteps,
    );

    final kit = ConvoKit.init(
      session: session,
      users: users,
      conversations: conversations,
      messages: messages,
      events: events,
      groups: groups,
      media: media,
      capabilities: ChatCapabilities.basic(),
    );

    return StudioBackend._(
      seedSnapshot: snapshot,
      session: session,
      events: events,
      users: users,
      conversations: conversations,
      messages: messages,
      groups: groups,
      media: media,
      kit: kit,
      anchorTime: anchorTime,
    );
  }

  final DateTime? _anchorTime;

  /// Initial seed snapshot (exposes studio roles and IDs).
  final StudioSeedSnapshot seedSnapshot;

  final StudioSession session;
  final StudioEventSource events;
  final StudioUserRepository users;
  final StudioConversationRepository conversations;
  final StudioMessageRepository messages;
  final StudioGroupRepository groups;
  final StudioMediaProvider media;

  /// Validated [ConvoKit] instance wired into [ConvoKitScope].
  final ConvoKit kit;

  /// Restores all repositories, session, and media state back to a fresh
  /// Atelier Studio seed snapshot.
  void reset({DateTime? anchorTime}) {
    final fresh = StudioSeedData.create(
      anchorTime: anchorTime ?? _anchorTime,
    );
    session.reset(fresh.currentUser);
    users.reset(fresh.users);
    conversations.reset(fresh.conversations);
    messages.reset(
      messagesByConversation: fresh.messagesByConversation,
      pinnedByConversation: fresh.pinnedByConversation,
      savedMessages: fresh.savedMessages,
    );
    groups.reset(fresh.groups);
    media.reset();
  }

  /// Releases timers and stream controllers owned by the offline backend.
  Future<void> dispose() async {
    messages.dispose();
    await events.dispose();
    await session.dispose();
  }
}
