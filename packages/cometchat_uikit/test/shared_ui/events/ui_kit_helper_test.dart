/// Tests for [ConvoKitUIKitHelper] event forwarding with Core models.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

class _GroupRecorder with ConvoKitGroupEventListener {
  ChatGroup? created;
  ChatGroup? joined;

  @override
  void ccGroupCreated(ChatGroup group) => created = group;

  @override
  void ccGroupMemberJoined(ChatUser joinedUser, ChatGroup joinedGroup) =>
      joined = joinedGroup;
}

void main() {
  const user = ChatUser(id: 'u1', name: 'Alice');
  const group = ChatGroup(id: 'g1', name: 'Team', type: GroupType.public);

  test('ConvoKitUIKitHelper forwards group created and joined events', () {
    final rec = _GroupRecorder();
    ConvoKitGroupEvents.addGroupsListener('helper_test', rec);
    addTearDown(() => ConvoKitGroupEvents.removeGroupsListener('helper_test'));

    ConvoKitUIKitHelper.onGroupCreated(group);
    ConvoKitUIKitHelper.onGroupMemberJoined(user, group);
    expect(rec.created, group);
    expect(rec.joined, group);
  });
}
