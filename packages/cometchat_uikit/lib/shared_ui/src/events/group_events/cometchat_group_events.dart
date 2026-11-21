import '../../../convokit_uikit_shared.dart';

class ConvoKitGroupEvents {
  static Map<String, ConvoKitGroupEventListener> groupsListener = {};

  static void addGroupsListener(
    String listenerId,
    ConvoKitGroupEventListener listenerClass,
  ) {
    groupsListener[listenerId] = listenerClass;
  }

  static void removeGroupsListener(String listenerId) {
    groupsListener.remove(listenerId);
  }

  static void ccGroupCreated(ChatGroup group) {
    groupsListener.forEach((key, value) {
      value.ccGroupCreated(group);
    });
  }

  static void ccGroupDeleted(ChatGroup group) {
    groupsListener.forEach((key, value) {
      value.ccGroupDeleted(group);
    });
  }

  static void ccGroupLeft(ChatMessage message, ChatUser leftUser, ChatGroup leftGroup) {
    groupsListener.forEach((key, value) {
      value.ccGroupLeft(message, leftUser, leftGroup);
    });
  }

  static void ccGroupMemberScopeChanged(
    ChatMessage message,
    ChatUser updatedUser,
    String scopeChangedTo,
    String scopeChangedFrom,
    ChatGroup group,
  ) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberScopeChanged(
        message,
        updatedUser,
        scopeChangedTo,
        scopeChangedFrom,
        group,
      );
    });
  }

  static void ccGroupMemberBanned(
    ChatMessage message,
    ChatUser bannedUser,
    ChatUser bannedBy,
    ChatGroup bannedFrom,
  ) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberBanned(message, bannedUser, bannedBy, bannedFrom);
    });
  }

  static void ccGroupMemberKicked(
    ChatMessage message,
    ChatUser kickedUser,
    ChatUser kickedBy,
    ChatGroup kickedFrom,
  ) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberKicked(message, kickedUser, kickedBy, kickedFrom);
    });
  }

  static void ccGroupMemberUnbanned(
    ChatMessage message,
    ChatUser unbannedUser,
    ChatUser unbannedBy,
    ChatGroup unbannedFrom,
  ) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberUnbanned(
        message,
        unbannedUser,
        unbannedBy,
        unbannedFrom,
      );
    });
  }

  static void ccGroupMemberJoined(ChatUser joinedUser, ChatGroup joinedGroup) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberJoined(joinedUser, joinedGroup);
    });
  }

  static void ccGroupMemberAdded(
    List<ChatMessage> messages,
    List<ChatUser> usersAdded,
    ChatGroup groupAddedIn,
    ChatUser addedBy,
  ) {
    groupsListener.forEach((key, value) {
      value.ccGroupMemberAdded(messages, usersAdded, groupAddedIn, addedBy);
    });
  }

  static void ccOwnershipChanged(ChatGroup group, ChatMember newOwner) {
    groupsListener.forEach((key, value) {
      value.ccOwnershipChanged(group, newOwner);
    });
  }
}
