/// Message models and states according to API-DESIGN.md §2.1.
library;

import '../../contracts/result.dart';
import 'attachment.dart';
import 'user.dart';

/// Outcome of Core's send attempts. Owned by Core; never set by events.
enum SendState { sending, sent, failed }

/// What the backend reported about a message WE sent. Only moves forward,
/// and only while sendState == sent. Set by MessageStatusChanged events.
enum DeliveryState { none, delivered, read }

sealed class ChatMessage {
  /// Server-assigned id. Null until the server confirms the message.
  final String? id;

  /// Client-generated id, always present. The idempotency key.
  final String localId;

  final String conversationId;
  final ChatUser sender;

  /// Client time while pending; server time after confirmation.
  final DateTime createdAt;
  final DateTime? serverCreatedAt;

  final SendState sendState;
  final DeliveryState deliveryState;

  /// Set when sendState == failed; null otherwise. Drives the retry UI.
  final ChatError? failure;

  final ChatMessage? repliedTo;

  const ChatMessage({
    this.id,
    required this.localId,
    required this.conversationId,
    required this.sender,
    required this.createdAt,
    this.serverCreatedAt,
    this.sendState = SendState.sending,
    this.deliveryState = DeliveryState.none,
    this.failure,
    this.repliedTo,
  }) : assert(
         sendState == SendState.failed ? failure != null : failure == null,
         'failure must be set if and only if sendState == failed',
       ),
       assert(
         sendState == SendState.failed
             ? deliveryState == DeliveryState.none
             : true,
         'failed message must have deliveryState == none',
       );
}

class TextMessage extends ChatMessage {
  final String text;

  const TextMessage({
    super.id,
    required super.localId,
    required super.conversationId,
    required super.sender,
    required super.createdAt,
    super.serverCreatedAt,
    super.sendState,
    super.deliveryState,
    super.failure,
    super.repliedTo,
    required this.text,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localId == other.localId &&
          conversationId == other.conversationId &&
          sender == other.sender &&
          createdAt == other.createdAt &&
          serverCreatedAt == other.serverCreatedAt &&
          sendState == other.sendState &&
          deliveryState == other.deliveryState &&
          failure == other.failure &&
          repliedTo == other.repliedTo &&
          text == other.text;

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    conversationId,
    sender,
    createdAt,
    serverCreatedAt,
    sendState,
    deliveryState,
    failure,
    repliedTo,
    text,
  );

  @override
  String toString() =>
      'TextMessage(localId: $localId, id: $id, text: "$text", sendState: $sendState, deliveryState: $deliveryState)';
}

class MediaMessage extends ChatMessage {
  final ChatAttachment attachment;
  final String? caption;

  /// Optional extensible metadata map (e.g. `audioType`, `audioDurationsMs`,
  /// `localPath`, or multi-attachment carriers). Null by default.
  final Map<String, dynamic>? metadata;

  const MediaMessage({
    super.id,
    required super.localId,
    required super.conversationId,
    required super.sender,
    required super.createdAt,
    super.serverCreatedAt,
    super.sendState,
    super.deliveryState,
    super.failure,
    super.repliedTo,
    required this.attachment,
    this.caption,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localId == other.localId &&
          conversationId == other.conversationId &&
          sender == other.sender &&
          createdAt == other.createdAt &&
          serverCreatedAt == other.serverCreatedAt &&
          sendState == other.sendState &&
          deliveryState == other.deliveryState &&
          failure == other.failure &&
          repliedTo == other.repliedTo &&
          attachment == other.attachment &&
          caption == other.caption;

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    conversationId,
    sender,
    createdAt,
    serverCreatedAt,
    sendState,
    deliveryState,
    failure,
    repliedTo,
    attachment,
    caption,
  );

  @override
  String toString() =>
      'MediaMessage(localId: $localId, id: $id, attachment: $attachment, sendState: $sendState, deliveryState: $deliveryState)';
}

class CustomMessage extends ChatMessage {
  /// Backend-defined payload the library renders via registered templates.
  final String kind;
  final Map<String, dynamic> data;

  const CustomMessage({
    super.id,
    required super.localId,
    required super.conversationId,
    required super.sender,
    required super.createdAt,
    super.serverCreatedAt,
    super.sendState,
    super.deliveryState,
    super.failure,
    super.repliedTo,
    required this.kind,
    required this.data,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localId == other.localId &&
          conversationId == other.conversationId &&
          sender == other.sender &&
          createdAt == other.createdAt &&
          serverCreatedAt == other.serverCreatedAt &&
          sendState == other.sendState &&
          deliveryState == other.deliveryState &&
          failure == other.failure &&
          repliedTo == other.repliedTo &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    conversationId,
    sender,
    createdAt,
    serverCreatedAt,
    sendState,
    deliveryState,
    failure,
    repliedTo,
    kind,
  );

  @override
  String toString() =>
      'CustomMessage(localId: $localId, id: $id, kind: $kind, sendState: $sendState, deliveryState: $deliveryState)';
}

extension ChatMessageStateCopyX on ChatMessage {
  ChatMessage copyWithDeliveryState(DeliveryState state) {
    return switch (this) {
      TextMessage t => TextMessage(
          id: id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt,
          sendState: sendState,
          deliveryState: state,
          failure: failure,
          repliedTo: repliedTo,
          text: t.text,
        ),
      MediaMessage m => MediaMessage(
          id: id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt,
          sendState: sendState,
          deliveryState: state,
          failure: failure,
          repliedTo: repliedTo,
          attachment: m.attachment,
          caption: m.caption,
          metadata: m.metadata,
        ),
      CustomMessage c => CustomMessage(
          id: id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt,
          sendState: sendState,
          deliveryState: state,
          failure: failure,
          repliedTo: repliedTo,
          kind: c.kind,
          data: c.data,
        ),
    };
  }

  ChatMessage copyWithSendState(
    SendState state, {
    ChatError? failure,
    String? id,
    DateTime? serverCreatedAt,
  }) {
    return switch (this) {
      TextMessage t => TextMessage(
          id: id ?? this.id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
          sendState: state,
          deliveryState:
              state == SendState.failed ? DeliveryState.none : deliveryState,
          failure: state == SendState.failed ? failure : null,
          repliedTo: repliedTo,
          text: t.text,
        ),
      MediaMessage m => MediaMessage(
          id: id ?? this.id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
          sendState: state,
          deliveryState:
              state == SendState.failed ? DeliveryState.none : deliveryState,
          failure: state == SendState.failed ? failure : null,
          repliedTo: repliedTo,
          attachment: m.attachment,
          caption: m.caption,
          metadata: m.metadata,
        ),
      CustomMessage c => CustomMessage(
          id: id ?? this.id,
          localId: localId,
          conversationId: conversationId,
          sender: sender,
          createdAt: createdAt,
          serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
          sendState: state,
          deliveryState:
              state == SendState.failed ? DeliveryState.none : deliveryState,
          failure: state == SendState.failed ? failure : null,
          repliedTo: repliedTo,
          kind: c.kind,
          data: c.data,
        ),
    };
  }
}
