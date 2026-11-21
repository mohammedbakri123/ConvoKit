import '../../../../convokit_uikit_shared.dart';

mixin ConvoKitConversationsControllerProtocol
    implements CometChatListProtocol<ChatConversation> {
  void updateUserStatus(ChatUser user, String status);

  void deleteConversation(ChatConversation conversation);

  void resetUnreadCount(ChatMessage message);

  void updateLastMessage(ChatMessage message);

  void updateGroup(ChatGroup group);

  void removeGroup(String guid);

  void updateLastMessageOnEdited(ChatMessage message);

  void refreshSingleConversation(
    ChatMessage message,
    bool isActionMessage, {
    bool? remove,
  });

  ///Update the conversation with new conversation Object matched according to conversation id ,  if not matched inserted at top
  void updateConversation(ChatConversation conversation);

  void setReceipts(dynamic receipt);

  void setTypingIndicator(
    dynamic typingIndicator,
    bool isTypingStarted,
  );

  void deleteConversationFromIndex(int index);

  void playNotificationSound(ChatMessage message);

  bool getHideThreadIndicator(ChatConversation conversation);

  bool getHideReceipt(ChatConversation conversation, bool? disableReadReceipt);
}
