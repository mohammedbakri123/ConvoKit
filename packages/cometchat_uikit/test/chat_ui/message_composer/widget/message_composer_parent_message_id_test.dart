import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  testWidgets(
    'ConvoKitMessageComposer accepts String? parentMessageId and attaches repliedTo on threaded send',
    (tester) async {
      final backend = FakeChatBackend(seededMessageCount: 2);
      final convId = backend.conversationsList.first.id;
      final parentMessage = backend.messagesByConversation[convId]!.first;
      final parentId = parentMessage.id!;

      final kit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: ChatCapabilities.basic(),
        groups: backend.groups,
        media: backend.media,
      );

      ChatMessage? sentMessage;
      await tester.pumpWidget(
        ConvoKitScope(
          kit: kit,
          child: MaterialApp(
            localizationsDelegates: Translations.localizationsDelegates,
            supportedLocales: Translations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: ConvoKitMessageList(conversationId: convId),
                  ),
                  ConvoKitMessageComposer(
                    conversationId: convId,
                    user: backend.user2,
                    parentMessageId: parentId,
                    onSendButtonTap: (_, msg, _) => sentMessage = msg,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(ConvoKitMessageComposer),
          matching: find.byType(TextField),
        ),
        'Threaded reply via parentMessageId',
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pumpAndSettle();

      expect(sentMessage, isA<TextMessage>());
      expect(
        (sentMessage! as TextMessage).text,
        'Threaded reply via parentMessageId',
      );
      expect(sentMessage!.repliedTo, isNotNull);
      expect(sentMessage!.repliedTo!.id, parentId);
    },
  );
}
