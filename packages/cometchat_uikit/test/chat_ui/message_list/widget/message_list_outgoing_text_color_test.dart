import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  testWidgets(
    'outgoingTextColor overrides outgoing bubble text color and defaults to white',
    (tester) async {
      const darkText = Color(0xFF111B21);
      final fake = FakeChatBackend(seededMessageCount: 2);
      final convId = fake.conversationsList.first.id;
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(),
      );

      Widget buildApp({ConvoKitMessageListStyle? style}) {
        return MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: ConvoKitScope(
            kit: kit,
            child: Scaffold(
              body: ConvoKitMessageList(
                conversationId: convId,
                style: style,
              ),
            ),
          ),
        );
      }

      // Default behavior (outgoingTextColor == null): outgoing text is white.
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final defaultOutgoingText = tester.widget<Text>(find.text('Message #0'));
      expect(defaultOutgoingText.style?.color, Colors.white);

      // With outgoingTextColor set: outgoing text renders in darkText,
      // while incoming text keeps its theme color.
      await tester.pumpWidget(
        buildApp(
          style: const ConvoKitMessageListStyle(
            outgoingTextColor: darkText,
            outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
              backgroundColor: Color(0xFFDCF8C6),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customOutgoingText = tester.widget<Text>(find.text('Message #0'));
      expect(customOutgoingText.style?.color, darkText);

      final incomingText = tester.widget<Text>(find.text('Message #1'));
      expect(incomingText.style?.color, isNot(darkText));

      // Verify getDeleteMessageBubble respects outgoingTextColor and defaults
      // to white when omitted.
      final sampleMessage = fake.messagesByConversation[convId]!.first;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  key: const Key('deleted_default'),
                  builder: (context) =>
                      MessageTemplateUtils.getDeleteMessageBubble(
                        sampleMessage,
                        context,
                        BubbleAlignment.right,
                      ),
                ),
                Builder(
                  key: const Key('deleted_custom'),
                  builder: (context) =>
                      MessageTemplateUtils.getDeleteMessageBubble(
                        sampleMessage,
                        context,
                        BubbleAlignment.right,
                        outgoingTextColor: darkText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final defaultDeletedText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('deleted_default')),
          matching: find.byType(Text),
        ),
      );
      expect(defaultDeletedText.style?.color, Colors.white);

      final customDeletedText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('deleted_custom')),
          matching: find.byType(Text),
        ),
      );
      expect(customDeletedText.style?.color, darkText);

      final customDeletedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('deleted_custom')),
          matching: find.byType(Icon),
        ),
      );
      expect(customDeletedIcon.color, darkText);
    },
  );
}
