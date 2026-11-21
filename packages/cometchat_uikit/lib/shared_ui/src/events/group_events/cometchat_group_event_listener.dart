import '../../../convokit_uikit_shared.dart';

///Events can be triggered by ChatGroup Module
///e.g. Clicking on a particular group. All public-facing components in each module will trigger events.
mixin ConvoKitGroupEventListener implements UIEventHandler {
  ///This will get triggered when a group is created successfully
  void ccGroupCreated(ChatGroup group) {}

  ///This will get triggered when a group is deleted successfully
  void ccGroupDeleted(ChatGroup group) {}

  ///This will get triggered when logged in user leaves the group
  void ccGroupLeft(ChatMessage message, ChatUser leftUser, ChatGroup leftGroup) {}

  ///This will get triggered when group member's scope is changed by logged in user
  void ccGroupMemberScopeChanged(
    ChatMessage message,
    ChatUser updatedUser,
    String scopeChangedTo,
    String scopeChangedFrom,
    ChatGroup group,
  ) {}

  ///This will get triggered when group member is banned from the group by logged in user
  void ccGroupMemberBanned(
    ChatMessage message,
    ChatUser bannedUser,
    ChatUser bannedBy,
    ChatGroup bannedFrom,
  ) {}

  ///This will get triggered when group member is kicked from the group by logged in user
  void ccGroupMemberKicked(
    ChatMessage message,
    ChatUser kickedUser,
    ChatUser kickedBy,
    ChatGroup kickedFrom,
  ) {}

  ///This will get triggered when a banned group member is unbanned from group by logged in user
  void ccGroupMemberUnbanned(
    ChatMessage message,
    ChatUser unbannedUser,
    ChatUser unbannedBy,
    ChatGroup unbannedFrom,
  ) {}

  ///This will get triggered when logged in user is joined successfully
  void ccGroupMemberJoined(ChatUser joinedUser, ChatGroup joinedGroup) {}

  ///This will get triggered when a member is added by logged in user
  void ccGroupMemberAdded(
    List<ChatMessage> messages,
    List<ChatUser> usersAdded,
    ChatGroup groupAddedIn,
    ChatUser addedBy,
  ) {}

  ///This will get triggered when ownership is changed by logged in user
  void ccOwnershipChanged(ChatGroup group, ChatMember newOwner) {}
}
