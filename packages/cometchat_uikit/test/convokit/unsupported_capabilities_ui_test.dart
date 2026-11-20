import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:convokit/convokit.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Unsupported capabilities hide UI tests (Plan §8.12)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend();
    });

    testWidgets('ChatCapabilities() default (all false): hides receipts, attach button, typing, groups, search, calls/AI', (tester) async {
      // With groups: null + groups: false and media: null + media: false
      // App builds and runs with no stubs.
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: null,
        media: null,
        capabilities: const ChatCapabilities(), // all false
      );

      // 1. Test ConversationsView
      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const Scaffold(
              body: ConversationsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ConversationsView renders conversation list
      expect(find.byType(ConversationsView), findsOneWidget);

      // Groups tab is NOT present
      expect(find.text('Groups'), findsNothing);
      expect(find.byKey(const Key('groups_tab')), findsNothing);

      // Search field is NOT present
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('search_field')), findsNothing);

      // Call and AI entry points are NOT present
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);
      expect(find.byKey(const Key('ai_button')), findsNothing);

      // 2. Test MessageListView with sent message
      // Seed a sent message in fake
      final testMsg = TextMessage(
        localId: 'msg_capabilities_test',
        id: 'srv_msg_1',
        conversationId: 'conv_1_2',
        sender: fake.user1, // logged-in user
        createdAt: DateTime.now(),
        text: 'Hello capabilities',
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
      );
      fake.messagesByConversation['conv_1_2'] = [testMsg];

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const Scaffold(
              body: MessageListView(conversationId: 'conv_1_2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Message content is visible
      expect(find.text('Hello capabilities'), findsOneWidget);

      // With receipts: false -> NO receipt UI of any kind (including single sent tick)
      expect(find.byKey(const Key('receipt_sent')), findsNothing);
      expect(find.byKey(const Key('receipt_delivered')), findsNothing);
      expect(find.byKey(const Key('receipt_read')), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);

      // With typing: false -> NO typing indicator
      expect(find.byKey(const Key('typing_indicator')), findsNothing);
      expect(find.textContaining('is typing'), findsNothing);

      // With media: false -> NO attach button
      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.byKey(const Key('attach_button')), findsNothing);

      // NO call or AI entry points
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);
      expect(find.byKey(const Key('ai_assistant')), findsNothing);
    });

    testWidgets('With capabilities.receipts = true, receipt UI is rendered on sent message', (tester) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: null,
        media: null,
        capabilities: const ChatCapabilities(receipts: true),
      );

      final testMsg = TextMessage(
        localId: 'msg_receipts_enabled_test',
        id: 'srv_msg_2',
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        text: 'Receipt enabled message',
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
      );
      fake.messagesByConversation['conv_1_2'] = [testMsg];

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const Scaffold(
              body: MessageListView(conversationId: 'conv_1_2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Receipt enabled message'), findsOneWidget);
      // Delivered receipt tick IS rendered
      expect(find.byKey(const Key('receipt_delivered')), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });
  });
}
