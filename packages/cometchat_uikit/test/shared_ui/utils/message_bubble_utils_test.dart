/// Tests for [MessageUtils] bubble rendering with Core [ChatMessage].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');

  testWidgets('MessageUtils builds bubble for Core TextMessage', (tester) async {
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hello ConvoKit',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageTemplateUtils.buildDefaultBubbleContent(
              context,
              msg,
              alignment: BubbleAlignment.left,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Hello ConvoKit'), findsOneWidget);
  });
}
