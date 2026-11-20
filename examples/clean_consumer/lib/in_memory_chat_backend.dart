import 'dart:async';

import 'package:convokit/convokit.dart';

/// In-memory chat backend implementing Phase 1 ConvoKit contracts.
///
/// Fully offline, seeded with superhero demo data from sample_data.json.
class InMemoryChatBackend {
  late final ChatUser superhero1;
  late final ChatUser superhero2;
  late final ChatUser superhero3;
  late final ChatUser superhero4;
  late final ChatUser superhero5;

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

  // Failure simulation hooks for testing
  bool failNextUpload = false;
  bool failNextSend = false;
  bool returnOutcomeUnknownNextSend = false;
  bool nullCheckpoint = false;

  InMemoryChatBackend() {
    _initData();
    _session = _InMemorySession(superhero1);
    _users = _InMemoryUserRepository(this);
    _conversations = _InMemoryConversationRepository(this);
    _messages = _InMemoryMessageRepository(this);
    _groups = _InMemoryGroupRepository(this);
    _media = _InMemoryMediaProvider(this);
    _events = _InMemoryEventSource();
  }

  void updateUser(ChatUser? user) => _session.updateUser(user);

  void injectMessage(ChatMessage message) {
    final list = _messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    list.add(message);

    final convIdx =
        _conversationsList.indexWhere((c) => c.id == message.conversationId);
    if (convIdx != -1) {
      final old = _conversationsList[convIdx];
      final updated = old.peer != null
          ? ChatConversation.direct(
              id: old.id,
              peer: old.peer!,
              lastMessage: message,
              unreadCount: old.unreadCount + 1,
              updatedAt: message.createdAt,
            )
          : ChatConversation.group(
              id: old.id,
              group: old.group!,
              lastMessage: message,
              unreadCount: old.unreadCount + 1,
              updatedAt: message.createdAt,
            );
      _conversationsList[convIdx] = updated;
      _events.emitEvent(
        ConversationUpdated(
          conversation: updated,
          receivedAt: DateTime.now(),
        ),
      );
    }

    _events.emitEvent(
      MessageReceived(message: message, receivedAt: DateTime.now()),
    );
  }

  void injectStatusChange(
    String conversationId,
    String messageId,
    DeliveryState deliveryState,
  ) {
    final list = _messagesByConversation[conversationId];
    if (list != null) {
      final idx = list.indexWhere(
        (m) => m.id == messageId || m.localId == messageId,
      );
      if (idx != -1) {
        list[idx] = list[idx].copyWithDeliveryState(deliveryState);
      }
    }
    _events.emitEvent(
      MessageStatusChanged(
        conversationId: conversationId,
        messageId: messageId,
        deliveryState: deliveryState,
        receivedAt: DateTime.now(),
      ),
    );
  }

  void injectTyping(String conversationId, ChatUser user, bool isTyping) {
    _events.emitEvent(
      TypingChanged(
        conversationId: conversationId,
        user: user,
        isTyping: isTyping,
        receivedAt: DateTime.now(),
      ),
    );
  }

