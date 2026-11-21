import 'dart:async';

import 'package:convokit/convokit.dart';

/// Offline in-memory ConvoKit backend seeded with WhatsApp-style contacts,
/// conversations, unread counts, online presence, and multi-day message history.
class WhatsAppInMemoryBackend {
  late final ChatUser currentUser;
  late final ChatUser amina;
  late final ChatUser omar;
  late final ChatUser lina;
  late final ChatUser tariq;
  late final ChatUser nadia;
  late final ChatUser karim;

  late final ChatGroup hikeGroup;

  late final List<ChatUser> _allUsers;
  late final List<ChatConversation> _conversationsList;
  late final Map<String, List<ChatMessage>> _messagesByConversation;
  late final List<ChatGroup> _groupsList;

  late final _InMemorySession _session;
  late final _InMemoryUserRepository _users;
  late final _InMemoryConversationRepository _conversations;
  late final _InMemoryMessageRepository _messages;
  late final _InMemoryGroupRepository _groups;
  late final _InMemoryMediaProvider _media;
  late final _InMemoryEventSource _events;

  ChatSession get session => _session;
  UserRepository get users => _users;
  ConversationRepository get conversations => _conversations;
  MessageRepository get messages => _messages;
  GroupRepository get groups => _groups;
  ChatMediaProvider get media => _media;
  ChatEventSource get events => _events;

  WhatsAppInMemoryBackend() {
    _initData();
    _session = _InMemorySession(currentUser);
    _users = _InMemoryUserRepository(this);
    _conversations = _InMemoryConversationRepository(this);
    _messages = _InMemoryMessageRepository(this);
    _groups = _InMemoryGroupRepository(this);
    _media = _InMemoryMediaProvider();
    _events = _InMemoryEventSource();
  }

  /// Creates a [ConvoKit] composition root wired to this offline backend.
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

  /// Looks up a seeded conversation by direct peer or group ID.
  ChatConversation? getConversationFor({String? userId, String? groupId}) {
    for (final conv in _conversationsList) {
      if (userId != null && conv.peer?.id == userId) return conv;
      if (groupId != null && conv.group?.id == groupId) return conv;
    }
    return null;
  }

  void _initData() {
    currentUser = const ChatUser(
      id: 'me',
      name: 'You',
      presence: UserPresence.online,
    );
    amina = const ChatUser(
      id: 'user_amina',
      name: 'Amina Hassan',
      presence: UserPresence.online,
    );
    omar = const ChatUser(
      id: 'user_omar',
      name: 'Omar Al-Mansoor',
      presence: UserPresence.online,
    );
    lina = const ChatUser(
      id: 'user_lina',
      name: 'Lina Haddad',
      presence: UserPresence.away,
    );
    tariq = const ChatUser(
      id: 'user_tariq',
      name: 'Tariq Saleh',
      presence: UserPresence.offline,
    );
    nadia = const ChatUser(
      id: 'user_nadia',
      name: 'Nadia Farouk',
      presence: UserPresence.online,
    );
    karim = const ChatUser(
      id: 'user_karim',
      name: 'Karim Nassar',
      presence: UserPresence.offline,
    );

    _allUsers = [currentUser, amina, omar, lina, tariq, nadia, karim];

    hikeGroup = ChatGroup(
      id: 'group_hike',
      name: 'Weekend Hike Crew',
      description: 'Trail plans, carpool & coffee stops',
      type: GroupType.public,
      memberCount: 4,
      members: [
        ChatMember(user: currentUser, role: GroupRole.owner),
        ChatMember(user: amina, role: GroupRole.admin),
        ChatMember(user: omar, role: GroupRole.member),
        ChatMember(user: lina, role: GroupRole.member),
      ],
    );
    _groupsList = [hikeGroup];

    final now = DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day, 10, 0);
    final yesterdayBase = todayBase.subtract(const Duration(days: 1));
    final twoDaysAgoBase = todayBase.subtract(const Duration(days: 2));

