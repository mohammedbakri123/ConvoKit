/// AttributedText generation tests for [CometChatMentionsFormatter].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');
  const bob = ChatUser(id: 'u2', name: 'Bob');

  testWidgets('resolves mentioned users into attributed text spans', (
    tester,
  ) async {
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hello <@uid:u1> and <@uid:u2>',
    );
    CometChatMentionsFormatter.setMentionedUsersFor(msg, const [alice, bob]);
    final formatter = CometChatMentionsFormatter(message: msg);

    late List<AttributedText> attrs;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) {
            attrs = formatter.getAttributedText(
              msg.text,
              context,
              BubbleAlignment.left,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(attrs.length, 2);
    expect(attrs.first.underlyingText, '@Alice');
    expect(attrs.last.underlyingText, '@Bob');
  });
}
