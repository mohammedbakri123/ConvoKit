import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';

/// Sample status update model for the Updates tab.
class BlueStatusUpdate {
  const BlueStatusUpdate({
    required this.user,
    required this.caption,
    required this.postedAt,
    required this.unseenCount,
  });

  final ChatUser user;
  final String caption;
  final DateTime postedAt;
  final int unseenCount;
}

/// Sample call entry model for the Calls tab.
class BlueCallRecord {
  const BlueCallRecord({
    required this.peer,
    required this.timestamp,
    required this.isVideo,
    required this.isMissed,
    required this.isOutgoing,
    required this.durationLabel,
  });

  final ChatUser peer;
  final DateTime timestamp;
  final bool isVideo;
  final bool isMissed;
  final bool isOutgoing;
  final String durationLabel;
}

/// Full offline in-memory ConvoKit backend implementing all ConvoKit contracts
/// with rich sample contacts, groups, members, multi-type messages (text,
/// replies, mentions, media/voice/file/video/image, polls, stickers, cards),
/// pinned messages, saved messages, reactions, status updates, and call logs.
class BlueInMemoryBackend {
  late final ChatUser currentUser;
  late final ChatUser maya;
  late final ChatUser daniel;
  late final ChatUser sara;
  late final ChatUser leo;
  late final ChatUser hana;
  late final ChatUser youssef;

  late final ChatGroup designGroup;
  late final ChatGroup flutterGroup;
  late final ChatGroup sailGroup;

  late final List<ChatUser> _allUsers;
  late final List<ChatConversation> _conversationsList;
  late final Map<String, List<ChatMessage>> _messagesByConversation;
  late final List<ChatGroup> _groupsList;

  final Map<String, List<ChatMessage>> _pinnedByConversation = {};
  final List<ChatMessage> _savedMessages = [];
  final Map<String, List<Map<String, dynamic>>> _reactionsByMessageId = {};

  late final List<BlueStatusUpdate> statusUpdates;
  late final List<BlueCallRecord> callRecords;

  late final _BlueInMemorySession _session;
  late final _BlueInMemoryUserRepository _users;
  late final _BlueInMemoryConversationRepository _conversations;
  late final _BlueInMemoryMessageRepository _messages;
  late final _BlueInMemoryGroupRepository _groups;
  late final _BlueInMemoryMediaProvider _media;
  late final _BlueInMemoryEventSource _events;

  ChatSession get session => _session;
  UserRepository get users => _users;
  ConversationRepository get conversations => _conversations;
  MessageRepository get messages => _messages;
  GroupRepository get groups => _groups;
  ChatMediaProvider get media => _media;
  ChatEventSource get events => _events;

  BlueInMemoryBackend() {
    _initData();
    _session = _BlueInMemorySession(currentUser);
    _users = _BlueInMemoryUserRepository(this);
    _conversations = _BlueInMemoryConversationRepository(this);
    _messages = _BlueInMemoryMessageRepository(this);
    _groups = _BlueInMemoryGroupRepository(this);
    _media = _BlueInMemoryMediaProvider();
    _events = _BlueInMemoryEventSource();
  }

  /// Creates a validated [ConvoKit] composition root wired to this backend.
  ConvoKit createConvoKit() {
    return ConvoKit(
      session: session,
      users: users,
      conversations: conversations,
      messages: messages,
      groups: groups,
      media: media,
      events: events,
      capabilities: ChatCapabilities.basic(),
    );
  }

  List<ChatUser> get contacts =>
      _allUsers.where((u) => u.id != currentUser.id).toList(growable: false);

  List<ChatGroup> get allGroups => List<ChatGroup>.unmodifiable(_groupsList);

  int get totalUnreadCount =>
      _conversationsList.fold<int>(0, (sum, c) => sum + c.unreadCount);

  /// Looks up a seeded conversation by direct peer or group ID.
  ChatConversation? getConversationFor({String? userId, String? groupId}) {
    for (final conv in _conversationsList) {
      if (userId != null && conv.peer?.id == userId) return conv;
      if (groupId != null && conv.group?.id == groupId) return conv;
    }
    return null;
  }

  /// Returns pinned messages for a conversation (or all pinned if null).
  List<ChatMessage> pinnedMessagesFor(String? conversationId) {
    if (conversationId == null) {
      return _pinnedByConversation.values.expand((e) => e).toList();
    }
    return List<ChatMessage>.unmodifiable(
      _pinnedByConversation[conversationId] ?? const [],
    );
  }

