import 'package:flutter/material.dart';
import '../../../shared_ui/convokit_uikit_shared.dart' as ui_kit;
import '../../../shared_ui/convokit_uikit_shared.dart';
import '../clean_architecture/core/constants/enums.dart' as core_enums;

///[ConvoKitUIKitHelper] contains static methods for triggering local events
class ConvoKitUIKitHelper {
  //---------- Message Events ----------
  ///[onMessageSent] is used to inform the listeners
  ///when the logged-in user is sending a message
  static void onMessageSent(
    ChatMessage message,
    core_enums.MessageStatus messageStatus,
  ) {
    ConvoKitMessageEvents.ccMessageSent(message, messageStatus);
  }

  ///[onMessageEdited] is used to inform the listeners
  ///when the logged-in user is editing a message
  static void onMessageEdited(ChatMessage message, MessageEditStatus status) {
    ConvoKitMessageEvents.ccMessageEdited(message, status);
  }

  ///[onMessageDeleted] is used to inform the listeners
  ///when the logged-in user has deleted a message
  static void onMessageDeleted(ChatMessage message, EventStatus status) {
    ConvoKitMessageEvents.ccMessageDeleted(message, status);
  }

  ///[onMessageRead] is used to inform the listeners
  ///when the logged-in user has read a message
  static void onMessageRead(ChatMessage message) {
    ConvoKitMessageEvents.ccMessageRead(message);
  }

  ///[onLiveReaction] is used to inform the listeners
  ///when the logged-in user sends a transient message (live reaction)
  static void onLiveReaction(String reaction, String receiverId) {
    ConvoKitMessageEvents.ccLiveReaction(reaction, receiverId);
  }

  //---------- ChatUser Events ----------
  ///[onUserBlocked] is used to inform the listeners
  ///when the logged-in user blocks another user
  static void onUserBlocked(ChatUser user) {
    ConvoKitUserEvents.ccUserBlocked(user);
  }

  ///[onUserUnblocked] is used to inform the listeners
  ///when the logged-in user unblocks a blocked user
  static void onUserUnblocked(ChatUser user) {
    ConvoKitUserEvents.ccUserUnblocked(user);
  }

  ///[onMessageModerated] is used to inform the listeners
  ///when the logged-in user has moderated a message
  static void onMessageModerated(ChatMessage message) {
    ConvoKitMessageEvents.onMessageModerated(message);
  }

  //---------- ChatGroup Events ----------
  ///[onGroupCreated] is used to inform the listeners
  ///when the logged-in user creates a ChatGroup
  static void onGroupCreated(ChatGroup group) {
    ConvoKitGroupEvents.ccGroupCreated(group);
  }

  ///[onGroupDeleted] is used to inform the listeners
  ///when the logged-in user deletes a ChatGroup
  static void onGroupDeleted(ChatGroup group) {
    ConvoKitGroupEvents.ccGroupDeleted(group);
  }

  ///[onGroupLeft] is used to inform the listeners
  ///when the logged-in user leaves a ChatGroup
  static void onGroupLeft(
    ui_kit.ChatMessage message,
    ChatUser leftUser,
    ChatGroup leftGroup,
  ) {
    ConvoKitGroupEvents.ccGroupLeft(message, leftUser, leftGroup);
  }

  ///[onGroupMemberScopeChanged] is used to inform the listeners
  ///when the logged-in user changes the scope of a group member
  ///in a group
  static void onGroupMemberScopeChanged(
    ui_kit.ChatMessage message,
    ChatUser updatedUser,
    String scopeChangedTo,
    String scopeChangedFrom,
    ChatGroup group,
  ) {
    ConvoKitGroupEvents.ccGroupMemberScopeChanged(
      message,
      updatedUser,
      scopeChangedTo,
      scopeChangedFrom,
      group,
    );
  }

  ///[onGroupMemberBanned] is used to inform the listeners
  ///when the logged-in user bans a group member
  static void onGroupMemberBanned(
    ui_kit.ChatMessage message,
    ChatUser bannedUser,
    ChatUser bannedBy,
    ChatGroup bannedFrom,
  ) {
    ConvoKitGroupEvents.ccGroupMemberBanned(
      message,
      bannedUser,
      bannedBy,
      bannedFrom,
    );
  }

