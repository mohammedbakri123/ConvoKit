/// Tests for [ConversationSubtitleUtils] with Core models.
library;

import 'package:convokit/chat_ui/src/conversations/utils/conversation_subtitle_utils.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');

  testWidgets('ConversationSubtitleUtils renders subtitle for text message', (
    tester,
  ) async {
    final conv = ChatConversation.direct(
      id: 'c1',
      peer: alice,
      updatedAt: DateTime(2026),
      lastMessage: TextMessage(
        id: 'm1',
        localId: 'm1',
        conversationId: 'c1',
        sender: alice,
        createdAt: DateTime(2026),
        text: 'See you tomorrow',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => ConversationSubtitleUtils.getConversationSubtitle(
              conv,
              context,
              const TextStyle(fontSize: 14),
              Colors.grey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RichText), findsWidgets);
  });
}
