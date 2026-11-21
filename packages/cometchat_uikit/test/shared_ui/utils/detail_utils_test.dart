/// Tests for [DetailUtils] with Core [ChatUser], [ChatGroup], and [ChatMember].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core group and member models carry expected roles and types', () {
    const owner = ChatUser(id: 'u1', name: 'Owner');
    const member = ChatMember(user: owner, role: GroupRole.owner);
    const group = ChatGroup(
      id: 'g1',
      name: 'Core',
      type: GroupType.private,
      memberCount: 1,
      members: [member],
    );
    expect(group.id, 'g1');
    expect(group.members?.first.role, GroupRole.owner);
  });
}