    // Conversation 1: Amina Hassan (online, 2 unread, multi-day history)
    const convAminaId = 'conv_me_user_amina';
    final aminaMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_amina_1',
        localId: 'local_amina_1',
        conversationId: convAminaId,
        sender: amina,
        createdAt: yesterdayBase.add(const Duration(hours: 6, minutes: 15)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Hey! Are we still on for coffee tomorrow morning?',
      ),
      TextMessage(
        id: 'm_amina_2',
        localId: 'local_amina_2',
        conversationId: convAminaId,
        sender: currentUser,
        createdAt: yesterdayBase.add(const Duration(hours: 6, minutes: 22)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Definitely! Let us meet at the usual spot around 9:30.',
      ),
      TextMessage(
        id: 'm_amina_3',
        localId: 'local_amina_3',
        conversationId: convAminaId,
        sender: currentUser,
        createdAt: todayBase.subtract(const Duration(minutes: 25)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'Just grabbed a table by the window.',
      ),
      TextMessage(
        id: 'm_amina_4',
        localId: 'local_amina_4',
        conversationId: convAminaId,
        sender: amina,
        createdAt: todayBase.subtract(const Duration(minutes: 4)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'On my way! Be there in 5 minutes.',
      ),
    ];

    // Conversation 2: Weekend Hike Crew (group, 3 unread)
    const convGroupId = 'conv_group_hike';
    final groupMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_grp_1',
        localId: 'local_grp_1',
        conversationId: convGroupId,
        sender: omar,
        createdAt: twoDaysAgoBase.add(const Duration(hours: 8)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Who is driving up to the ridge trail on Saturday?',
      ),
      TextMessage(
        id: 'm_grp_2',
        localId: 'local_grp_2',
        conversationId: convGroupId,
        sender: currentUser,
        createdAt: yesterdayBase.add(const Duration(hours: 2, minutes: 10)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'I can take 3 people in my car. Leaving at 6:30 AM.',
      ),
      TextMessage(
        id: 'm_grp_3',
        localId: 'local_grp_3',
        conversationId: convGroupId,
        sender: lina,
        createdAt: todayBase.subtract(const Duration(minutes: 18)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'Count me in! Bringing thermos coffee and dates.',
      ),
    ];

    // Conversation 3: Omar Al-Mansoor (online, 0 unread, last message from me)
    const convOmarId = 'conv_me_user_omar';
    final omarMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_omar_1',
        localId: 'local_omar_1',
        conversationId: convOmarId,
        sender: omar,
        createdAt: yesterdayBase.add(const Duration(hours: 4, minutes: 5)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Did you get a chance to review the Flutter build?',
      ),
      TextMessage(
        id: 'm_omar_2',
        localId: 'local_omar_2',
        conversationId: convOmarId,
        sender: currentUser,
        createdAt: todayBase.subtract(const Duration(minutes: 42)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Yes, looks super clean. Ready to ship!',
      ),
    ];

    // Conversation 4: Lina Haddad (away, 1 unread)
    const convLinaId = 'conv_me_user_lina';
    final linaMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_lina_1',
        localId: 'local_lina_1',
        conversationId: convLinaId,
        sender: lina,
        createdAt: yesterdayBase.add(const Duration(hours: 9, minutes: 30)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'Sent you the updated design notes for the home screen.',
      ),
    ];

    // Conversation 5: Nadia Farouk (online, 0 unread)
    const convNadiaId = 'conv_me_user_nadia';
    final nadiaMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_nadia_1',
        localId: 'local_nadia_1',
        conversationId: convNadiaId,
        sender: currentUser,
        createdAt: yesterdayBase.add(const Duration(hours: 3, minutes: 45)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        text: 'Thanks again for helping with the presentation deck!',
      ),
      TextMessage(
        id: 'm_nadia_2',
        localId: 'local_nadia_2',
        conversationId: convNadiaId,
        sender: nadia,
        createdAt: yesterdayBase.add(const Duration(hours: 4, minutes: 12)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Anytime! Good luck with the demo today.',
      ),
    ];

    // Conversation 6: Tariq Saleh (offline, 0 unread)
    const convTariqId = 'conv_me_user_tariq';
    final tariqMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_tariq_1',
        localId: 'local_tariq_1',
        conversationId: convTariqId,
        sender: tariq,
        createdAt: twoDaysAgoBase.add(const Duration(hours: 5, minutes: 20)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Catch up next week when I am back in town.',
      ),
    ];

    // Conversation 7: Karim Nassar (offline, 0 unread)
    const convKarimId = 'conv_me_user_karim';
    final karimMsgs = <ChatMessage>[
      TextMessage(
        id: 'm_karim_1',
        localId: 'local_karim_1',
        conversationId: convKarimId,
        sender: currentUser,
        createdAt: twoDaysAgoBase.add(const Duration(hours: 1, minutes: 10)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.none,
        text: 'Let me know when you land safely.',
      ),
    ];

    _messagesByConversation = {
      convAminaId: aminaMsgs,
      convGroupId: groupMsgs,
      convOmarId: omarMsgs,
      convLinaId: linaMsgs,
      convNadiaId: nadiaMsgs,
      convTariqId: tariqMsgs,
      convKarimId: karimMsgs,
    };

    _conversationsList = [
      ChatConversation.direct(
        id: convAminaId,
        peer: amina,
        lastMessage: aminaMsgs.last,
        unreadCount: 2,
        updatedAt: aminaMsgs.last.createdAt,
      ),
      ChatConversation.group(
        id: convGroupId,
        group: hikeGroup,
        lastMessage: groupMsgs.last,
        unreadCount: 3,
        updatedAt: groupMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convOmarId,
        peer: omar,
        lastMessage: omarMsgs.last,
        unreadCount: 0,
        updatedAt: omarMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convLinaId,
        peer: lina,
        lastMessage: linaMsgs.last,
        unreadCount: 1,
        updatedAt: linaMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convNadiaId,
        peer: nadia,
        lastMessage: nadiaMsgs.last,
        unreadCount: 0,
        updatedAt: nadiaMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convTariqId,
        peer: tariq,
        lastMessage: tariqMsgs.last,
        unreadCount: 0,
        updatedAt: tariqMsgs.last.createdAt,
      ),
      ChatConversation.direct(
        id: convKarimId,
        peer: karim,
        lastMessage: karimMsgs.last,
        unreadCount: 0,
        updatedAt: karimMsgs.last.createdAt,
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

class _InMemorySession implements ChatSession {
  final ChatUser? _current;
  StreamController<ChatUser?> _controller =
      StreamController<ChatUser?>.broadcast();

  _InMemorySession(ChatUser initialUser) : _current = initialUser;

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

class _InMemoryUserRepository implements UserRepository {
  final WhatsAppInMemoryBackend _backend;
  _InMemoryUserRepository(this._backend);

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

class _InMemoryConversationRepository implements ConversationRepository {
  final WhatsAppInMemoryBackend _backend;
  _InMemoryConversationRepository(this._backend);

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

class _InMemoryMessageRepository implements MessageRepository {
  final WhatsAppInMemoryBackend _backend;
  _InMemoryMessageRepository(this._backend);

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
          deliveryState: DeliveryState.delivered,
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
          deliveryState: DeliveryState.delivered,
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
          deliveryState: DeliveryState.delivered,
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

class _InMemoryGroupRepository implements GroupRepository {
  final WhatsAppInMemoryBackend _backend;
  _InMemoryGroupRepository(this._backend);

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

class _InMemoryMediaProvider implements ChatMediaProvider {
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

class _InMemoryEventSource implements ChatEventSource {
  StreamController<ChatEvent> _eventController =
      StreamController<ChatEvent>.broadcast();
  StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  _InMemoryEventSource() {
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
