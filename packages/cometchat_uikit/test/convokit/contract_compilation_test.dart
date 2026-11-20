/// Consumer contract compilation test.
///
/// Imports ONLY the public ConvoKit barrel and verifies all public symbols,
/// interfaces, results, and widgets compile and behave correctly.
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:convokit/convokit.dart';

// Host implementation of ChatSession
class HostChatSession implements ChatSession {
  final ChatUser? _user;
  final _controller = StreamController<ChatUser?>.broadcast();

  HostChatSession(this._user);

  @override
  ChatUser? get currentUser => _user;

  @override
  Stream<ChatUser?> get currentUserStream => _controller.stream;
}

// Host implementation of UserRepository
class HostUserRepository implements UserRepository {
  @override
  Future<ChatResult<ChatUser>> getUser(String id) async =>
      ChatResult.success(ChatUser(id: id, name: 'User $id'));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({String? cursor, int limit = 30}) async =>
      const ChatResult.success(ChatPage(items: []));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(String query, {String? cursor, int limit = 30}) async =>
      const ChatResult.success(ChatPage(items: []));
}

// Host implementation of ConversationRepository
class HostConversationRepository implements ConversationRepository {
  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({String? cursor, int limit = 30}) async =>
      const ChatResult.success(ChatPage(items: []));

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async =>
      ChatResult.success(ChatConversation.direct(
        id: id,
        peer: const ChatUser(id: 'u1', name: 'Alice'),
        updatedAt: DateTime.now(),
      ));

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> deleteConversation(String conversationId) async =>
      ChatResult.ok();
}

// Host implementation of MessageRepository
class HostMessageRepository implements MessageRepository {
  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async =>
      const ChatResult.success(ChatPage(items: []));

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) async =>
      ChatResult.success(message);

  @override
  Future<ChatResult<void>> deleteMessage(String messageId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> markAsDelivered(String messageId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> markAsRead(String messageId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping) async =>
      ChatResult.ok();
}

// Host implementation of GroupRepository
class HostGroupRepository implements GroupRepository {
  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({String? cursor, int limit = 30}) async =>
      const ChatResult.success(ChatPage(items: []));

  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async =>
      ChatResult.success(ChatGroup(id: id, name: 'Group $id'));

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(String groupId, {String? cursor, int limit = 30}) async =>
      const ChatResult.success(ChatPage(items: []));

  @override
  Future<ChatResult<void>> joinGroup(String groupId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> leaveGroup(String groupId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> addMembers(String groupId, List<String> userIds) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> removeMember(String groupId, String userId) async =>
      ChatResult.ok();
}

// Host implementation of ChatEventSource
class HostChatEventSource implements ChatEventSource {
  final _eventsController = StreamController<ChatEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();

  @override
  Stream<ChatEvent> get events => _eventsController.stream;

  @override
  Stream<ConnectionStatus> get connectionState => _connectionController.stream;

  @override
  Future<ChatResult<void>> connect() async => ChatResult.ok();

  @override
  Future<ChatResult<void>> disconnect() async => ChatResult.ok();

  @override
  Future<ChatResult<void>> reconnect() async => ChatResult.ok();
}

// Host implementation of ChatMediaProvider
class HostChatMediaProvider implements ChatMediaProvider {
  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    return const ChatResult.success(UploadedMedia(
      id: 'med_1',
      url: 'https://cdn.example.com/file.jpg',
    ));
  }

  @override
  Future<ChatResult<void>> delete(String mediaId) async =>
      ChatResult.ok();
}

void main() {
  test('Consumer file compiles and operates on public ConvoKit API', () async {
    const user = ChatUser(id: 'u1', name: 'Alice');
    final session = HostChatSession(user);
    final users = HostUserRepository();
    final conversations = HostConversationRepository();
    final messages = HostMessageRepository();
    final groups = HostGroupRepository();
    final events = HostChatEventSource();
    final media = HostChatMediaProvider();

    final kit = ConvoKit(
      session: session,
      users: users,
      conversations: conversations,
      messages: messages,
      groups: groups,
      events: events,
      media: media,
      capabilities: ChatCapabilities.basic(),
    );

    expect(kit.session.currentUser?.id, 'u1');
    expect(kit.capabilities.groups, isTrue);
    expect(kit.capabilities.media, isTrue);

    // Verify ChatResult sealed hierarchy methods
    const successResult = ChatResult.success(42);
    expect(successResult.isSuccess, isTrue);
    expect(successResult.isFailure, isFalse);
    expect(successResult.fold(onSuccess: (v) => v * 2, onFailure: (_) => 0), 84);
    expect(successResult.map((v) => 'num: $v'), const ChatResult.success('num: 42'));

    const failErr = ChatError(ChatErrorCode.network, 'Network failure', outcomeUnknown: true);
    expect(failErr.isRetryable, isTrue);
    const failureResult = ChatResult<int>.failure(failErr);
    expect(failureResult.isSuccess, isFalse);
    expect(failureResult.isFailure, isTrue);
    expect(failureResult.fold(onSuccess: (_) => 'ok', onFailure: (e) => e.message), 'Network failure');
    expect(failureResult.map((v) => 'val: $v'), const ChatResult<String>.failure(failErr));

    final okResult = ChatResult.ok();
    expect(okResult.isSuccess, isTrue);

    // Verify pagination structures
    const pageReq = MessagePageRequest(direction: MessagePageDirection.latest);
    expect(pageReq.direction, MessagePageDirection.latest);

    const chatPage = ChatPage<String>(
      items: ['a', 'b'],
      olderCursor: 'c_older',
      newerCursor: null,
      newerCheckpoint: 'chk_1',
    );
    expect(chatPage.hasOlder, isTrue);
    expect(chatPage.hasNewer, isFalse);
    expect(chatPage.newerCheckpoint, 'chk_1');
  });

  testWidgets('ConvoKitScope and ConversationsView render correctly in widget tree', (tester) async {
    const user = ChatUser(id: 'u1', name: 'Alice');
    final session = HostChatSession(user);
    final kit = ConvoKit(
      session: session,
      users: HostUserRepository(),
      conversations: HostConversationRepository(),
      messages: HostMessageRepository(),
      events: HostChatEventSource(),
    );

    await tester.pumpWidget(
      ConvoKitScope(
        kit: kit,
        child: const ConversationsView(),
      ),
    );

    expect(find.byType(ConversationsView), findsOneWidget);
  });
}
