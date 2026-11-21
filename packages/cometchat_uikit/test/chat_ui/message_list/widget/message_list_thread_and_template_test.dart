import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  testWidgets(
    'ConvoKitMessageList supports parentMessageId filtering, addTemplate dispatch, and onThreadRepliesClick',
    (tester) async {
      final fake = FakeChatBackend(seededMessageCount: 0);
      final convId = fake.conversationsList.first.id;
      final now = DateTime.utc(2026, 5, 14, 12, 0);

      final parentMsg = TextMessage(
        id: 'msg_parent_1',
        localId: 'local_parent_1',
        conversationId: convId,
        sender: fake.user2,
        createdAt: now,
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Parent topic message',
      );
      final unrelatedMsg = TextMessage(
        id: 'msg_other_1',
        localId: 'local_other_1',
        conversationId: convId,
        sender: fake.user1,
        createdAt: now.add(const Duration(minutes: 1)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        text: 'Unrelated root message',
      );
      final replyMsg = TextMessage(
        id: 'msg_reply_1',
        localId: 'local_reply_1',
        conversationId: convId,
        sender: fake.user1,
        createdAt: now.add(const Duration(minutes: 2)),
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
        repliedTo: parentMsg,
        text: 'Threaded reply body',
      );

      fake.messagesByConversation[convId] = <ChatMessage>[
        parentMsg,
        unrelatedMsg,
        replyMsg,
      ];

      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(),
      );

      // 1. Default mode (all three props null): all messages render, no thread affordance.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: ConvoKitScope(
            kit: kit,
            child: Scaffold(
              body: ConvoKitMessageList(conversationId: convId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent topic message'), findsOneWidget);
      expect(find.text('Unrelated root message'), findsOneWidget);
      expect(find.text('Threaded reply body'), findsOneWidget);
      expect(find.text('1 reply'), findsNothing);

      // 2. addTemplate + onThreadRepliesClick in main conversation.
      ChatMessage? clickedThreadParent;
      CometChatMessageTemplate? clickedTemplate;

      final customTextTemplate = CometChatMessageTemplate(
        category: MessageCategoryConstants.message,
        type: MessageTypeConstants.text,
        contentView: (message, ctx, alignment, {additionalConfigurations}) {
          if (message is TextMessage && message.id == 'msg_parent_1') {
            return Text('CUSTOM: ${message.text}');
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: ConvoKitScope(
            kit: kit,
            child: Scaffold(
              body: ConvoKitMessageList(
                conversationId: convId,
                addTemplate: <CometChatMessageTemplate>[customTextTemplate],
                onThreadRepliesClick: (message, ctx, {template}) {
                  clickedThreadParent = message;
                  clickedTemplate = template;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Custom template takes precedence for matching message; null falls back to default.
      expect(find.text('CUSTOM: Parent topic message'), findsOneWidget);
      expect(find.text('Unrelated root message'), findsOneWidget);

      // Thread reply affordance renders on parentMsg and invokes callback on tap.
      expect(find.text('1 reply'), findsOneWidget);
      await tester.tap(find.byKey(const Key('thread_replies_msg_parent_1')));
      await tester.pump();
      expect(clickedThreadParent?.id, 'msg_parent_1');
      expect(clickedTemplate, same(customTextTemplate));

      // 3. parentMessageId set: only replies to parentMsg render.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: ConvoKitScope(
            kit: kit,
            child: Scaffold(
              body: ConvoKitMessageList(
                conversationId: convId,
                parentMessageId: 'msg_parent_1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Threaded reply body'), findsOneWidget);
      expect(find.text('Parent topic message'), findsNothing);
      expect(find.text('Unrelated root message'), findsNothing);
    },
  );
}
