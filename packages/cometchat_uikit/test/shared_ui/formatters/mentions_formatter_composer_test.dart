/// Composer mention suggestion & formatting tests (SDK-free Core models).
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice');
  const group = ChatGroup(
    id: 'g1',
    name: 'Engineering',
    type: GroupType.public,
  );

  test('formatter initializes trackingCharacter and pattern defaults', () {
    final formatter = CometChatMentionsFormatter(user: alice, group: group);
    formatter.init();
    expect(formatter.trackingCharacter, '@');
    expect(formatter.pattern, isNotNull);
  });

  test('getTextWithMentions replaces mention tags cleanly', () {
    final out = CometChatMentionsFormatter.getTextWithMentions(
      'Ping <@uid:u1>',
      const [alice],
    );
    expect(out, 'Ping @Alice');
  });
}
