/// Dispatch tests for [ConversationUtils] with Core [ChatConversation] and [ChatMessage].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');

  testWidgets('ConversationUtils formats text, media, and custom conversation subtitles', (
    tester,
  ) async {
    final textConv = ChatConversation.direct(
      id: 'c1',
      peer: alice,
      updatedAt: DateTime(2026),
      lastMessage: TextMessage(
        id: 'm1',
        localId: 'm1',
        conversationId: 'c1',
        sender: alice,
        createdAt: DateTime(2026),
        text: 'Hello team',
      ),
    );
    final pollConv = ChatConversation.direct(
      id: 'c2',
      peer: alice,
      updatedAt: DateTime(2026),
      lastMessage: CustomMessage(
        id: 'm2',
        localId: 'm2',
        conversationId: 'c2',
        sender: alice,
        createdAt: DateTime(2026),
        kind: ExtensionType.extensionPoll,
        data: const {'question': 'Lunch?'},
      ),
    );

    late String textSub;
    late String pollSub;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) {
            textSub = ConversationUtils.getLastConversationMessage(textConv, context);
            pollSub = ConversationUtils.getLastConversationMessage(pollConv, context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(textSub, 'Hello team');
    expect(pollSub, isNotEmpty);
  });
}
