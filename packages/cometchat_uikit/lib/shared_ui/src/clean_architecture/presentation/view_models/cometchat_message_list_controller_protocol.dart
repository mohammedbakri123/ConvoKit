import '../../../../convokit_uikit_shared.dart';
import 'package:flutter/widgets.dart';

abstract class ConvoKitMessageListControllerProtocol
    extends CometChatSearchListControllerProtocol<ChatMessage> {
  Map<String, CometChatMessageTemplate> getTemplateMap();
  ScrollController getScrollController();
  int? getParentMessageId();
  ChatGroup? getGroup();
  ChatUser? getUser();
  BuildContext getCurrentContext();
  String getConversationId();
  void initializeHeaderAndFooterView();
  void addMessage(ChatMessage message);

  void updateMessageWithMuid(ChatMessage message);

  void deleteMessage(ChatMessage message);

  void updateMessageThreadCount(int parentMessageId);
}
