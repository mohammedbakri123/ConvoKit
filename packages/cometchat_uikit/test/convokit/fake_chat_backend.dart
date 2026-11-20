// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:cometchat_chat_uikit/convokit.dart';

extension ChatResultTestX<T> on ChatResult<T> {
  T getOrThrow() {
    if (this is ChatSuccess<T>) {
      return (this as ChatSuccess<T>).value;
    }
    throw StateError('Expected ChatSuccess, but got ${(this as ChatFailure<T>).error}');
  }

  ChatError? get errorOrNull =>
      this is ChatFailure<T> ? (this as ChatFailure<T>).error : null;
}

/// Test fake chat backend implementing ConvoKit contracts for unit & widget tests.
///
/// Features:
/// - Fully offline, in-memory data store
/// - Seeded users, groups, conversations, and messages
/// - Configurable failure injection for media upload and message send
/// - Call recording to assert whether upload vs send was invoked
class FakeChatBackend {
  late final ChatUser user1;
  late final ChatUser user2;
  late final ChatUser user3;
  late final ChatUser user4;

  late final List<ChatUser> allUsers;
  late final List<ChatConversation> conversationsList;
  late final Map<String, List<ChatMessage>> messagesByConversation;
  late final List<ChatGroup> groupsList;

  late final _FakeSession _session;
  late final _FakeUserRepository _users;
  late final _FakeConversationRepository _conversations;
  late final _FakeMessageRepository _messages;
  late final _FakeGroupRepository _groups;
  late final _FakeMediaProvider _media;
  late final _FakeEventSource _events;

  ChatSession get session => _session;
  UserRepository get users => _users;
  ConversationRepository get conversations => _conversations;
  MessageRepository get messages => _messages;
  GroupRepository get groups => _groups;
  ChatMediaProvider get media => _media;
  ChatEventSource get events => _events;

  // Failure simulation hooks
  bool failNextUpload = false;
  bool failNextSend = false;
  bool returnOutcomeUnknownNextSend = false;
  bool nullCheckpoint = false;
  Duration connectDelay = Duration.zero;
  Duration disconnectDelay = Duration.zero;

  // Call counters for verifying retry and lifecycle behavior
  int uploadCallCount = 0;
  int sendCallCount = 0;
  int connectCount = 0;
  int disconnectCount = 0;
  int reconnectCount = 0;

  FakeChatBackend({int seededMessageCount = 105}) {
    _initData(seededMessageCount);
    _session = _FakeSession(user1);
    _users = _FakeUserRepository(this);
    _conversations = _FakeConversationRepository(this);
    _messages = _FakeMessageRepository(this);
    _groups = _FakeGroupRepository(this);
    _media = _FakeMediaProvider(this);
    _events = _FakeEventSource(this);
  }

  void updateUser(ChatUser? user) => _session.updateUser(user);

  void emitEvent(ChatEvent event) => _events.emitEvent(event);

