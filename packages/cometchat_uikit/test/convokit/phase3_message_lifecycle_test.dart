import 'package:convokit/convokit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Phase 3 — Core Message Lifecycle Tests (Plan §7, §8.5)', () {
    late FakeChatBackend fake;
    late ConvoKit kit;
    late EventHub hub;
    late MessageCoordinator coordinator;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 2);
      kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );
      hub = EventHub();
      hub.attach(kit);
      coordinator = hub.coordinator;
    });

    tearDown(() {
      hub.dispose();
    });

    test('optimistic send appears instantly as sending, reconciles on success', () async {
      final store = hub.getMessageStore('conv_1_2');
      final initialCount = store.messages.length;

      // Start optimistic send
      final sendFuture = coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Optimistic message',
        sender: fake.user1,
      );

      // Verify it appears immediately as sending
      expect(store.messages.length, initialCount + 1);
      final pending = store.messages.last;
      expect(pending.sendState, SendState.sending);
      expect(pending.deliveryState, DeliveryState.none);
      expect(pending.id, isNull);
      expect(pending.localId, isNotEmpty);

      // Await send completion
      final result = await sendFuture;
      expect(result.isSuccess, isTrue);

      // Reconciled to sent
      final confirmed = store.messages.last;
      expect(confirmed.localId, pending.localId);
      expect(confirmed.id, isNotNull);
      expect(confirmed.sendState, SendState.sent);
      expect(confirmed.deliveryState, DeliveryState.none);
    });

    test('failed send marks failed and retry resends same localId', () async {
      final store = hub.getMessageStore('conv_1_2');

      fake.failNextSend = true;
      final sendResult = await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Will fail',
        sender: fake.user1,
      );

      expect(sendResult.isFailure, isTrue);
      final failedMsg = store.messages.last;
      expect(failedMsg.sendState, SendState.failed);
      expect(failedMsg.deliveryState, DeliveryState.none);
      expect(failedMsg.failure?.code, ChatErrorCode.sendFailed);
      final localId = failedMsg.localId;

      // Retry same message
      final initialSendCount = fake.sendCallCount;
      final retryResult = await coordinator.retryFailed(
        localId,
        conversationId: 'conv_1_2',
      );

      expect(retryResult.isSuccess, isTrue);
      expect(fake.sendCallCount, initialSendCount + 1);

      final retriedMsg = store.messages.last;
      expect(retriedMsg.localId, localId);
      expect(retriedMsg.sendState, SendState.sent);
      expect(retriedMsg.deliveryState, DeliveryState.none);
    });

    test('idempotency: duplicate localId returns one message and never duplicates in store', () async {
      final store = hub.getMessageStore('conv_1_2');
      final localId = 'fixed_idempotent_local_id';

      // First send
      final res1 = await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'First attempt',
        sender: fake.user1,
        localId: localId,
      );
      expect(res1.isSuccess, isTrue);
      final msgCountAfterFirst = store.messages.length;

      // Duplicate send attempt with same localId
      final duplicateMsg = TextMessage(
        localId: localId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        text: 'First attempt duplicate',
      );
      final res2 = await fake.messages.sendMessage(duplicateMsg);
      expect(res2.isSuccess, isTrue);

      store.addOrReconcile(res2.getOrThrow());

      // Exactly one message in store for this localId
      final matching = store.messages.where((m) => m.localId == localId).toList();
      expect(matching.length, 1);
      expect(store.messages.length, msgCountAfterFirst);
    });

    test('reconciliation via echo event replaces pending message', () async {
      final store = hub.getMessageStore('conv_1_2');
      const echoLocalId = 'echo_local_123';

      // Pending message in store
      final pending = TextMessage(
        localId: echoLocalId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        sendState: SendState.sending,
        text: 'Echo test',
      );
      store.addOrReconcile(pending);

      expect(store.messages.any((m) => m.localId == echoLocalId && m.sendState == SendState.sending), isTrue);

      // Server broadcasts echo MessageReceived before send ack arrives
      final echoMsg = TextMessage(
        id: 'srv_echo_999',
        localId: echoLocalId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: pending.createdAt,
        serverCreatedAt: DateTime.now(),
        sendState: SendState.sent,
        text: 'Echo test',
      );

      fake.injectMessage(echoMsg);

      // Small async tick for event distribution
      await Future<void>.delayed(Duration.zero);

      final reconciled = store.messages.firstWhere((m) => m.localId == echoLocalId);
      expect(reconciled.id, 'srv_echo_999');
      expect(reconciled.sendState, SendState.sent);
      expect(reconciled.deliveryState, DeliveryState.none);
    });

    test('reconciliation via fetched page replaces pending message', () async {
      final store = hub.getMessageStore('conv_1_2');
      const pageLocalId = 'page_local_456';

      final pending = TextMessage(
        localId: pageLocalId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        sendState: SendState.sending,
        text: 'Page reconciliation test',
      );
      store.addOrReconcile(pending);

      // Backend persisted it as server message
      final serverMsg = TextMessage(
        id: 'srv_page_888',
        localId: pageLocalId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: pending.createdAt,
        serverCreatedAt: DateTime.now(),
        sendState: SendState.sent,
        text: 'Page reconciliation test',
      );
      fake.messagesByConversation['conv_1_2']!.add(serverMsg);

      // Fetch page
      final fetchResult = await coordinator.fetchLatest('conv_1_2');
      expect(fetchResult.isSuccess, isTrue);

      final reconciled = store.messages.firstWhere((m) => m.localId == pageLocalId);
      expect(reconciled.id, 'srv_page_888');
      expect(reconciled.sendState, SendState.sent);
    });

    test('lost-response (outcomeUnknown) retries to the same single message', () async {
      final store = hub.getMessageStore('conv_1_2');

      // Inject lost response: backend persists, but network drops before response
      fake.returnOutcomeUnknownNextSend = true;

      final sendResult = await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'Lost response message',
        sender: fake.user1,
      );

      expect(sendResult.isFailure, isTrue);
      final error = (sendResult as ChatFailure<ChatMessage>).error;
      expect(error.outcomeUnknown, isTrue);

      final failedMsg = store.messages.last;
      expect(failedMsg.sendState, SendState.failed);
      expect(failedMsg.deliveryState, DeliveryState.none);
      expect(failedMsg.failure?.outcomeUnknown, isTrue);

      final countBeforeRetry = store.messages.length;

      // Retry
      final retryResult = await coordinator.retryFailed(
        failedMsg.localId,
        conversationId: 'conv_1_2',
      );

      expect(retryResult.isSuccess, isTrue);

      // Exactly one message exists
      expect(store.messages.length, countBeforeRetry);
      final retriedMsg = store.messages.last;
      expect(retriedMsg.localId, failedMsg.localId);
      expect(retriedMsg.sendState, SendState.sent);
      expect(retriedMsg.deliveryState, DeliveryState.none);
    });

    test('retried failed send leaves deliveryState at none throughout', () async {
      final store = hub.getMessageStore('conv_1_2');

      fake.failNextSend = true;
      await coordinator.sendTextMessage(
        conversationId: 'conv_1_2',
        text: 'State transition test',
        sender: fake.user1,
      );

      final failedMsg = store.messages.last;
      expect(failedMsg.sendState, SendState.failed);
      expect(failedMsg.deliveryState, DeliveryState.none);

      final retryResult = await coordinator.retryFailed(
        failedMsg.localId,
        conversationId: 'conv_1_2',
      );
      expect(retryResult.isSuccess, isTrue);

      final sentMsg = store.messages.last;
      expect(sentMsg.sendState, SendState.sent);
      expect(sentMsg.deliveryState, DeliveryState.none);
    });
  });
}
