// ignore_for_file: public_member_api_docs
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

  static void addCallListener(String id, cc.CallListener listener) =>
      cc.CometChat.addCallListener(id, listener);

  static void removeCallListener(String id) =>
      cc.CometChat.removeCallListener(id);

  static void addAIAssistantListener(
    String id,
    cc.AIAssistantListener listener,
  ) =>
      cc.CometChat.addAIAssistantListener(id, listener);

  static void removeAIAssistantListener(String id) =>
      cc.CometChat.removeAIAssistantListener(id);

  static Future<dynamic> markConversationAsRead(
    String conversationWith,
    String conversationType, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.markConversationAsRead(
        conversationWith,
        conversationType,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<cc.BaseMessage?> addReaction(
    int messageId,
    String reaction, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.addReaction(
        messageId,
        reaction,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.BaseMessage?> removeReaction(
    int messageId,
    String reaction, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.removeReaction(
        messageId,
        reaction,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.Conversation?> markMessageAsUnread(
    cc.BaseMessage message, {
    void Function(cc.Conversation)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.markMessageAsUnread(
        message,
        onSuccess: onSuccess,
        onError: onError,
      );

  static bool isPinMessageEnabled() => cc.CometChat.isPinMessageEnabled();

  static bool isSaveMessageEnabled() => cc.CometChat.isSaveMessageEnabled();

  static int? getPinnedMessagesLimit() => cc.CometChat.getPinnedMessagesLimit();

  static int? getSavedMessagesLimit() => cc.CometChat.getSavedMessagesLimit();

  static Future<cc.BaseMessage?> pinMessage(
    int messageId, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.pinMessage(messageId, onSuccess: onSuccess, onError: onError);

  static Future<cc.BaseMessage?> unpinMessage(
    int messageId, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.unpinMessage(
        messageId,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.BaseMessage?> saveMessage(
    int messageId, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.saveMessage(messageId, onSuccess: onSuccess, onError: onError);

  static Future<cc.BaseMessage?> unsaveMessage(
    int messageId, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.unsaveMessage(
        messageId,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<dynamic> subscribeToThread(
    int messageId, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.subscribeToThread(
        messageId,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<dynamic> unsubscribeFromThread(
    int messageId, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.unsubscribeFromThread(
        messageId,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<bool?> isExtensionEnabled(
    String slug, {
    void Function(bool)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.isExtensionEnabled(
        slug,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<dynamic> callExtension(
    String slug,
    String requestType,
    String url,
    dynamic body, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.callExtension(
        slug,
        requestType,
        url,
        body,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<List<cc.FlagReason>?> getFlagReasons({
    void Function(List<cc.FlagReason>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getFlagReasons(onSuccess: onSuccess, onError: onError);

  static Future<dynamic> flagMessage(
    int messageId,
    cc.FlagDetail detail, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.flagMessage(
        messageId,
        detail,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<void> deleteMessage(
    int messageId, {
    Function? onSuccess,
    Function? onError,
  }) =>
      cc.CometChat.deleteMessage(
        messageId,
        onSuccess: onSuccess != null ? (dynamic res) => onSuccess(res) : null,
        onError: onError != null
            ? (cc.CometChatException err) => onError(err)
            : null,
      );

  static Future<cc.TextMessage?> sendMessage(
    cc.TextMessage message, {
    void Function(cc.TextMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.sendMessage(message, onSuccess: onSuccess, onError: onError);

  static Future<cc.MediaMessage?> sendMediaMessage(
    cc.MediaMessage message, {
    void Function(cc.MediaMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.sendMediaMessage(
        message,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.CustomMessage?> sendCustomMessage(
    cc.CustomMessage message, {
    void Function(cc.CustomMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.sendCustomMessage(
        message,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.BaseMessage?> editMessage(
    cc.BaseMessage message, {
    void Function(cc.BaseMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.editMessage(message, onSuccess: onSuccess, onError: onError);

  static void startTyping({
    required String receiverUid,
    required String receiverType,
  }) =>
      cc.CometChat.startTyping(
        receiverUid: receiverUid,
        receiverType: receiverType,
      );

  static void endTyping({
    required String receiverUid,
    required String receiverType,
  }) =>
      cc.CometChat.endTyping(
        receiverUid: receiverUid,
        receiverType: receiverType,
      );

  static cc.UploadFileRequest createUploadFileRequest(
    String receiverId,
    String receiverType,
  ) =>
      cc.CometChat.createUploadFileRequest(receiverId, receiverType);

  static int getMaxAttachmentCount() => cc.CometChat.getMaxAttachmentCount();

  static int getMaxAttachmentSize() => cc.CometChat.getMaxAttachmentSize();

  static Future<dynamic> markAsInteracted(
    int messageId,
    String interactionGoal, {
    void Function(dynamic)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.markAsInteracted(
        messageId,
        interactionGoal,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.InteractiveMessage?> sendInteractiveMessage(
    cc.InteractiveMessage message, {
    void Function(cc.InteractiveMessage)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.sendInteractiveMessage(
        message,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<void> setSource(
    String version,
    String platform,
    String type,
  ) =>
      cc.CometChat.setSource(version, platform, type);

  static void setIntegrationSource(String source) =>
      cc.CometChat.setIntegrationSource(source);

  static Future<cc.User?> createUser(
    cc.User user,
    String apiKey, {
    void Function(cc.User)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.createUser(
        user,
        apiKey,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.User?> updateUser(
    cc.User user,
    String apiKey, {
    void Function(cc.User)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.updateUser(
        user,
        apiKey,
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<cc.ConversationUpdateSettings?> getConversationUpdateSettings({
    void Function(cc.ConversationUpdateSettings)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getConversationUpdateSettings(
        onSuccess: onSuccess,
        onError: onError,
      );

  static Future<void> getConversationStarter(
    String conversationWith,
    String conversationType, {
    dynamic configuration,
    void Function(List<String>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getConversationStarter(
        conversationWith,
        conversationType,
        configuration: configuration,
        onSuccess: onSuccess != null ? (res) => onSuccess(res) : (res) {},
        onError: onError != null ? (err) => onError(err) : (err) {},
      );

  static Future<void> getConversationSummary(
    String conversationWith,
    String conversationType, {
    dynamic configuration,
    void Function(String)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getConversationSummary(
        conversationWith,
        conversationType,
        configuration: configuration,
        onSuccess: onSuccess != null ? (res) => onSuccess(res) : (res) {},
        onError: onError != null ? (err) => onError(err) : (err) {},
      );

  static Future<void> getSmartReplies(
    String conversationWith,
    String conversationType, {
    dynamic configuration,
    void Function(Map<String, String>)? onSuccess,
    void Function(cc.CometChatException)? onError,
  }) =>
      cc.CometChat.getSmartReplies(
        conversationWith,
        conversationType,
        configuration: configuration,
        onSuccess: onSuccess != null ? (res) => onSuccess(res) : (res) {},
        onError: onError != null ? (err) => onError(err) : (err) {},
      );
}
