/// In-app UI event bus dispatch tests (SDK-free Core models).
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

class _UserRecorder with ConvoKitUserEventListener {
  ChatUser? blocked;
  ChatUser? unblocked;

  @override
  void ccUserBlocked(ChatUser user) => blocked = user;

  @override
  void ccUserUnblocked(ChatUser user) => unblocked = user;
}

class _GroupRecorder with ConvoKitGroupEventListener {
  ChatGroup? created;
  ChatGroup? deleted;

  @override
  void ccGroupCreated(ChatGroup group) => created = group;

  @override
  void ccGroupDeleted(ChatGroup group) => deleted = group;
}

class _ConvRecorder with ConvoKitConversationEventListener {
  ChatConversation? deleted;
  ChatConversation? updated;

  @override
  void ccConversationDeleted(ChatConversation conversation) =>
      deleted = conversation;

  @override
  void ccUpdateConversation(ChatConversation conversation) =>
      updated = conversation;
}

void main() {
  const user = ChatUser(id: 'u1', name: 'Alice');
  const group = ChatGroup(id: 'g1', name: 'Team', type: GroupType.public);

  test('ConvoKitUserEvents dispatches to registered listeners', () {
    final rec = _UserRecorder();
    ConvoKitUserEvents.addUsersListener('test_u', rec);
    addTearDown(() => ConvoKitUserEvents.removeUsersListener('test_u'));

    ConvoKitUserEvents.ccUserBlocked(user);
    ConvoKitUserEvents.ccUserUnblocked(user);
    expect(rec.blocked, user);
    expect(rec.unblocked, user);
  });

  test('ConvoKitGroupEvents dispatches to registered listeners', () {
    final rec = _GroupRecorder();
    ConvoKitGroupEvents.addGroupsListener('test_g', rec);
    addTearDown(() => ConvoKitGroupEvents.removeGroupsListener('test_g'));

    ConvoKitGroupEvents.ccGroupCreated(group);
    ConvoKitGroupEvents.ccGroupDeleted(group);
    expect(rec.created, group);
    expect(rec.deleted, group);
  });

  test('ConvoKitConversationEvents dispatches to registered listeners', () {
    final rec = _ConvRecorder();
    ConvoKitConversationEvents.addConversationListListener('test_c', rec);
    addTearDown(
      () => ConvoKitConversationEvents.removeConversationListListener('test_c'),
    );

    final conv = ChatConversation.direct(
      id: 'c1',
      peer: user,
      updatedAt: DateTime(2026),
    );
    ConvoKitConversationEvents.ccUpdateConversation(conv);
    ConvoKitConversationEvents.ccConversationDeleted(conv);
    expect(rec.updated, conv);
    expect(rec.deleted, conv);
  });
}
