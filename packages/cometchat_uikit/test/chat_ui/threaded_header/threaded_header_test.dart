import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitThreadedHeader (ConvoKitScope + MessageStore)', () {
    late FakeChatBackend fake;
    late ConvoKit kit;
    late TextMessage parentMessage;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 3);
      kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: fake.groups,
        capabilities: ChatCapabilities.basic(),
      );
      parentMessage = TextMessage(
        id: 'parent_1',
        localId: 'local_parent_1',
        conversationId: 'conv_thread_1',
        sender: fake.user1,
        createdAt: DateTime(2026, 11, 1, 10, 0),
        text: 'Parent thread message',
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
      );
    });

    Widget wrapWithScope(ConvoKit activeKit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(
          kit: activeKit,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('renders parent message text and initial reply count', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(
          kit,
          ConvoKitThreadedHeader(
            parentMessage: parentMessage,
            user: fake.user2,
            initialReplyCount: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent thread message', findRichText: true), findsOneWidget);
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets(
      'updates reply count reactively when MessageStore receives replies',
      (tester) async {
        await tester.pumpWidget(
          wrapWithScope(
            kit,
            ConvoKitThreadedHeader(
              parentMessage: parentMessage,
              loggedInUser: fake.user1,
              user: fake.user2,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('0'), findsWidgets);

        fake.injectMessage(
          TextMessage(
            id: 'reply_1',
            localId: 'local_reply_1',
            conversationId: parentMessage.conversationId,
            sender: fake.user2,
            createdAt: DateTime(2026, 11, 1, 10, 1),
            text: 'First reply',
            sendState: SendState.sent,
            repliedTo: parentMessage,
          ),
        );
        fake.injectMessage(
          TextMessage(
            id: 'reply_2',
            localId: 'local_reply_2',
            conversationId: parentMessage.conversationId,
            sender: fake.user1,
            createdAt: DateTime(2026, 11, 1, 10, 2),
            text: 'Second reply',
            sendState: SendState.sent,
            repliedTo: parentMessage,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('2'), findsWidgets);
      },
    );

    testWidgets('supports custom messageActionView and clean dispose', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(
          kit,
          ConvoKitThreadedHeader(
            parentMessage: parentMessage,
            messageActionView: (msg, _) =>
                Text('Custom action for ${msg.localId}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom action for local_parent_1'), findsOneWidget);

      // Unmount and ensure injecting messages afterwards does not throw
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      fake.injectMessage(
        TextMessage(
          id: 'reply_after_dispose',
          localId: 'local_reply_after_dispose',
          conversationId: parentMessage.conversationId,
          sender: fake.user2,
          createdAt: DateTime(2026, 11, 1, 10, 5),
          text: 'Late reply',
          sendState: SendState.sent,
          repliedTo: parentMessage,
        ),
      );
      await tester.pump();
    });
  });
}
