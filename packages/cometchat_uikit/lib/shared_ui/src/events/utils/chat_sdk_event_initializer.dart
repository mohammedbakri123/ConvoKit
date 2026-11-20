import 'package:convokit/src/adapters/cometchat_sdk_adapter.dart';
import '../../../convokit_uikit_shared.dart';
import '../../clean_architecture/data/models/interactive_message/card_message.dart'
    as legacy;

class ChatSDKEventInitializer with MessageListener {
  //Do not use this id, its reserved for cometchat own structure
  final String _listenerId = "__CometChatConstantListenerID__";

  ChatSDKEventInitializer() {
    CometChatSdkAdapter.addMessageListener(_listenerId, this);
  }

  @override
  void onTextMessageReceived(TextMessage textMessage) {
    ConvoKitMessageEvents.onTextMessageReceived(textMessage);
  }

  @override
  void onMediaMessageReceived(MediaMessage mediaMessage) {
    ConvoKitMessageEvents.onMediaMessageReceived(mediaMessage);
  }

  @override
  void onCustomMessageReceived(CustomMessage customMessage) {
    ConvoKitMessageEvents.onCustomMessageReceived(customMessage);
  }

  @override
  void onTypingStarted(TypingIndicator typingIndicator) {
    ConvoKitMessageEvents.onTypingStarted(typingIndicator);
  }

  @override
  void onTypingEnded(TypingIndicator typingIndicator) {
    ConvoKitMessageEvents.onTypingEnded(typingIndicator);
  }

  @override
  void onMessagesDelivered(MessageReceipt messageReceipt) {
    ConvoKitMessageEvents.onMessagesDelivered(messageReceipt);
  }

  @override
  void onMessagesRead(MessageReceipt messageReceipt) {
    ConvoKitMessageEvents.onMessagesRead(messageReceipt);
  }

  @override
  void onMessageEdited(BaseMessage message) {
    InteractiveMessage? interactiveMessage;

    if (message.category == MessageCategoryConstants.interactive) {
      interactiveMessage =
          InteractiveMessageUtils.getSpecificMessageFromInteractiveMessage(
            message as InteractiveMessage,
          );
    }

    ConvoKitMessageEvents.onMessageEdited(interactiveMessage ?? message);
  }

  @override
  void onMessageDeleted(BaseMessage message) {
    InteractiveMessage? interactiveMessage;

    if (message.category == MessageCategoryConstants.interactive) {
      interactiveMessage =
          InteractiveMessageUtils.getSpecificMessageFromInteractiveMessage(
            message as InteractiveMessage,
          );
    }

    ConvoKitMessageEvents.onMessageDeleted(interactiveMessage ?? message);
  }

  @override
  void onTransientMessageReceived(TransientMessage message) {
    ConvoKitMessageEvents.onTransientMessageReceived(message);
  }

  @override
  void onInteractiveMessageReceived(InteractiveMessage message) {
    if (message.type == MessageTypeConstants.form) {
      ConvoKitMessageEvents.onFormMessageReceived(
        FormMessage.fromInteractiveMessage(message),
      );
    } else if (message.type == MessageTypeConstants.card) {
      ConvoKitMessageEvents.onCardMessageReceived(
        legacy.CardMessage.fromInteractiveMessage(message),
      );
    } else if (message.type == MessageTypeConstants.scheduler) {
      ConvoKitMessageEvents.onSchedulerMessageReceived(
        SchedulerMessage.fromInteractiveMessage(message),
      );
    } else {
      ConvoKitMessageEvents.onCustomInteractiveMessageReceived(
        CustomInteractiveMessage.fromInteractiveMessage(message),
      );
    }
  }

  @override
  void onInteractionGoalCompleted(InteractionReceipt receipt) {
    ConvoKitMessageEvents.onInteractionGoalCompleted(receipt);
  }

  @override
  void onMessageReactionAdded(ReactionEvent reactionEvent) {
    ConvoKitMessageEvents.onMessageReactionAdded(reactionEvent);
  }

  @override
  void onMessageReactionRemoved(ReactionEvent reactionEvent) {
    ConvoKitMessageEvents.onMessageReactionRemoved(reactionEvent);
  }

  @override
  void onMessagesDeliveredToAll(MessageReceipt messageReceipt) {
    ConvoKitMessageEvents.onMessagesDeliveredToAll(messageReceipt);
  }

  @override
  void onMessagesReadByAll(MessageReceipt messageReceipt) {
    ConvoKitMessageEvents.onMessagesReadByAll(messageReceipt);
  }

  @override
  void onMessageModerated(BaseMessage message) {
    ConvoKitMessageEvents.onMessageModerated(message);
  }
}
