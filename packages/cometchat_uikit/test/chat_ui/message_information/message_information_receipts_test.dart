import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';

void main() {
  group('CometChatMessageInformation (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 3);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(
          kit: kit,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
      'hides all receipt rows when capabilities.receipts is false',
      (tester) async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(receipts: false),
        );

        final msg = TextMessage(
          id: 'msg_no_receipts',
          localId: 'local_no_receipts',
          conversationId: 'conv_info_1',
          sender: fake.user1,
          createdAt: DateTime(2026, 11, 1, 12, 0),
          text: 'Secret receipt test',
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
        );

        await tester.pumpWidget(
          wrapWithScope(kit, CometChatMessageInformation(message: msg)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Secret receipt test', findRichText: true), findsOneWidget);
        expect(find.byType(ConvoKitReceipt), findsNothing);
        expect(find.text('----'), findsNothing);
      },
    );

    testWidgets(
      'renders sendState and deliveryState directly when capabilities.receipts is true',
      (tester) async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(receipts: true),
        );

        final deliveredOnly = TextMessage(
          id: 'msg_delivered',
          localId: 'local_delivered',
          conversationId: 'conv_info_2',
          sender: fake.user1,
          createdAt: DateTime(2026, 11, 1, 12, 30),
          serverCreatedAt: DateTime(2026, 11, 1, 12, 30),
          text: 'Delivered message',
          sendState: SendState.sent,
          deliveryState: DeliveryState.delivered,
        );

        await tester.pumpWidget(
          wrapWithScope(
            kit,
            CometChatMessageInformation(
              message: deliveredOnly,
              title: 'Custom Info Title',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Custom Info Title'), findsOneWidget);
        expect(find.text('Delivered message', findRichText: true), findsOneWidget);
        // Read row shows "----" while Delivered row shows formatted date
        expect(find.text('----'), findsOneWidget);
        expect(find.textContaining('2026'), findsOneWidget);
      },
    );

    testWidgets('updates receipt row live when MessageStatusChanged arrives', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(receipts: true),
      );

      final sentMsg = TextMessage(
        id: 'msg_live_receipt',
        localId: 'local_live_receipt',
        conversationId: 'conv_info_3',
        sender: fake.user1,
        createdAt: DateTime(2026, 11, 1, 14, 0),
        serverCreatedAt: DateTime(2026, 11, 1, 14, 0),
        text: 'Live receipt update',
        sendState: SendState.sent,
        deliveryState: DeliveryState.none,
      );

      await tester.pumpWidget(
        wrapWithScope(kit, CometChatMessageInformation(message: sentMsg)),
      );
      await tester.pumpAndSettle();

      // Initially neither delivered nor read -> two "----" placeholders
      expect(find.text('----'), findsNWidgets(2));

      // Seed message in EventHub store and transition to read
      fake.injectMessage(sentMsg);
      fake.injectStatusChange(
        sentMsg.conversationId,
        sentMsg.id!,
        DeliveryState.read,
      );
      await tester.pumpAndSettle();

      expect(find.text('----'), findsNothing);
    });

    testWidgets('shows failure message when sendState is SendState.failed', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(receipts: true),
      );

      final failedMsg = TextMessage(
        localId: 'local_failed',
        conversationId: 'conv_info_4',
        sender: fake.user1,
        createdAt: DateTime(2026, 11, 1, 15, 0),
        text: 'Failed delivery',
        sendState: SendState.failed,
        deliveryState: DeliveryState.none,
        failure: const ChatError(ChatErrorCode.network, 'Network offline'),
      );

      await tester.pumpWidget(
        wrapWithScope(kit, CometChatMessageInformation(message: failedMsg)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network offline'), findsOneWidget);
    });
  });
}
