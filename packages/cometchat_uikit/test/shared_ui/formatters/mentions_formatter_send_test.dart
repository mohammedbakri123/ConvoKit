/// Pre-send mention substitution tests for [CometChatMentionsFormatter].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');

  testWidgets('handlePreMessageSend returns immutable ChatMessage with mentions', (
    tester,
  ) async {
    final formatter = CometChatMentionsFormatter();
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hello world',
    );

    late ChatMessage result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            result = formatter.handlePreMessageSend(context, msg);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(result, isA<TextMessage>());
    expect((result as TextMessage).text, 'Hello world');
    expect(CometChatMentionsFormatter.getMentionedUsersFor(result), isEmpty);
  });
}