  void injectPresence(ChatUser user, UserPresence presence) {
    final idx = _allUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _allUsers[idx] = ChatUser(
        id: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
        presence: presence,
        isBlocked: user.isBlocked,
      );
    }
    _events.emitEvent(
      PresenceChanged(
        user: user,
        presence: presence,
        receivedAt: DateTime.now(),
      ),
    );
  }

  void injectMessageDeleted(String conversationId, String messageId) {
    final list = _messagesByConversation[conversationId];
    list?.removeWhere((m) => m.id == messageId || m.localId == messageId);
    _events.emitEvent(
      MessageDeleted(
        conversationId: conversationId,
        messageId: messageId,
        receivedAt: DateTime.now(),
      ),
    );
  }

  void simulateDisconnect({ChatError? error}) {
    _events._connectionController.add(
      ConnectionStatus(ConnectionState.disconnected, error: error),
    );
  }

  void simulateConnect() {
    _events._connectionController.add(
      const ConnectionStatus(ConnectionState.connected),
    );
  }

  void simulateEventsStreamError(Object error) {
    _events.emitError(error);
  }

  void simulateEventsStreamDone() {
    _events.closeEventsStream();
  }

  void simulateSessionStreamError(Object error) {
    _session.emitError(error);
  }

  void simulateSessionStreamDone() {
    _session.closeStream();
  }

  void _initData() {
    superhero1 = const ChatUser(
      id: 'superhero1',
      name: 'Iron Man',
      avatarUrl: 'assets/ironman_avatar.png',
      presence: UserPresence.online,
    );
    superhero2 = const ChatUser(
      id: 'superhero2',
      name: 'Captain America',
      avatarUrl: 'assets/captainamerica_avatar.png',
      presence: UserPresence.online,
    );
    superhero3 = const ChatUser(
      id: 'superhero3',
      name: 'Spiderman',
      avatarUrl: 'assets/spiderman_avatar.png',
      presence: UserPresence.away,
    );
    superhero4 = const ChatUser(
      id: 'superhero4',
      name: 'Wolverine',
      avatarUrl: 'assets/wolverine_avatar.png',
      presence: UserPresence.offline,
    );
    superhero5 = const ChatUser(
      id: 'superhero5',
      name: 'Cyclops',
      avatarUrl: 'assets/cyclops_avatar.png',
      presence: UserPresence.online,
    );

    _allUsers = [superhero1, superhero2, superhero3, superhero4, superhero5];

    final now = DateTime.now();

    final msg1 = TextMessage(
      id: 'msg_1',
      localId: 'local_msg_1',
      conversationId: 'conv_superhero1_superhero2',
      sender: superhero2,
      createdAt: now.subtract(const Duration(minutes: 5)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Suit up, Tony!',
    );

    final msg2 = TextMessage(
      id: 'msg_2',
      localId: 'local_msg_2',
      conversationId: 'conv_superhero1_superhero3',
      sender: superhero3,
      createdAt: now.subtract(const Duration(minutes: 15)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Mr. Stark, do you have any new upgrades?',
    );

    final msg3 = TextMessage(
      id: 'msg_3',
      localId: 'local_msg_3',
      conversationId: 'conv_superhero1_superhero4',
      sender: superhero4,
      createdAt: now.subtract(const Duration(hours: 1)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Where are we meeting?',
    );

    final msg4 = TextMessage(
      id: 'msg_4',
      localId: 'local_msg_4',
      conversationId: 'conv_superhero1_superhero5',
      sender: superhero5,
      createdAt: now.subtract(const Duration(days: 1)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'X-Men are ready when you are.',
    );

    _messagesByConversation = {
      'conv_superhero1_superhero2': [msg1],
      'conv_superhero1_superhero3': [msg2],
      'conv_superhero1_superhero4': [msg3],
      'conv_superhero1_superhero5': [msg4],
    };

    _conversationsList = [
      ChatConversation.direct(
        id: 'conv_superhero1_superhero2',
        peer: superhero2,
        lastMessage: msg1,
        unreadCount: 1,
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      ChatConversation.direct(
        id: 'conv_superhero1_superhero3',
        peer: superhero3,
        lastMessage: msg2,
        unreadCount: 0,
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
      ChatConversation.direct(
        id: 'conv_superhero1_superhero4',
        peer: superhero4,
        lastMessage: msg3,
        unreadCount: 1,
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      ChatConversation.direct(
        id: 'conv_superhero1_superhero5',
        peer: superhero5,
        lastMessage: msg4,
        unreadCount: 0,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _groupsList = [
      ChatGroup(
        id: 'group_avengers',
        name: 'Avengers HQ',
        avatarUrl: 'assets/captainamerica_avatar.png',
        description: 'Earth’s Mightiest Heroes',
        type: GroupType.public,
        memberCount: 3,
        members: [
          ChatMember(user: superhero1, role: GroupRole.admin),
          ChatMember(user: superhero2, role: GroupRole.owner),
          ChatMember(user: superhero3, role: GroupRole.member),
        ],
      ),
    ];
  }
}

class _InMemorySession implements ChatSession {
  ChatUser? _current;
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

  void updateUser(ChatUser? user) {
    _current = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  void emitError(Object error) {
    if (!_controller.isClosed) {
      _controller.addError(error);
    }
  }

  void closeStream() {
    _controller.close();
  }
}

class _InMemoryUserRepository implements UserRepository {
  final InMemoryChatBackend _backend;
  _InMemoryUserRepository(this._backend);

  @override
  Future<ChatResult<ChatUser>> getUser(String id) async {
    try {
      final user = _backend._allUsers.firstWhere((u) => u.id == id);
      return ChatResult.success(user);
    } catch (_) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'User $id not found'),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = _backend._allUsers.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < _backend._allUsers.length ? nextIndex.toString() : null;

    return ChatResult.success(
      ChatPage<ChatUser>(
        items: items,
        olderCursor: olderCursor,
      ),
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
              u.name.toLowerCase().contains(lower) ||
              u.id.toLowerCase().contains(lower),
        )
        .toList();
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = matched.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < matched.length ? nextIndex.toString() : null;

    return ChatResult.success(
      ChatPage<ChatUser>(
        items: items,
        olderCursor: olderCursor,
      ),
    );
  }
}

class _InMemoryConversationRepository implements ConversationRepository {
  final InMemoryChatBackend _backend;
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
      ChatPage<ChatConversation>(
        items: items,
        olderCursor: olderCursor,
      ),
    );
  }

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async {
    try {
      final conv = _backend._conversationsList.firstWhere((c) => c.id == id);
      return ChatResult.success(conv);
    } catch (_) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Conversation $id not found'),
      );
    }
  }

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async {
    final index = _backend._conversationsList
        .indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _backend._conversationsList[index];
      if (old.peer != null) {
        _backend._conversationsList[index] = ChatConversation.direct(
          id: old.id,
          peer: old.peer!,
          lastMessage: old.lastMessage,
          unreadCount: 0,
          updatedAt: old.updatedAt,
        );
      } else if (old.group != null) {
        _backend._conversationsList[index] = ChatConversation.group(
          id: old.id,
          group: old.group!,
          lastMessage: old.lastMessage,
          unreadCount: 0,
          updatedAt: old.updatedAt,
        );
      }
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
  final InMemoryChatBackend _backend;
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
      int endIndex = list.length;
      if (request.cursor != null) {
        final cursorIdx = list.indexWhere((m) => m.id == request.cursor);
        if (cursorIdx != -1) {
          endIndex = cursorIdx;
        }
      }
      final startIndex = (endIndex - request.limit).clamp(0, endIndex);
      final items = list.sublist(startIndex, endIndex);
      final olderCursor = startIndex > 0 ? items.first.id : null;

      return ChatResult.success(
        ChatPage<ChatMessage>(
          items: items,
          olderCursor: olderCursor,
        ),
      );
    } else if (request.direction == MessagePageDirection.latest) {
      final startIndex = (list.length - request.limit).clamp(0, list.length);
      final items = list.sublist(startIndex, list.length);
      final olderCursor = startIndex > 0 ? items.first.id : null;
      final newerCheckpoint = _backend.nullCheckpoint
          ? null
          : (items.isNotEmpty ? items.last.id : null);

      return ChatResult.success(
        ChatPage<ChatMessage>(
          items: items,
          olderCursor: olderCursor,
          newerCheckpoint: newerCheckpoint,
        ),
      );
    } else {
      int startIndex = 0;
      if (request.cursor != null) {
        final cursorIdx = list.indexWhere((m) => m.id == request.cursor);
        if (cursorIdx != -1) {
          startIndex = cursorIdx + 1;
        }
      }
      final endIndex =
          (startIndex + request.limit).clamp(startIndex, list.length);
      final items = list.sublist(startIndex, endIndex);
      final newerCursor = endIndex < list.length ? items.last.id : null;
      final newerCheckpoint = _backend.nullCheckpoint
          ? null
          : (items.isNotEmpty ? items.last.id : null);

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
    if (_backend.failNextSend) {
      _backend.failNextSend = false;
      return ChatResult.failure(
        const ChatError(ChatErrorCode.sendFailed, 'Injected send failure'),
      );
    }

    final list = _backend._messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    // Check if duplicate localId already exists
    final existingIdx = list.indexWhere((m) => m.localId == message.localId);
    if (existingIdx != -1) {
      return ChatResult.success(list[existingIdx]);
    }

    final confirmed = switch (message) {
      TextMessage t => TextMessage(
          id: 'server_${DateTime.now().microsecondsSinceEpoch}',
          localId: t.localId,
          conversationId: t.conversationId,
          sender: t.sender,
          createdAt: t.createdAt,
          serverCreatedAt: DateTime.now(),
          sendState: SendState.sent,
          deliveryState: DeliveryState.none,
          repliedTo: t.repliedTo,
          text: t.text,
        ),
      MediaMessage m => MediaMessage(
          id: 'server_${DateTime.now().microsecondsSinceEpoch}',
          localId: m.localId,
          conversationId: m.conversationId,
          sender: m.sender,
          createdAt: m.createdAt,
          serverCreatedAt: DateTime.now(),
          sendState: SendState.sent,
          deliveryState: DeliveryState.none,
          repliedTo: m.repliedTo,
          attachment: m.attachment,
          caption: m.caption,
        ),
      CustomMessage c => CustomMessage(
          id: 'server_${DateTime.now().microsecondsSinceEpoch}',
          localId: c.localId,
          conversationId: c.conversationId,
          sender: c.sender,
          createdAt: c.createdAt,
          serverCreatedAt: DateTime.now(),
          sendState: SendState.sent,
          deliveryState: DeliveryState.none,
          repliedTo: c.repliedTo,
          kind: c.kind,
          data: c.data,
        ),
    };

    list.add(confirmed);

    if (_backend.returnOutcomeUnknownNextSend) {
      _backend.returnOutcomeUnknownNextSend = false;
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unknown,
          'Lost response',
          outcomeUnknown: true,
        ),
      );
    }

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
  Future<ChatResult<void>> markAsDelivered(String messageId) async {
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> markAsRead(String messageId) async {
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> sendTyping(
    String conversationId,
    bool isTyping,
  ) async {
    return ChatResult.ok();
  }
}

class _InMemoryGroupRepository implements GroupRepository {
  final InMemoryChatBackend _backend;
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
      ChatPage<ChatGroup>(
        items: items,
        olderCursor: olderCursor,
      ),
    );
  }

  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async {
    try {
      final grp = _backend._groupsList.firstWhere((g) => g.id == id);
      return ChatResult.success(grp);
    } catch (_) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group $id not found'),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    final grpResult = await getGroup(groupId);
    return grpResult.fold(
      onSuccess: (grp) {
        final members = grp.members ?? [];
        return ChatResult.success(ChatPage<ChatMember>(items: members));
      },
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
  final InMemoryChatBackend _backend;
  _InMemoryMediaProvider(this._backend);

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

    if (_backend.failNextUpload) {
      _backend.failNextUpload = false;
      return const ChatResult.failure(
        ChatError(ChatErrorCode.uploadFailed, 'Injected upload failure'),
      );
    }

    onProgress?.call(UploadProgress(sentBytes: 50, totalBytes: 100));

    if (cancel?.isCancelled ?? false) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
      );
    }

    onProgress?.call(UploadProgress(sentBytes: 100, totalBytes: 100));

    final mediaId = 'media_${DateTime.now().millisecondsSinceEpoch}';
    final url = request.localPath != null
        ? 'file://${request.localPath}'
        : 'https://example.com/$mediaId';

    return ChatResult.success(
      UploadedMedia(
        id: mediaId,
        url: url,
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

  void emitError(Object error) {
    if (!_eventController.isClosed) {
      _eventController.addError(error);
    }
  }

  void closeEventsStream() {
    _eventController.close();
  }
}