  void injectMessage(ChatMessage message) {
    final list = messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    list.add(message);

    final convIdx =
        conversationsList.indexWhere((c) => c.id == message.conversationId);
    if (convIdx != -1) {
      final old = conversationsList[convIdx];
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
      conversationsList[convIdx] = updated;
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
    final list = messagesByConversation[conversationId];
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
    final idx = allUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      allUsers[idx] = ChatUser(
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
    final list = messagesByConversation[conversationId];
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

  void _initData(int seededMessageCount) {
    user1 = const ChatUser(
      id: 'user_1',
      name: 'Alice',
      avatarUrl: 'https://example.com/alice.png',
      presence: UserPresence.online,
    );
    user2 = const ChatUser(
      id: 'user_2',
      name: 'Bob',
      avatarUrl: 'https://example.com/bob.png',
      presence: UserPresence.online,
    );
    user3 = const ChatUser(
      id: 'user_3',
      name: 'Charlie',
      avatarUrl: 'https://example.com/charlie.png',
      presence: UserPresence.away,
    );
    user4 = const ChatUser(
      id: 'user_4',
      name: 'David',
      avatarUrl: 'https://example.com/david.png',
      presence: UserPresence.offline,
    );

    allUsers = [user1, user2, user3, user4];

    final now = DateTime.now();

    final baseMsg = TextMessage(
      id: 'msg_initial',
      localId: 'local_initial',
      conversationId: 'conv_1_2',
      sender: user2,
      createdAt: now.subtract(const Duration(hours: 2)),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Hello from Bob',
    );

    // Create seeded messages for pagination testing (e.g. 105 messages)
    final msgList = <ChatMessage>[];
    for (int i = 0; i < seededMessageCount; i++) {
      msgList.add(
        TextMessage(
          id: 'msg_$i',
          localId: 'local_msg_$i',
          conversationId: 'conv_1_2',
          sender: i.isEven ? user1 : user2,
          createdAt: now.subtract(Duration(minutes: seededMessageCount - i)),
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
          text: 'Message #$i',
        ),
      );
    }

    messagesByConversation = {
      'conv_1_2': msgList.isNotEmpty ? msgList : [baseMsg],
      'conv_1_3': [
        TextMessage(
          id: 'msg_c1',
          localId: 'local_c1',
          conversationId: 'conv_1_3',
          sender: user3,
          createdAt: now.subtract(const Duration(minutes: 10)),
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
          text: 'Hey Alice, Charlie here',
        ),
      ],
    };

    conversationsList = [
      ChatConversation.direct(
        id: 'conv_1_2',
        peer: user2,
        lastMessage: messagesByConversation['conv_1_2']!.last,
        unreadCount: 2,
        updatedAt: now.subtract(const Duration(minutes: 1)),
      ),
      ChatConversation.direct(
        id: 'conv_1_3',
        peer: user3,
        lastMessage: messagesByConversation['conv_1_3']!.last,
        unreadCount: 0,
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];

    groupsList = [
      ChatGroup(
        id: 'group_team',
        name: 'Core Team',
        avatarUrl: 'https://example.com/team.png',
        description: 'Team Discussion',
        type: GroupType.public,
        memberCount: 3,
        members: [
          ChatMember(user: user1, role: GroupRole.admin),
          ChatMember(user: user2, role: GroupRole.member),
          ChatMember(user: user3, role: GroupRole.member),
        ],
      ),
    ];
  }
}

class _FakeSession implements ChatSession {
  ChatUser? _current;
  StreamController<ChatUser?> _controller =
      StreamController<ChatUser?>.broadcast();

  _FakeSession(ChatUser initialUser) : _current = initialUser;

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

class _FakeUserRepository implements UserRepository {
  final FakeChatBackend _backend;
  _FakeUserRepository(this._backend);

  @override
  Future<ChatResult<ChatUser>> getUser(String id) async {
    try {
      final user = _backend.allUsers.firstWhere((u) => u.id == id);
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
    final items = _backend.allUsers.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < _backend.allUsers.length ? nextIndex.toString() : null;

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
    final matched = _backend.allUsers
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

class _FakeConversationRepository implements ConversationRepository {
  final FakeChatBackend _backend;
  _FakeConversationRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items =
        _backend.conversationsList.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor = nextIndex < _backend.conversationsList.length
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
      final conv = _backend.conversationsList.firstWhere((c) => c.id == id);
      return ChatResult.success(conv);
    } catch (_) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Conversation $id not found'),
      );
    }
  }

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async {
    final index = _backend.conversationsList
        .indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _backend.conversationsList[index];
      if (old.peer != null) {
        _backend.conversationsList[index] = ChatConversation.direct(
          id: old.id,
          peer: old.peer!,
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
    _backend.conversationsList.removeWhere((c) => c.id == conversationId);
    return ChatResult.ok();
  }
}

class _FakeMessageRepository implements MessageRepository {
  final FakeChatBackend _backend;
  _FakeMessageRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async {
    final list = _backend.messagesByConversation.putIfAbsent(
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
    _backend.sendCallCount++;
    if (_backend.failNextSend) {
      _backend.failNextSend = false;
      return ChatResult.failure(
        const ChatError(ChatErrorCode.sendFailed, 'Injected send failure'),
      );
    }

    final list = _backend.messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );

    // Idempotency: duplicate localId returns already persisted message
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
    for (final list in _backend.messagesByConversation.values) {
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
  ) async =>
      ChatResult.ok();
}

class _FakeGroupRepository implements GroupRepository {
  final FakeChatBackend _backend;
  _FakeGroupRepository(this._backend);

  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  }) async {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final items = _backend.groupsList.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + items.length;
    final olderCursor =
        nextIndex < _backend.groupsList.length ? nextIndex.toString() : null;

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
      final grp = _backend.groupsList.firstWhere((g) => g.id == id);
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
  ) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> removeMember(
    String groupId,
    String userId,
  ) async =>
      ChatResult.ok();
}

class _FakeMediaProvider implements ChatMediaProvider {
  final FakeChatBackend _backend;
  _FakeMediaProvider(this._backend);

  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    _backend.uploadCallCount++;
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

class _FakeEventSource implements ChatEventSource {
  final FakeChatBackend _backend;
  StreamController<ChatEvent> _eventController =
      StreamController<ChatEvent>.broadcast();
  StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  _FakeEventSource(this._backend) {
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
    _backend.connectCount++;
    if (_backend.connectDelay > Duration.zero) {
      await Future<void>.delayed(_backend.connectDelay);
    }
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
    _backend.disconnectCount++;
    if (_backend.disconnectDelay > Duration.zero) {
      await Future<void>.delayed(_backend.disconnectDelay);
    }
    if (!_connectionController.isClosed) {
      _connectionController.add(
        const ConnectionStatus(ConnectionState.disconnected),
      );
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> reconnect() async {
    _backend.reconnectCount++;
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
