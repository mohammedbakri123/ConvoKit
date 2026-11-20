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
