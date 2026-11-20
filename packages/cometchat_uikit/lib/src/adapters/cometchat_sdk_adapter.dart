/// Internal adapter keeping CometChat SDK static calls centralized behind adapters.
library;

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

class CometChatSdkAdapter {
  static Future<cc.Conversation?> getConversation(
    String conversationWith,
    String conversationType, {
    void Function(cc.Conversation)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) {
    return cc.CometChat.getConversation(
      conversationWith,
      conversationType,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Future<cc.User?> getLoggedInUser({
    void Function(cc.User?)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getLoggedInUser(onSuccess: onSuccess, onError: onError);

  static Future<void> markAsDelivered(
    cc.BaseMessage message, {
    void Function(dynamic result)? onSuccess,
    void Function(cc.CometChatException exception)? onError,
  }) {
    return cc.CometChat.markAsDelivered(
      message,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static bool isPinConversationEnabled() =>
      cc.CometChat.isPinConversationEnabled();

  static int? getPinnedConversationsLimit() =>
      cc.CometChat.getPinnedConversationsLimit();

  static Future<cc.Conversation?> pinConversation(
    String conversationId,
    String conversationType, {
    void Function(cc.Conversation)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) {
    return cc.CometChat.pinConversation(
      conversationId,
      conversationType,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Future<cc.Conversation?> unpinConversation(
    String conversationId,
    String conversationType, {
    void Function(cc.Conversation)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) {
    return cc.CometChat.unpinConversation(
      conversationId,
      conversationType,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Future<cc.User?> getUser(
    String uid, {
    void Function(cc.User)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getUser(uid, onSuccess: onSuccess, onError: onError);

  static Future<Map<String, dynamic>?> blockUser(
    List<String> uids, {
    void Function(Map<String, dynamic>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.blockUser(uids, onSuccess: onSuccess, onError: onError);

  static Future<Map<String, dynamic>?> unblockUser(
    List<String> uids, {
    void Function(Map<String, dynamic>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.unblockUser(uids, onSuccess: onSuccess, onError: onError);

  static Future<cc.Group?> getGroup(
    String guid, {
    void Function(cc.Group)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getGroup(guid, onSuccess: onSuccess, onError: onError);

  static Future<cc.Group?> joinGroup(
    String guid,
    String groupType, {
    String? password,
    void Function(cc.Group)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.joinGroup(
        guid,
        groupType,
        password: password ?? '',
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<void> leaveGroup(
    String guid, {
    void Function(String)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.leaveGroup(guid, onSuccess: onSuccess, onError: onError);

  static Future<Map<String?, String?>?> addMembersToGroup({
    required String guid,
    required List<cc.GroupMember> groupMembers,
    void Function(Map<String?, String?>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.addMembersToGroup(
        guid: guid,
        groupMembers: groupMembers,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<String?> kickGroupMember({
    required String guid,
    required String uid,
    void Function(String)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.kickGroupMember(
        guid: guid,
        uid: uid,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<String?> banGroupMember({
    required String guid,
    required String uid,
    void Function(String)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.banGroupMember(
        guid: guid,
        uid: uid,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<String?> updateGroupMemberScope({
    required String guid,
    required String uid,
    required String scope,
    void Function(String)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.updateGroupMemberScope(
        guid: guid,
        uid: uid,
        scope: scope,
        onSuccess: onSuccess,
        onError: onError,
      );

  static void addMessageListener(String id, cc.MessageListener listener) =>
      cc.CometChat.addMessageListener(id, listener);

  static void removeMessageListener(String id) =>
      cc.CometChat.removeMessageListener(id);

  static void addUserListener(String id, cc.UserListener listener) =>
      cc.CometChat.addUserListener(id, listener);

  static void removeUserListener(String id) =>
      cc.CometChat.removeUserListener(id);

  static void addGroupListener(String id, cc.GroupListener listener) =>
      cc.CometChat.addGroupListener(id, listener);

  static void removeGroupListener(String id) =>
      cc.CometChat.removeGroupListener(id);

  static void addConversationListener(
    String id,
    cc.ConversationListener listener,
  ) =>
      cc.CometChat.addConversationListener(id, listener);

  static void removeConversationListener(String id) =>
      cc.CometChat.removeConversationListener(id);

  static void addConnectionListener(
    String id,
    cc.ConnectionListener listener,
  ) =>
      cc.CometChat.addConnectionListener(id, listener);

  static void removeConnectionListener(String id) =>
      cc.CometChat.removeConnectionListener(id);
}