  ///[onGroupMemberKicked] is used to inform the listeners
  ///when the logged-in user kicks a group member from a group
  static void onGroupMemberKicked(
    ui_kit.ChatMessage message,
    ChatUser kickedUser,
    ChatUser kickedBy,
    ChatGroup kickedFrom,
  ) {
    ConvoKitGroupEvents.ccGroupMemberKicked(
      message,
      kickedUser,
      kickedBy,
      kickedFrom,
    );
  }

  ///[onGroupMemberUnbanned] is used to inform the listeners
  ///when the logged-in user unbans a banned user of a group
  static void onGroupMemberUnbanned(
    ui_kit.ChatMessage message,
    ChatUser unbannedUser,
    ChatUser unbannedBy,
    ChatGroup unbannedFrom,
  ) {
    ConvoKitGroupEvents.ccGroupMemberUnbanned(
      message,
      unbannedUser,
      unbannedBy,
      unbannedFrom,
    );
  }

  ///[onGroupMemberJoined] is used to inform the listeners
  ///when the logged-in user joins a group
  static void onGroupMemberJoined(ChatUser joinedUser, ChatGroup joinedGroup) {
    ConvoKitGroupEvents.ccGroupMemberJoined(joinedUser, joinedGroup);
  }

  ///[onGroupMemberAdded] is used to inform the listeners
  ///when the logged-in user adds users to a group
  static void onGroupMemberAdded(
    List<ChatMessage> messages,
    List<ChatUser> usersAdded,
    ChatGroup groupAddedIn,
    ChatUser addedBy,
  ) {
    ConvoKitGroupEvents.ccGroupMemberAdded(
      messages,
      usersAdded,
      groupAddedIn,
      addedBy,
    );
  }

  ///[onOwnershipChanged] is used to inform the listeners
  ///when the logged-in user transfers their ownership to some other group member
  static void onOwnershipChanged(ChatGroup group, ChatMember newOwner) {
    ConvoKitGroupEvents.ccOwnershipChanged(group, newOwner);
  }

  //---------- ChatConversation Events ----------
  ///[onConversationDeleted] is used to inform the listeners
  ///when the logged-in user deletes a conversation
  static void onConversationDeleted(ChatConversation conversation) {
    ConvoKitConversationEvents.ccConversationDeleted(conversation);
  }

  ///[onConversationUpdate] is used to inform the listeners
  ///when a conversation is updated (e.g., mark as unread)
  static void onConversationUpdate(ChatConversation conversation) {
    ConvoKitConversationEvents.ccUpdateConversation(conversation);
  }

  //---------- CometChat UI Events ----------
  ///[showPanel] used to reveal a panel above message composer
  static void showPanel(
    Map<String, dynamic>? id,
    CustomUIPosition uiPosition,
    WidgetBuilder child,
  ) {
    ConvoKitUIEvents.showPanel(id, uiPosition, child);
  }

  ///[hidePanel] used to hide the panel above message composer
  static void hidePanel(Map<String, dynamic>? id, CustomUIPosition uiPosition) {
    ConvoKitUIEvents.hidePanel(id, uiPosition);
  }

  ///[ccActiveChatChanged] used to notify if the logged-in user
  ///has moved on to a different conversation
  static void ccActiveChatChanged(
    Map<String, dynamic>? id,
    ChatMessage? lastMessage,
    ChatUser? user,
    ChatGroup? group,
    int unreadMessageCount,
  ) {
    ConvoKitUIEvents.ccActiveChatChanged(
      id,
      lastMessage,
      user,
      group,
      unreadMessageCount,
    );
  }

  ///[onOpenChat] used to open the chat conversation
  ///of a user or a group
  static void onOpenChat(ChatUser? user, ChatGroup? group) {
    ConvoKitUIEvents.openChat(user, group);
  }

  ///[ccComposeMessage] used to add replies to message composer
  ///when the logged-in user is adding a message to composer
  static void ccComposeMessage(String text, MessageEditStatus status) {
    ConvoKitUIEvents.ccComposeMessage(text, status);
  }
}
