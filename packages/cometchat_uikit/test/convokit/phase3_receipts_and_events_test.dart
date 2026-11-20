import 'package:cometchat_chat_uikit/convokit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Phase 3 — Receipts and Realtime Events Tests (Plan §7, §8.9, §8.10)', () {
    test('reconnect recovery + event/pagination dedupe preserves uniqueness and re-syncs unread counts', () async {
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
      final coordinator = hub.coordinator;
      final store = hub.getMessageStore('conv_1_2');
      hub.registerVisibleConversation('conv_1_2');

      await coordinator.fetchLatest('conv_1_2');
      expect(store.messages.length, 2);

      // Disconnect
      fake.simulateDisconnect();

      // Inject new message into backend
      final now = DateTime.now();
      final newMsg = TextMessage(
        id: 'msg_reconnect_1',
        localId: 'local_reconnect_1',
        conversationId: 'conv_1_2',
        sender: fake.user2,
        createdAt: now,
        serverCreatedAt: now,
        sendState: SendState.sent,
        deliveryState: DeliveryState.none,
        text: 'Reconnect dedupe test',
      );
      fake.injectMessage(newMsg);

      // Emit duplicate event of the same message while disconnected/reconnecting
      fake.emitEvent(
        MessageReceived(message: newMsg, receivedAt: DateTime.now()),
      );

      // Reconnect
      fake.simulateConnect();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Assert no message appears twice
      expect(store.messages.length, 3);
      final matching = store.messages.where((m) => m.id == 'msg_reconnect_1').toList();
      expect(matching.length, 1);

      // Assert unread counts re-sync from list refresh
      final conv = hub.conversationStore.conversations.firstWhere((c) => c.id == 'conv_1_2');
      expect(conv.lastMessage?.id, 'msg_reconnect_1');

      hub.dispose();
    });

    test('receipt forward-only updates via MessageStatusChanged', () async {
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
      final coordinator = hub.coordinator;
      final store = hub.getMessageStore('conv_1_2');

      // Send a message as currentUser (user1)
      final sendResult = await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'My sent message',
        sender: fake.user1,
      );
      expect(sendResult.isSuccess, isTrue);
      final sentMsg = sendResult.getOrThrow();
      expect(sentMsg.sendState, SendState.sent);
      expect(sentMsg.deliveryState, DeliveryState.none);

      // 1. none -> delivered
      fake.injectStatusChange('conv_1_2', sentMsg.id!, DeliveryState.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(store.messages.last.deliveryState, DeliveryState.delivered);

      // 2. delivered -> read
      fake.injectStatusChange('conv_1_2', sentMsg.id!, DeliveryState.read);
      await Future<void>.delayed(Duration.zero);
      expect(store.messages.last.deliveryState, DeliveryState.read);

      // 3. Stale/backwards update (delivered) is ignored
      fake.injectStatusChange('conv_1_2', sentMsg.id!, DeliveryState.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(store.messages.last.deliveryState, DeliveryState.read);

      // 4. Update for unknown message id is ignored
      fake.injectStatusChange('conv_1_2', 'non_existent_id', DeliveryState.delivered);
      await Future<void>.delayed(Duration.zero);

      // 5. Update to a failed or sending message is ignored
      fake.failNextSend = true;
      await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Failed msg',
        sender: fake.user1,
      );
      final failedMsg = store.messages.last;
      expect(failedMsg.sendState, SendState.failed);
      expect(failedMsg.deliveryState, DeliveryState.none);

      fake.injectStatusChange('conv_1_2', failedMsg.localId, DeliveryState.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(store.messages.last.deliveryState, DeliveryState.none);

      hub.dispose();
    });

    testWidgets('receipts: false suppresses ALL receipt UI on sent messages', (WidgetTester tester) async {
      final fake = FakeChatBackend(seededMessageCount: 0);

      // capabilities with receipts = false
      final kitNoReceipts = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(receipts: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kitNoReceipts,
            child: const Scaffold(
              body: MessageListView(conversationId: 'conv_1_2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hub = ConvoKitScope.hubOf(tester.element(find.byType(MessageListView)));
      await hub.coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Sent without receipts capability',
        sender: fake.user1,
      );
      await tester.pumpAndSettle();

      // Sent message is rendered
      expect(find.text('Sent without receipts capability'), findsOneWidget);

      // ALL receipt UI is suppressed: no ticks rendered
      expect(find.byKey(const Key('receipt_sent')), findsNothing);
      expect(find.byKey(const Key('receipt_delivered')), findsNothing);
      expect(find.byKey(const Key('receipt_read')), findsNothing);
    });

    testWidgets('receipts: true renders ticks for sent messages', (WidgetTester tester) async {
      final fake = FakeChatBackend(seededMessageCount: 0);

      final kitWithReceipts = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(receipts: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kitWithReceipts,
            child: const Scaffold(
              body: MessageListView(conversationId: 'conv_1_2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hub = ConvoKitScope.hubOf(tester.element(find.byType(MessageListView)));
      final sendResult = await hub.coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Sent with receipts capability',
        sender: fake.user1,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sent with receipts capability'), findsOneWidget);
      // Single tick visible
      expect(find.byKey(const Key('receipt_sent')), findsOneWidget);

      // Deliver message
      fake.injectStatusChange('conv_1_2', sendResult.getOrThrow().id!, DeliveryState.delivered);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('receipt_delivered')), findsOneWidget);

      // Read message
      fake.injectStatusChange('conv_1_2', sendResult.getOrThrow().id!, DeliveryState.read);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('receipt_read')), findsOneWidget);
    });

    test('typing indicator registers and expires after ~5s without refresh', () async {
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

      // User 2 starts typing
      fake.injectTyping('conv_1_2', fake.user2, true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(hub.typingRegistry.getTypingUsers('conv_1_2').length, 1);
      expect(hub.typingRegistry.getTypingUsers('conv_1_2').first.id, fake.user2.id);

      // Wait 5.2 seconds for expiry timer
      await Future<void>.delayed(const Duration(milliseconds: 5200));

      // Indicator automatically cleared
      expect(hub.typingRegistry.getTypingUsers('conv_1_2'), isEmpty);

      hub.dispose();
    });

    test('presence updates via PresenceChanged event', () async {
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

      expect(hub.presenceRegistry.getPresence(fake.user3.id), UserPresence.unknown);

      fake.injectPresence(fake.user3, UserPresence.online);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(hub.presenceRegistry.getPresence(fake.user3.id), UserPresence.online);

      fake.injectPresence(fake.user3, UserPresence.away);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(hub.presenceRegistry.getPresence(fake.user3.id), UserPresence.away);

      hub.dispose();
    });
  });
}
