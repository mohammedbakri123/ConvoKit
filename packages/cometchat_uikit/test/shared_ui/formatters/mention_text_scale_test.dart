/// Mention formatter text-scale rendering tests (Core models).
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mentions render cleanly at 2.0 text scale', (tester) async {
    const alice = ChatUser(id: 'u1', name: 'Alice');
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hi <@uid:u1>!',
    );
    CometChatMentionsFormatter.setMentionedUsersFor(msg, const [alice]);
    final formatter = CometChatMentionsFormatter(message: msg);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final spans = FormatterUtils.buildTextSpan(
                  msg.text,
                  [formatter],
                  context,
                  BubbleAlignment.left,
                );
                return RichText(text: TextSpan(children: spans));
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byType(RichText), findsWidgets);
    expect(find.text('@Alice'), findsOneWidget);
  });
}
