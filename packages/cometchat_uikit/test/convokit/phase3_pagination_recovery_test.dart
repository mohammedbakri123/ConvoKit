import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Phase 3 — Pagination and Catch-up Recovery Tests (Plan §7, §8.6, §8.7, §8.8)', () {
    test('older pagination loads all 105 messages, no duplicates, in order, hasOlder false at end', () async {
      final fake = FakeChatBackend(seededMessageCount: 105);
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

      // 1. Initial latest fetch (returns newest 30 messages)
      final initialRes = await coordinator.fetchLatest('conv_1_2', limit: 30);
      expect(initialRes.isSuccess, isTrue);
      expect(store.messages.length, 30);
      expect(store.hasOlder, isTrue);

      // 2. Paginate older history until hasOlder is false
      while (store.hasOlder) {
        final olderRes = await coordinator.fetchOlder('conv_1_2', limit: 30);
        expect(olderRes.isSuccess, isTrue);
      }

      expect(store.hasOlder, isFalse);
      expect(store.messages.length, 105);

      // Dedupe check: all IDs unique
      final ids = store.messages.map((m) => m.id).toSet();
      expect(ids.length, 105);

      // Ordering check: msg_0 .. msg_104
      for (int i = 0; i < 105; i++) {
        expect(store.messages[i].id, 'msg_$i');
      }

      hub.dispose();
    });

    test('newer catch-up from stored checkpoint recovers messages after disconnect', () async {
      final fake = FakeChatBackend(seededMessageCount: 10);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(messageCatchUp: true),
      );
      final hub = EventHub();
      hub.attach(kit);
      final coordinator = hub.coordinator;
      final store = hub.getMessageStore('conv_1_2');

      // Latest fetch establishes checkpoint while hasNewer is false
      await coordinator.fetchLatest('conv_1_2', limit: 30);
      expect(store.hasNewer, isFalse);
      expect(store.newerCheckpoint, isNotNull);
      final initialCheckpoint = store.newerCheckpoint;

      // Disconnect
      fake.simulateDisconnect();
      hub.registerVisibleConversation('conv_1_2');

      // Inject 5 messages while disconnected
      final now = DateTime.now();
      for (int i = 10; i < 15; i++) {
        fake.messagesByConversation['conv_1_2']!.add(
          TextMessage(
            id: 'msg_$i',
            localId: 'local_injected_$i',
            conversationId: 'conv_1_2',
            sender: fake.user2,
            createdAt: now.add(Duration(minutes: i)),
            serverCreatedAt: now.add(Duration(minutes: i)),
            sendState: SendState.sent,
            deliveryState: DeliveryState.none,
            text: 'Catchup message $i',
          ),
        );
      }

      // Reconnect
      fake.simulateConnect();

      // Wait for recovery queue
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(store.messages.length, 15);
      expect(store.hasPossibleGap, isFalse);

      // Dedupe & ordering check
      final ids = store.messages.map((m) => m.id).toList();
      expect(ids.toSet().length, 15);
      for (int i = 0; i < 15; i++) {
        expect(ids[i], 'msg_$i');
      }

      expect(store.newerCheckpoint, isNot(equals(initialCheckpoint)));
      hub.dispose();
    });

    test('checkpoint-null fallback performs latest refresh without duplicates', () async {
      final fake = FakeChatBackend(seededMessageCount: 10);
      fake.nullCheckpoint = true; // Null checkpoint fallback scenario

      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(messageCatchUp: true),
      );
      final hub = EventHub();
      hub.attach(kit);
      final coordinator = hub.coordinator;
      final store = hub.getMessageStore('conv_1_2');

      await coordinator.fetchLatest('conv_1_2', limit: 30);
      expect(store.newerCheckpoint, isNull);

      fake.simulateDisconnect();
      hub.registerVisibleConversation('conv_1_2');

      // Inject 3 new messages
      final now = DateTime.now();
      for (int i = 10; i < 13; i++) {
        fake.messagesByConversation['conv_1_2']!.add(
          TextMessage(
            id: 'msg_$i',
            localId: 'local_injected_$i',
            conversationId: 'conv_1_2',
            sender: fake.user2,
            createdAt: now.add(Duration(minutes: i)),
            serverCreatedAt: now.add(Duration(minutes: i)),
            sendState: SendState.sent,
            deliveryState: DeliveryState.none,
            text: 'Fallback message $i',
          ),
        );
      }

      fake.simulateConnect();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Recovered via latest fetch fallback
      expect(store.messages.length, 13);
      final ids = store.messages.map((m) => m.id).toSet();
      expect(ids.length, 13);

      hub.dispose();
    });

    testWidgets('catch-up limit sets gap flag, displays banner, and refresh completes recovery', (WidgetTester tester) async {
      final fake = FakeChatBackend(seededMessageCount: 10);
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(messageCatchUp: true),
      );

      final controller = MessageListController();

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: Scaffold(
              body: MessageListView(
                conversationId: 'conv_1_2',
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially 10 messages, no gap banner
      expect(find.byKey(const Key('gap_banner')), findsNothing);

      // Disconnect
      fake.simulateDisconnect();
      await tester.pump();

      // Inject 400 messages into conversation (10 pages * 30 = 300 will be fetched, 100 still remaining newer!)
      final now = DateTime.now();
      for (int i = 10; i < 410; i++) {
        fake.messagesByConversation['conv_1_2']!.add(
          TextMessage(
            id: 'msg_$i',
            localId: 'local_msg_$i',
            conversationId: 'conv_1_2',
            sender: fake.user2,
            createdAt: now.add(Duration(seconds: i)),
            serverCreatedAt: now.add(Duration(seconds: i)),
            sendState: SendState.sent,
            deliveryState: DeliveryState.none,
            text: 'Overflow message $i',
          ),
        );
      }

      // Reconnect
      fake.simulateConnect();

      // Wait for recovery (10 iterations of newer page requests)
      for (int step = 0; step < 15; step++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Gap flag is set because limit of 10 pages was hit while hasNewer was still true!
      expect(controller.hasPossibleGap, isTrue);
      expect(find.byKey(const Key('gap_banner')), findsOneWidget);
      expect(find.text('Some messages may be missing'), findsOneWidget);
      expect(find.byKey(const Key('gap_banner_refresh')), findsOneWidget);

      // Tap Refresh button to complete recovery with fresh 10-page budget
      await tester.tap(find.byKey(const Key('gap_banner_refresh')));

      // Allow catch-up pages to finish
      for (int step = 0; step < 10; step++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Recovery is now complete!
      expect(controller.hasPossibleGap, isFalse);
      expect(find.byKey(const Key('gap_banner')), findsNothing);
    });
  });
}
