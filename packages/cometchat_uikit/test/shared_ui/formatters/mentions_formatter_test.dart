/// Core unit tests for [CometChatMentionsFormatter].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');

  test('getMentionedUserName returns name when present and empty otherwise', () {
    final msg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Hi <@uid:u1>',
    );
    CometChatMentionsFormatter.setMentionedUsersFor(msg, const [alice]);
    expect(CometChatMentionsFormatter.getMentionedUserName('u1', msg), 'Alice');
    expect(CometChatMentionsFormatter.getMentionedUserName('u99', msg), '');
  });
}