  bool isPinned(ChatMessage message) {
    final list = _pinnedByConversation[message.conversationId] ?? const [];
    return list.any((m) => m.localId == message.localId);
  }

  void togglePin(ChatMessage message) {
    final list = _pinnedByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    final idx = list.indexWhere((m) => m.localId == message.localId);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, message);
    }
  }

  void unpinMessage(ChatMessage message) {
    _pinnedByConversation[message.conversationId]?.removeWhere(
      (m) => m.localId == message.localId,
    );
  }

  /// Returns all saved / bookmarked messages across conversations.
  List<ChatMessage> get savedMessages =>
      List<ChatMessage>.unmodifiable(_savedMessages);

  bool isSaved(ChatMessage message) =>
      _savedMessages.any((m) => m.localId == message.localId);

  void toggleSave(ChatMessage message) {
    final idx = _savedMessages.indexWhere((m) => m.localId == message.localId);
    if (idx >= 0) {
      _savedMessages.removeAt(idx);
    } else {
      _savedMessages.insert(0, message);
    }
  }

  void unsaveMessage(ChatMessage message) {
    _savedMessages.removeWhere((m) => m.localId == message.localId);
  }

  /// Returns reaction entries for a message (duck-typed Map list for
  /// [CometChatReactions]).
  List<Map<String, dynamic>> reactionsFor(String messageKey) {
    return List<Map<String, dynamic>>.from(
      _reactionsByMessageId[messageKey] ?? const [],
    );
  }

  void toggleReaction(String messageKey, String emoji) {
    final list = _reactionsByMessageId.putIfAbsent(messageKey, () => []);
    final idx = list.indexWhere((r) => r['reaction'] == emoji);
    if (idx >= 0) {
      final current = list[idx];
      final reactedByMe = current['reactedByMe'] == true;
      final count = (current['count'] as int? ?? 1) + (reactedByMe ? -1 : 1);
      if (count <= 0) {
        list.removeAt(idx);
      } else {
        list[idx] = {
          'reaction': emoji,
          'count': count,
          'reactedByMe': !reactedByMe,
        };
      }
    } else {
      list.add({'reaction': emoji, 'count': 1, 'reactedByMe': true});
    }
  }

  /// Updates a member's role inside an in-memory [ChatGroup].
  void updateMemberRole(String groupId, String userId, GroupRole newRole) {
    final gIdx = _groupsList.indexWhere((g) => g.id == groupId);
    if (gIdx == -1) return;
    final grp = _groupsList[gIdx];
    final updatedMembers = (grp.members ?? const <ChatMember>[]).map((m) {
      if (m.user.id == userId) {
        return ChatMember(user: m.user, role: newRole);
      }
      return m;
    }).toList();
    _groupsList[gIdx] = ChatGroup(
      id: grp.id,
      name: grp.name,
      description: grp.description,
      avatarUrl: grp.avatarUrl,
      type: grp.type,
      memberCount: updatedMembers.length,
      members: updatedMembers,
    );
  }

  /// Returns a sample message for demonstrations / sheets.
  ChatMessage get featuredSampleMessage =>
      _messagesByConversation['conv_me_user_maya']!.first;

  void _initData() {
    currentUser = const ChatUser(
      id: 'me',
      name: 'You',
      presence: UserPresence.online,
    );
    maya = const ChatUser(
      id: 'user_maya',
      name: 'Maya Lin',
      presence: UserPresence.online,
    );
    daniel = const ChatUser(
      id: 'user_daniel',
      name: 'Daniel Brooks',
      presence: UserPresence.online,
    );
    sara = const ChatUser(
      id: 'user_sara',
      name: 'Sara Al-Harbi',
      presence: UserPresence.away,
    );
    leo = const ChatUser(
      id: 'user_leo',
      name: 'Leo Martinez',
      presence: UserPresence.online,
    );
    hana = const ChatUser(
      id: 'user_hana',
      name: 'Hana Sato',
      presence: UserPresence.offline,
    );
    youssef = const ChatUser(
      id: 'user_youssef',
      name: 'Youssef Nabil',
      presence: UserPresence.offline,
    );

    _allUsers = [currentUser, maya, daniel, sara, leo, hana, youssef];

    designGroup = ChatGroup(
      id: 'group_design',
      name: 'Ocean Design Guild',
      description: 'Floating island UI, blue palettes, and motion studies',
      type: GroupType.public,
      memberCount: 5,
      members: [
        ChatMember(user: currentUser, role: GroupRole.owner),
        ChatMember(user: maya, role: GroupRole.admin),
        ChatMember(user: daniel, role: GroupRole.member),
        ChatMember(user: sara, role: GroupRole.member),
        ChatMember(user: leo, role: GroupRole.member),
      ],
    );

    flutterGroup = ChatGroup(
      id: 'group_flutter',
      name: 'Flutter Architecture',
      description: 'Pure-Dart stores, ConvoKit contracts, and zero-SDK builds',
      type: GroupType.private,
      memberCount: 4,
      members: [
        ChatMember(user: currentUser, role: GroupRole.owner),
        ChatMember(user: daniel, role: GroupRole.admin),
        ChatMember(user: hana, role: GroupRole.member),
        ChatMember(user: youssef, role: GroupRole.member),
      ],
    );

    sailGroup = ChatGroup(
      id: 'group_sail',
      name: 'Weekend Sail Club',
      description: 'Harbor departure times, tide charts & crew roster',
      type: GroupType.public,
      memberCount: 4,
      members: [
        ChatMember(user: maya, role: GroupRole.owner),
        ChatMember(user: currentUser, role: GroupRole.admin),
        ChatMember(user: leo, role: GroupRole.member),
        ChatMember(user: sara, role: GroupRole.member),
      ],
    );

    _groupsList = [designGroup, flutterGroup, sailGroup];

    final now = DateTime.now();
    final todayBase = now;
    final yesterdayBase = todayBase.subtract(const Duration(days: 1));
    final twoDaysAgoBase = todayBase.subtract(const Duration(days: 2));

    // Conversation 1: Maya Lin (rich mix: text, mention, reply, voice note, file, poll)
    const convMayaId = 'conv_me_user_maya';
    final mayaMsg1 = TextMessage(
      id: 'm_maya_1',
      localId: 'local_maya_1',
      conversationId: convMayaId,
      sender: maya,
      createdAt: yesterdayBase.add(const Duration(hours: 5, minutes: 10)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Morning! Check the new cobalt floating-island mockups at https://convokit.dev/design or email maya@convokit.dev.',
    );
    final mayaMsg2 = TextMessage(
      id: 'm_maya_2',
      localId: 'local_maya_2',
      conversationId: convMayaId,
      sender: currentUser,
      createdAt: yesterdayBase.add(const Duration(hours: 5, minutes: 18)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: mayaMsg1,
      text:
          'Love the deep blue primary and light-blue outgoing bubbles! Call me at +1-415-555-0199 if you want to walk through the tabs.',
    );
    final mayaVoice = MediaMessage(
      id: 'm_maya_3',
      localId: 'local_maya_3',
      conversationId: convMayaId,
      sender: maya,
      createdAt: todayBase.subtract(const Duration(minutes: 40)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_voice_1',
        remoteId: 'rem_voice_1',
        kind: AttachmentKind.audio,
        url: 'offline://voice_note_design_sync.m4a',
        state: AttachmentState.uploaded,
        mimeType: 'audio/mp4',
        sizeBytes: 94200,
        name: 'Voice note (0:34)',
      ),
      caption: 'Quick voice note on the floating pill nav spacing',
      metadata: const {'audioType': 'voice_note', 'audioDurationMs': 34000},
    );
    final mayaFile = MediaMessage(
      id: 'm_maya_4',
      localId: 'local_maya_4',
      conversationId: convMayaId,
      sender: currentUser,
      createdAt: todayBase.subtract(const Duration(minutes: 18)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      attachment: const ChatAttachment(
        id: 'att_file_1',
        remoteId: 'rem_file_1',
        kind: AttachmentKind.file,
        url: 'offline://Blue_Messenger_Spec_v2.pdf',
        state: AttachmentState.uploaded,
        mimeType: 'application/pdf',
        sizeBytes: 428000,
        name: 'Blue_Messenger_Spec_v2.pdf',
      ),
      caption: 'Blue_Messenger_Spec_v2.pdf',
    );
    final mayaLatest = TextMessage(
      id: 'm_maya_5',
      localId: 'local_maya_5',
      conversationId: convMayaId,
      sender: maya,
      createdAt: todayBase.subtract(const Duration(minutes: 3)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'The floating islands feel super crisp! Ready for review.',
    );
    final mayaMsgs = <ChatMessage>[
      mayaMsg1,
      mayaMsg2,
      mayaVoice,
      mayaFile,
      mayaLatest,
    ];

    // Conversation 2: Ocean Design Guild (group with poll, video, mentions)
    const convDesignId = 'conv_group_design';
    final designMsg1 = TextMessage(
      id: 'm_des_1',
      localId: 'local_des_1',
      conversationId: convDesignId,
      sender: daniel,
      createdAt: twoDaysAgoBase.add(const Duration(hours: 6)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          '@Maya Lin should we use 28px or 32px radius for the floating nav pill?',
    );
    final designPoll = CustomMessage(
      id: 'm_des_2',
      localId: 'local_des_2',
      conversationId: convDesignId,
      sender: currentUser,
      createdAt: yesterdayBase.add(const Duration(hours: 3, minutes: 20)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      kind: ExtensionConstants.polls,
      data: const {
        'question': 'Favorite Blue Messenger accent shade?',
        'options': {
          '1': 'Deep Cobalt (#0D47A1)',
          '2': 'Royal Ocean (#1976D2)',
          '3': 'Sky Pulse (#29B6F6)',
        },
        '@injected': {
          'extensions': {
            'polls': {
              'id': 'poll_accent_1',
              'results': {
                'total': 5,
                'options': {
                  '1': {
                    'text': 'Deep Cobalt (#0D47A1)',
                    'count': 3,
                    'voters': {
                      'me': {'name': 'You'},
                      'user_maya': {'name': 'Maya Lin'},
                      'user_sara': {'name': 'Sara Al-Harbi'},
                    },
                  },
                  '2': {
                    'text': 'Royal Ocean (#1976D2)',
                    'count': 1,
                    'voters': {
                      'user_daniel': {'name': 'Daniel Brooks'},
                    },
                  },
                  '3': {
                    'text': 'Sky Pulse (#29B6F6)',
                    'count': 1,
                    'voters': {
                      'user_leo': {'name': 'Leo Martinez'},
                    },
                  },
                },
              },
            },
          },
        },
      },
    );
    final designVideo = MediaMessage(
      id: 'm_des_3',
      localId: 'local_des_3',
      conversationId: convDesignId,
      sender: sara,
      createdAt: todayBase.subtract(const Duration(minutes: 22)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      attachment: const ChatAttachment(
        id: 'att_vid_1',
        remoteId: 'rem_vid_1',
        kind: AttachmentKind.video,
        url: 'offline://floating_island_prototype.mp4',
        state: AttachmentState.uploaded,
        mimeType: 'video/mp4',
        sizeBytes: 2450000,
        name: 'floating_island_prototype.mp4',
      ),
      caption: 'Recorded a quick walkthrough of the floating composer bar',
    );
    final designMsgs = <ChatMessage>[designMsg1, designPoll, designVideo];

    // Conversation 3: Flutter Architecture (group)
    const convFlutterId = 'conv_group_flutter';
    final flutterMsg1 = TextMessage(
      id: 'm_flt_1',
      localId: 'local_flt_1',
      conversationId: convFlutterId,
      sender: hana,
      createdAt: yesterdayBase.add(const Duration(hours: 4)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'All 2,441 tests passing and zero SDK imports across the package!',
    );
    final flutterMsg2 = TextMessage(
      id: 'm_flt_2',
      localId: 'local_flt_2',
      conversationId: convFlutterId,
      sender: currentUser,
      createdAt: todayBase.subtract(const Duration(minutes: 55)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Awesome — wiring up every ConvoKit component in Blue Messenger now.',
    );
    final flutterMsgs = <ChatMessage>[flutterMsg1, flutterMsg2];

    // Conversation 4: Daniel Brooks (direct)
    const convDanielId = 'conv_me_user_daniel';
    final danielMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_dan_1',
        localId: 'local_dan_1',
        conversationId: convDanielId,
        sender: daniel,
        createdAt: yesterdayBase.add(const Duration(hours: 7, minutes: 30)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Can you share the group members scope sheet when it is ready?',
      ),
      TextMessage(
        id: 'm_dan_2',
        localId: 'local_dan_2',
        conversationId: convDanielId,
        sender: currentUser,
        createdAt: todayBase.subtract(const Duration(minutes: 31)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Done! Tap any member inside Ocean Design Guild to change scope.',
      ),
    ];

    // Conversation 5: Sara Al-Harbi (direct)
    const convSaraId = 'conv_me_user_sara';
    final saraMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_sara_1',
        localId: 'local_sara_1',
        conversationId: convSaraId,
        sender: sara,
        createdAt: yesterdayBase.add(const Duration(hours: 8, minutes: 15)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'Pinned the launch checklist in our chat so we do not lose it.',
      ),
    ];

    // Conversation 6: Weekend Sail Club (group)
    const convSailId = 'conv_group_sail';
    final sailMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_sail_1',
        localId: 'local_sail_1',
        conversationId: convSailId,
        sender: leo,
        createdAt: twoDaysAgoBase.add(const Duration(hours: 11)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Wind looks steady at 14 knots Saturday morning. Harbor gate opens at 7 AM.',
      ),
    ];

    // Conversation 7: Leo Martinez (direct)
    const convLeoId = 'conv_me_user_leo';
    final leoMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_leo_1',
        localId: 'local_leo_1',
        conversationId: convLeoId,
        sender: currentUser,
        createdAt: twoDaysAgoBase.add(const Duration(hours: 9, minutes: 5)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.none,
        text: 'Sent you the marina parking pass!',
      ),
    ];

    // Compact messages for the Core MessageListView preview in
    // BlueExtensionsScreen so the default Row renderer fits narrow viewports.
    const convShowcaseId = 'conv_showcase_preview';
    final showcaseMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_show_1',
        localId: 'local_show_1',
        conversationId: convShowcaseId,
        sender: maya,
        createdAt: todayBase.subtract(const Duration(minutes: 6)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Floating islands ready!',
      ),
      TextMessage(
        id: 'm_show_2',
        localId: 'local_show_2',
        conversationId: convShowcaseId,
        sender: currentUser,
        createdAt: todayBase.subtract(const Duration(minutes: 2)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Pure Dart Core 💙',
      ),
    ];

    _messagesByConversation = {
      convMayaId: mayaMsgs,
      convDesignId: designMsgs,
      convFlutterId: flutterMsgs,
      convDanielId: danielMsgs,
      convSaraId: saraMsgs,
      convSailId: sailMsgs,
      convLeoId: leoMsgs,
      convShowcaseId: showcaseMsgs,
    };

    // Seed pinned messages
    _pinnedByConversation[convMayaId] = [mayaMsg1, mayaFile];
    _pinnedByConversation[convDesignId] = [designMsg1];
    _pinnedByConversation[convFlutterId] = [flutterMsg1];

    // Seed saved / bookmarked messages
    _savedMessages.addAll([mayaMsg1, mayaMsg2, flutterMsg1, designMsg1]);

    // Seed reactions for messages
    _reactionsByMessageId[mayaMsg1.localId] = [
      {'reaction': '💙', 'count': 3, 'reactedByMe': true},
      {'reaction': '🔥', 'count': 2, 'reactedByMe': false},
    ];
    _reactionsByMessageId[designMsg1.localId] = [
      {'reaction': '👍', 'count': 4, 'reactedByMe': true},
      {'reaction': '✨', 'count': 2, 'reactedByMe': false},
    ];
    _reactionsByMessageId[flutterMsg1.localId] = [
      {'reaction': '🎉', 'count': 5, 'reactedByMe': true},
    ];

    _conversationsList = [
      ChatConversation.direct(
        id: convMayaId,
        peer: maya,
        lastMessage: mayaMsgs.last,
        unreadCount: 2,
        updatedAt: mayaMsgs.last.createdAt,
      ),
      ChatConversation.group(
        id: convDesignId,
        group: designGroup,
        lastMessage: designMsgs.last,
        unreadCount: 3,
        updatedAt: designMsgs.last.createdAt,
      ),
      ChatConversation.group(
        id: convFlutterId,
        group: flutterGroup,
        lastMessage: flutterMsgs.last,
        unreadCount: 0,
        updatedAt: flutterMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convDanielId,
        peer: daniel,
        lastMessage: danielMsgs.last,
        unreadCount: 0,
        updatedAt: danielMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convSaraId,
        peer: sara,
        lastMessage: saraMsgs.last,
        unreadCount: 1,
        updatedAt: saraMsgs.last.createdAt,
      ),
      ChatConversation.group(
        id: convSailId,
        group: sailGroup,
        lastMessage: sailMsgs.last,
        unreadCount: 0,
        updatedAt: sailMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convLeoId,
        peer: leo,
        lastMessage: leoMsgs.last,
        unreadCount: 0,
        updatedAt: leoMsgs.last.createdAt,
      ),
    ];

    statusUpdates = [
      BlueStatusUpdate(
        user: maya,
        caption: 'Exploring cobalt glass & floating pill layouts today',
        postedAt: todayBase.subtract(const Duration(minutes: 14)),
        unseenCount: 2,
      ),
      BlueStatusUpdate(
        user: daniel,
        caption: 'Zero SDK imports verified across the entire ConvoKit repo',
        postedAt: todayBase.subtract(const Duration(hours: 1, minutes: 20)),
        unseenCount: 1,
      ),
      BlueStatusUpdate(
        user: sara,
        caption: 'Coffee by the marina before the sprint review',
        postedAt: todayBase.subtract(const Duration(hours: 3)),
        unseenCount: 0,
      ),
      BlueStatusUpdate(
        user: leo,
        caption: 'Checking wind charts for Saturday sail club',
        postedAt: yesterdayBase.add(const Duration(hours: 8)),
        unseenCount: 0,
      ),
    ];

    callRecords = [
      BlueCallRecord(
        peer: maya,
        timestamp: todayBase.subtract(const Duration(minutes: 45)),
        isVideo: true,
        isMissed: false,
        isOutgoing: true,
        durationLabel: '12m 18s',
      ),
      BlueCallRecord(
        peer: daniel,
        timestamp: todayBase.subtract(const Duration(hours: 2, minutes: 10)),
        isVideo: false,
        isMissed: true,
        isOutgoing: false,
        durationLabel: 'Missed voice call',
      ),
      BlueCallRecord(
        peer: sara,
        timestamp: yesterdayBase.add(const Duration(hours: 6, minutes: 30)),
        isVideo: false,
        isMissed: false,
        isOutgoing: false,
        durationLabel: '6m 04s',
      ),
      BlueCallRecord(
        peer: hana,
        timestamp: yesterdayBase.add(const Duration(hours: 2)),
        isVideo: true,
        isMissed: false,
        isOutgoing: true,
        durationLabel: '19m 42s',
      ),
    ];
  }

  void _updateConversationLastMessage(ChatMessage confirmed) {
    final idx = _conversationsList.indexWhere(
      (c) => c.id == confirmed.conversationId,
    );
    if (idx == -1) return;
    final old = _conversationsList[idx];
    final updated = old.peer != null
        ? ChatConversation.direct(
            id: old.id,
            peer: old.peer!,
            lastMessage: confirmed,
            unreadCount: 0,
            updatedAt: confirmed.createdAt,
          )
        : ChatConversation.group(
            id: old.id,
            group: old.group!,
            lastMessage: confirmed,
            unreadCount: 0,
            updatedAt: confirmed.createdAt,
          );
    _conversationsList.removeAt(idx);
    _conversationsList.insert(0, updated);
    _events.emitEvent(
      ConversationUpdated(
        conversation: updated,
        receivedAt: DateTime.now(),
      ),
    );
  }
}

class _BlueInMemorySession implements ChatSession {
  final ChatUser? _current;
  StreamController<ChatUser?> _controller =
      StreamController<ChatUser?>.broadcast();

  _BlueInMemorySession(ChatUser initialUser) : _current = initialUser;

  @override
  ChatUser? get currentUser => _current;

  @override
  Stream<ChatUser?> get currentUserStream {
    if (_controller.isClosed) {
      _controller = StreamController<ChatUser?>.broadcast();
    }
    return _controller.stream;
  }
}

class _BlueInMemoryUserRepository implements UserRepository {
  final BlueInMemoryBackend _backend;
  _BlueInMemoryUserRepository(this._backend);

  @override
  Future<ChatResult<ChatUser>> getUser(String id) async {
    for (final user in _backend._allUsers) {
      if (user.id == id) return ChatResult.success(user);
    }
    return ChatResult.failure(
      ChatError(ChatErrorCode.notFound, 'User $id not found'),
    );
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async {
    final peers = _backend._allUsers
        .where((u) => u.id != _backend.currentUser.id)
        .toList();
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = peers.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor = nextIndex < peers.length ? nextIndex.toString() : null;
    return ChatResult.success(
      ChatPage<ChatUser>(items: items, olderCursor: olderCursor),
    );
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  }) async {
    final lower = query.toLowerCase();
    final matched = _backend._allUsers
        .where(
          (u) =>
              u.id != _backend.currentUser.id &&
              (u.name.toLowerCase().contains(lower) ||
                  u.id.toLowerCase().contains(lower)),
        )
        .toList();
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = matched.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < matched.length ? nextIndex.toString() : null;
    return ChatResult.success(
      ChatPage<ChatUser>(items: items, olderCursor: olderCursor),
    );
  }
}

class _BlueInMemoryConversationRepository implements ConversationRepository {
  final BlueInMemoryBackend _backend;
  _BlueInMemoryConversationRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items =
        _backend._conversationsList.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor = nextIndex < _backend._conversationsList.length
        ? nextIndex.toString()
        : null;
    return ChatResult.success(
      ChatPage<ChatConversation>(items: items, olderCursor: olderCursor),
    );
  }

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async {
    for (final conv in _backend._conversationsList) {
      if (conv.id == id) return ChatResult.success(conv);
    }
    return ChatResult.failure(
      ChatError(ChatErrorCode.notFound, 'Conversation $id not found'),
    );
  }

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async {
    final index = _backend._conversationsList
        .indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _backend._conversationsList[index];
      final updated = old.peer != null
          ? ChatConversation.direct(
              id: old.id,
              peer: old.peer!,
              lastMessage: old.lastMessage,
              unreadCount: 0,
              updatedAt: old.updatedAt,
            )
          : ChatConversation.group(
              id: old.id,
              group: old.group!,
              lastMessage: old.lastMessage,
              unreadCount: 0,
              updatedAt: old.updatedAt,
            );
      _backend._conversationsList[index] = updated;
      _backend._events.emitEvent(
        ConversationUpdated(
          conversation: updated,
          receivedAt: DateTime.now(),
        ),
      );
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> deleteConversation(String conversationId) async {
    _backend._conversationsList.removeWhere((c) => c.id == conversationId);
    return ChatResult.ok();
  }
}

class _BlueInMemoryMessageRepository implements MessageRepository {
  final BlueInMemoryBackend _backend;
  _BlueInMemoryMessageRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async {
    final list = _backend._messagesByConversation.putIfAbsent(
      conversationId,
      () => [],
    );

    if (request.direction == MessagePageDirection.older) {
      var endIndex = list.length;
      if (request.cursor != null) {
        final cursorIdx = list.indexWhere((m) => m.id == request.cursor);
        if (cursorIdx != -1) endIndex = cursorIdx;
      }
      final startIndex = (endIndex - request.limit).clamp(0, endIndex);
      final items = list.sublist(startIndex, endIndex);
      final olderCursor = startIndex > 0 ? items.first.id : null;
      return ChatResult.success(
        ChatPage<ChatMessage>(items: items, olderCursor: olderCursor),
      );
    } else if (request.direction == MessagePageDirection.latest) {
      final startIndex = (list.length - request.limit).clamp(0, list.length);
      final items = list.sublist(startIndex, list.length);
      final olderCursor = startIndex > 0 ? items.first.id : null;
      final newerCheckpoint = items.isNotEmpty ? items.last.id : null;
      return ChatResult.success(
        ChatPage<ChatMessage>(
          items: items,
          olderCursor: olderCursor,
          newerCheckpoint: newerCheckpoint,
        ),
      );
    } else {
      var startIndex = 0;
      if (request.cursor != null) {
        final cursorIdx = list.indexWhere((m) => m.id == request.cursor);
        if (cursorIdx != -1) startIndex = cursorIdx + 1;
      }
      final endIndex =
          (startIndex + request.limit).clamp(startIndex, list.length);
      final items = list.sublist(startIndex, endIndex);
      final newerCursor = endIndex < list.length ? items.last.id : null;
      final newerCheckpoint = items.isNotEmpty ? items.last.id : null;
      return ChatResult.success(
        ChatPage<ChatMessage>(
          items: items,
          newerCursor: newerCursor,
          newerCheckpoint: newerCheckpoint,
        ),
      );
    }
  }

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) async {
    final list = _backend._messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    final existingIdx = list.indexWhere((m) => m.localId == message.localId);
    if (existingIdx != -1) {
      return ChatResult.success(list[existingIdx]);
    }

    final now = DateTime.now();
    final serverId = 'srv_${now.microsecondsSinceEpoch}';
    final confirmed = switch (message) {
      TextMessage t => TextMessage(
          id: serverId,
          localId: t.localId,
          conversationId: t.conversationId,
          sender: t.sender,
          createdAt: t.createdAt,
          serverCreatedAt: now,
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
          repliedTo: t.repliedTo,
          text: t.text,
        ),
      MediaMessage m => MediaMessage(
          id: serverId,
          localId: m.localId,
          conversationId: m.conversationId,
          sender: m.sender,
          createdAt: m.createdAt,
          serverCreatedAt: now,
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
          repliedTo: m.repliedTo,
          attachment: m.attachment,
          caption: m.caption,
          metadata: m.metadata,
        ),
      CustomMessage c => CustomMessage(
          id: serverId,
          localId: c.localId,
          conversationId: c.conversationId,
          sender: c.sender,
          createdAt: c.createdAt,
          serverCreatedAt: now,
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
          repliedTo: c.repliedTo,
          kind: c.kind,
          data: c.data,
        ),
    };

    list.add(confirmed);
    _backend._updateConversationLastMessage(confirmed);
    return ChatResult.success(confirmed);
  }

  @override
  Future<ChatResult<void>> deleteMessage(String messageId) async {
    for (final list in _backend._messagesByConversation.values) {
      list.removeWhere((m) => m.id == messageId || m.localId == messageId);
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> markAsDelivered(String messageId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> markAsRead(String messageId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> sendTyping(
    String conversationId,
    bool isTyping,
  ) async => ChatResult.ok();
}

class _BlueInMemoryGroupRepository implements GroupRepository {
  final BlueInMemoryBackend _backend;
  _BlueInMemoryGroupRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  }) async {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = _backend._groupsList.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < _backend._groupsList.length ? nextIndex.toString() : null;
    return ChatResult.success(
      ChatPage<ChatGroup>(items: items, olderCursor: olderCursor),
    );
  }

  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async {
    for (final grp in _backend._groupsList) {
      if (grp.id == id) return ChatResult.success(grp);
    }
    return ChatResult.failure(
      ChatError(ChatErrorCode.notFound, 'Group $id not found'),
    );
  }

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    final grpResult = await getGroup(groupId);
    return grpResult.fold(
      onSuccess: (grp) =>
          ChatResult.success(ChatPage<ChatMember>(items: grp.members ?? [])),
      onFailure: (err) => ChatResult.failure(err),
    );
  }

  @override
  Future<ChatResult<void>> joinGroup(String groupId) async => ChatResult.ok();

  @override
  Future<ChatResult<void>> leaveGroup(String groupId) async => ChatResult.ok();

  @override
  Future<ChatResult<void>> addMembers(
    String groupId,
    List<String> userIds,
  ) async => ChatResult.ok();

  @override
  Future<ChatResult<void>> removeMember(
    String groupId,
    String userId,
  ) async => ChatResult.ok();
}

class _BlueInMemoryMediaProvider implements ChatMediaProvider {
  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
      );
    }
    onProgress?.call(const UploadProgress(sentBytes: 100, totalBytes: 100));
    final mediaId = 'media_${DateTime.now().millisecondsSinceEpoch}';
    return ChatResult.success(
      UploadedMedia(
        id: mediaId,
        url: request.localPath != null
            ? 'file://${request.localPath}'
            : 'offline://$mediaId',
        mimeType: request.mimeType,
        name: request.name,
      ),
    );
  }

  @override
  Future<ChatResult<void>> delete(String mediaId) async => ChatResult.ok();
}

class _BlueInMemoryEventSource implements ChatEventSource {
  StreamController<ChatEvent> _eventController =
      StreamController<ChatEvent>.broadcast();
  StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  _BlueInMemoryEventSource() {
    _connectionController.add(
      const ConnectionStatus(ConnectionState.connected),
    );
  }

  @override
  Stream<ChatEvent> get events {
    if (_eventController.isClosed) {
      _eventController = StreamController<ChatEvent>.broadcast();
    }
    return _eventController.stream;
  }

  @override
  Stream<ConnectionStatus> get connectionState {
    if (_connectionController.isClosed) {
      _connectionController = StreamController<ConnectionStatus>.broadcast();
    }
    return _connectionController.stream;
  }

  @override
  Future<ChatResult<void>> connect() async {
    if (_connectionController.isClosed) {
      _connectionController = StreamController<ConnectionStatus>.broadcast();
    }
    _connectionController.add(
      const ConnectionStatus(ConnectionState.connected),
    );
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> disconnect() async {
    if (!_connectionController.isClosed) {
      _connectionController.add(
        const ConnectionStatus(ConnectionState.disconnected),
      );
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> reconnect() async {
    await disconnect();
    return connect();
  }

  void emitEvent(ChatEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
}
