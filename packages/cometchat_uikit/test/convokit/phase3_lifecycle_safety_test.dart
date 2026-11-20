import 'package:cometchat_chat_uikit/convokit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Phase 3 — Async Lifecycle Safety Tests (Plan §7, §8.17, §8.18, §11.2)', () {
    test('identity change A->B clears old data, closes old connection, and discards pending', () async {
      final fakeA = FakeChatBackend(seededMessageCount: 2);
      final kitA = ConvoKit(
        session: fakeA.session,
        users: fakeA.users,
        conversations: fakeA.conversations,
        messages: fakeA.messages,
        events: fakeA.events,
        capabilities: ChatCapabilities.basic(),
      );

      final fakeB = FakeChatBackend(seededMessageCount: 0);
      final kitB = ConvoKit(
        session: fakeB.session,
        users: fakeB.users,
        conversations: fakeB.conversations,
        messages: fakeB.messages,
        events: fakeB.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kitA);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final storeA = hub.getMessageStore('conv_1_2');
      // Add pending message for user A
      final pendingA = TextMessage(
        localId: 'local_pending_user_a',
        conversationId: 'conv_1_2',
        sender: fakeA.user1,
        createdAt: DateTime.now(),
        sendState: SendState.sending,
        text: 'User A pending text',
      );
      storeA.addOrReconcile(pendingA);
      expect(storeA.messages.any((m) => m.localId == 'local_pending_user_a'), isTrue);

      // Reattach to kit B (identity change)
      hub.reattach(kitB);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 1. Old connection closed
      expect(fakeA.disconnectCount, greaterThanOrEqualTo(1));

      // 2. Old data cleared and pending discarded
      final storeB = hub.getMessageStore('conv_1_2');
      expect(storeB.messages.any((m) => m.localId == 'local_pending_user_a'), isFalse);
      expect(storeB.messages, isEmpty);

      // 3. New connection established
      expect(fakeB.connectCount, greaterThanOrEqualTo(1));
      expect(hub.currentKit, kitB);

      hub.dispose();
    });

    test('scope dispose disconnects event source and clears all stores', () async {
      final fake = FakeChatBackend(seededMessageCount: 2);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kit);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      hub.conversationStore.setConversations(fake.conversationsList);
      expect(hub.conversationStore.conversations, isNotEmpty);

      // Dispose
      hub.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(hub.isDisposed, isTrue);
      expect(fake.disconnectCount, greaterThanOrEqualTo(1));
      expect(hub.conversationStore.conversations, isEmpty);
      expect(hub.typingRegistry.getTypingUsers('conv_1_2'), isEmpty);
    });

    test('stream termination treated as transport failure with reconnect policy', () async {
      final fake = FakeChatBackend(seededMessageCount: 1);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kit);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Stream terminates unexpectedly
      fake.simulateEventsStreamDone();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Treated as transport failure
      expect(hub.currentConnectionStatus.state, ConnectionState.disconnected);
      expect(hub.currentConnectionStatus.error, isNotNull);
      expect(fake.disconnectCount, greaterThanOrEqualTo(1));

      hub.dispose();
    });

    test('kit replacement while connect is in progress discards stale result and disconnects old first', () async {
      final fakeA = FakeChatBackend(seededMessageCount: 1);
      fakeA.connectDelay = const Duration(milliseconds: 80);
      final kitA = ConvoKit(
        session: fakeA.session,
        users: fakeA.users,
        conversations: fakeA.conversations,
        messages: fakeA.messages,
        events: fakeA.events,
        capabilities: ChatCapabilities.basic(),
      );

      final fakeB = FakeChatBackend(seededMessageCount: 1);
      final kitB = ConvoKit(
        session: fakeB.session,
        users: fakeB.users,
        conversations: fakeB.conversations,
        messages: fakeB.messages,
        events: fakeB.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kitA); // Kit A starts connecting asynchronously

      // Replace kit while A connect is in progress
      await Future<void>.delayed(const Duration(milliseconds: 10));
      hub.reattach(kitB);

      // Wait for everything to complete
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(fakeA.disconnectCount, greaterThanOrEqualTo(1));
      expect(fakeB.connectCount, 1);
      expect(hub.currentKit, kitB);

      hub.dispose();
    });

    test('rapid identity changes A->B->C connects only C', () async {
      final fakeA = FakeChatBackend(seededMessageCount: 1);
      fakeA.connectDelay = const Duration(milliseconds: 60);
      final kitA = ConvoKit(
        session: fakeA.session,
        users: fakeA.users,
        conversations: fakeA.conversations,
        messages: fakeA.messages,
        events: fakeA.events,
        capabilities: ChatCapabilities.basic(),
      );

      final fakeB = FakeChatBackend(seededMessageCount: 1);
      fakeB.connectDelay = const Duration(milliseconds: 60);
      final kitB = ConvoKit(
        session: fakeB.session,
        users: fakeB.users,
        conversations: fakeB.conversations,
        messages: fakeB.messages,
        events: fakeB.events,
        capabilities: ChatCapabilities.basic(),
      );

      final fakeC = FakeChatBackend(seededMessageCount: 1);
      final kitC = ConvoKit(
        session: fakeC.session,
        users: fakeC.users,
        conversations: fakeC.conversations,
        messages: fakeC.messages,
        events: fakeC.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();

      // Rapid consecutive changes without waiting
      hub.attach(kitA);
      hub.reattach(kitB);
      hub.reattach(kitC);

      // Wait for queue
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // A and B were torn down without connecting; only C connected
      expect(fakeA.connectCount, 0);
      expect(fakeB.connectCount, 0);
      expect(fakeC.connectCount, 1);
      expect(hub.currentKit, kitC);

      hub.dispose();
    });

    test('scope dispose during a connect leaves no event able to reach a store afterwards', () async {
      final fake = FakeChatBackend(seededMessageCount: 1);
      fake.connectDelay = const Duration(milliseconds: 80);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kit);

      // Dispose while connect is in progress
      await Future<void>.delayed(const Duration(milliseconds: 10));
      hub.dispose();

      // Wait for connect delay to pass
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Try emitting event on the source
      final msg = TextMessage(
        id: 'msg_after_dispose',
        localId: 'local_after_dispose',
        conversationId: 'conv_1_2',
        sender: fake.user2,
        createdAt: DateTime.now(),
        text: 'Should not reach store',
      );
      fake.emitEvent(MessageReceived(message: msg, receivedAt: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Store remains cleared / empty
      expect(hub.conversationStore.conversations, isEmpty);
    });

    test('event and session streams re-subscribed after termination deliver new events', () async {
      final fake = FakeChatBackend(seededMessageCount: 1);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kit);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Terminate event stream
      fake.simulateEventsStreamDone();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(hub.currentConnectionStatus.state, ConnectionState.disconnected);

      // Manual retry re-subscribes fresh
      hub.retryConnection();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(hub.currentConnectionStatus.state, ConnectionState.connected);

      // Emit new message on restartable stream
      final store = hub.getMessageStore('conv_1_2');
      final newMsg = TextMessage(
        id: 'msg_after_reconnect',
        localId: 'local_after_reconnect',
        conversationId: 'conv_1_2',
        sender: fake.user2,
        createdAt: DateTime.now(),
        serverCreatedAt: DateTime.now(),
        sendState: SendState.sent,
        text: 'Delivered after stream restart',
      );
      fake.injectMessage(newMsg);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(store.messages.any((m) => m.id == 'msg_after_reconnect'), isTrue);

      hub.dispose();
    });

    test('currentUserStream error/termination disconnects, clears stores, and waits for a new kit', () async {
      final fake = FakeChatBackend(seededMessageCount: 2);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      final hub = EventHub();
      hub.attach(kit);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      hub.conversationStore.setConversations(fake.conversationsList);
      expect(hub.conversationStore.conversations, isNotEmpty);

      // Session stream emits error
      fake.simulateSessionStreamError(Exception('Session expired'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Disconnected, all stores cleared
      expect(fake.disconnectCount, greaterThanOrEqualTo(1));
      expect(hub.currentConnectionStatus.state, ConnectionState.disconnected);
      expect(hub.conversationStore.conversations, isEmpty);

      hub.dispose();
    });
  });
}
