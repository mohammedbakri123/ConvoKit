import 'package:convokit/src/core/models/models.dart';
import '../../../core/utils/ui_event_handler.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/interactive_message/form_message.dart';
import '../../../data/models/interactive_message/card_message.dart';
import '../../../data/models/interactive_message/scheduler_message.dart';
import '../../../data/models/interactive_message/custom_interactive_message.dart';

///Listener class for [ConvoKitMessageList]

enum LiveReactionType { liveReaction }

mixin ConvoKitMessageEventListener implements UIEventHandler {
  //---composer events---
  //event for message sent by logged-in user
  void ccMessageSent(ChatMessage message, MessageStatus messageStatus) {}

  //---message list events---
  //event for message edited by logged-in user
  void ccMessageEdited(ChatMessage message, MessageEditStatus status) {}

  //event for message deleted by logged-in user
  void ccMessageDeleted(ChatMessage message, EventStatus messageStatus) {}

  //event for message read by logged-in user
  void ccMessageRead(ChatMessage message) {}

  //event for the logged-in user following/unfollowing a thread from a kit
  //surface; default no-op so existing listeners are unaffected
  void ccThreadSubscriptionChanged(int parentMessageId, bool subscribed) {}

  //Pin & Save events for actions taken by the logged-in user from a kit
  //surface; [message] carries the full updated object. Default no-ops so
  //existing listeners are unaffected.
  void ccMessagePinned(ChatMessage message) {}

  void ccMessageUnpinned(ChatMessage message) {}

  void ccMessageSaved(ChatMessage message) {}

  void ccMessageUnsaved(ChatMessage message) {}

  //event for transient message sent by logged-in user
  void ccLiveReaction(String reaction) {}

  //event for forwarding message by logged-in user
  void ccMessageForwarded(
    ChatMessage message,
    List<ChatUser>? usersSent,
    List<ChatGroup>? groupsSent,
    MessageStatus status,
  ) {}

  //event for replying to a message by logged-in user
  void ccReplyToMessage(ChatMessage message) {}

  //event for forwarding message by logged-in user
  void onTextMessageReceived(TextMessage textMessage) {}

  //event for forwarding message by logged-in user
  void onMediaMessageReceived(MediaMessage mediaMessage) {}

  //event for forwarding message by logged-in user
  void onCustomMessageReceived(CustomMessage customMessage) {}

  //event for on transient message received
  void onTypingStarted(dynamic typingIndicator) {}

  //event for on transient message received
  void onTypingEnded(dynamic typingIndicator) {}

  //event for on transient message received
  void onMessagesDelivered(dynamic messageReceipt) {}

  //event for on transient message received
  void onMessagesRead(dynamic messageReceipt) {}

  //event for on transient message received
  void onMessageEdited(ChatMessage message) {}

  //event for on transient message received
  void onMessageDeleted(ChatMessage message) {}

  //event for on transient message received
  void onTransientMessageReceived(dynamic message) {}

  //event for forwarding message by logged-in user
  void onFormMessageReceived(FormMessage formMessage) {}

  //event for forwarding message by logged-in user
  void onCardMessageReceived(CardMessage cardMessage) {}

  //event for forwarding message by logged-in user
  void onCustomInteractiveMessageReceived(
    CustomInteractiveMessage customInteractiveMessage,
  ) {}

  //event for completion of interaction goals
  void onInteractionGoalCompleted(dynamic receipt) {}

  //event for listening to meeting message events
  void onSchedulerMessageReceived(SchedulerMessage schedulerMessage) {}

  ///[onMessageReactionAdded] is called when a reaction is added to a message
  void onMessageReactionAdded(dynamic reactionEvent) {}

  ///[onMessageReactionRemoved] is called when a reaction is removed from a message
  void onMessageReactionRemoved(dynamic reactionEvent) {}

  //event for all messages delivered to all
  void onMessagesDeliveredToAll(dynamic messageReceipt) {}

  //event for all messages read by all
  void onMessagesReadByAll(dynamic messageReceipt) {}

  //event for on transient message received
  void onMessageModerated(ChatMessage message) {}
}
