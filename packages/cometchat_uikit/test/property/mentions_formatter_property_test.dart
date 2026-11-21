/// Property tests for [CometChatMentionsFormatter] with Core models.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getTextWithMentions substitutes <@uid:id> tokens with @name', () {
    const alice = ChatUser(id: 'u1', name: 'Alice');
    const bob = ChatUser(id: 'u2', name: 'Bob');
    final formatted = CometChatMentionsFormatter.getTextWithMentions(
      'Hi <@uid:u1> and <@uid:u2>!',
      const [alice, bob],
    );
    expect(formatted, contains('@Alice'));
    expect(formatted, contains('@Bob'));
  });

  test('getMentionedUserName resolves from Expando-attached mention list', () {
    const alice = ChatUser(id: 'u1', name: 'Alice');
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hello <@uid:u1>',
    );
    CometChatMentionsFormatter.setMentionedUsersFor(msg, const [alice]);
    expect(CometChatMentionsFormatter.getMentionedUserName('u1', msg), 'Alice');
  });
}
