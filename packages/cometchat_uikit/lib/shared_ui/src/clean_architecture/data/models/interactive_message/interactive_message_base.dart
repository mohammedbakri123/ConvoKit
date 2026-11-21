import 'package:convokit/src/core/models/models.dart';

/// Pure-Dart interaction goal descriptor (SDK-free).
class InteractionGoal {
  final String? type;
  final List<String>? elementIds;

  const InteractionGoal({this.type, this.elementIds});

  factory InteractionGoal.fromMap(Map<String, dynamic> map) {
    return InteractionGoal(
      type: map['type'] as String?,
      elementIds: (map['elementIds'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (type != null) 'type': type,
    if (elementIds != null) 'elementIds': elementIds,
  };
}

/// Pure-Dart interaction receipt/record (SDK-free).
class Interaction {
  final String elementId;
  final int interactedAt;

  const Interaction({required this.elementId, required this.interactedAt});

  factory Interaction.fromMap(Map<String, dynamic> map) {
    return Interaction(
      elementId: (map['elementId'] ?? '').toString(),
      interactedAt: (map['interactedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'elementId': elementId,
    'interactedAt': interactedAt,
  };
}

/// Pure-Dart base class for interactive messages (Form, Card, Scheduler, CustomInteractive).
class ConvoKitInteractiveMessage {
  int id;
  String muid;
  ChatUser? sender;
  dynamic receiver;
  String receiverUid;
  String type;
  String receiverType;
  String category;
  DateTime? sentAt;
  DateTime? deliveredAt;
  DateTime? readAt;
  Map<String, dynamic>? metadata;
  DateTime? readByMeAt;
  DateTime? deliveredToMeAt;
  DateTime? deletedAt;
  DateTime? editedAt;
  String? deletedBy;
  String? editedBy;
  DateTime? updatedAt;
  String? conversationId;
  int parentMessageId;
  int replyCount;
  List<String>? tags;
  Map<String, dynamic> interactiveData;
  InteractionGoal? interactionGoal;
  List<Interaction>? interactions;
  bool? allowSenderInteraction;

  ConvoKitInteractiveMessage({
    this.id = 0,
    this.muid = '',
    this.sender,
    this.receiver,
    required this.receiverUid,
    required this.type,
    required this.receiverType,
    this.category = 'interactive',
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.metadata,
    this.readByMeAt,
    this.deliveredToMeAt,
    this.deletedAt,
    this.editedAt,
    this.deletedBy,
    this.editedBy,
    this.updatedAt,
    this.conversationId,
    this.parentMessageId = 0,
    this.replyCount = 0,
    this.tags,
    Map<String, dynamic>? interactiveData,
    this.interactionGoal,
    this.interactions,
    this.allowSenderInteraction,
  }) : interactiveData = interactiveData ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'muid': muid,
    'receiverUid': receiverUid,
    'type': type,
    'receiverType': receiverType,
    'category': category,
    if (metadata != null) 'metadata': metadata,
    if (conversationId != null) 'conversationId': conversationId,
    'parentMessageId': parentMessageId,
    'replyCount': replyCount,
    if (tags != null) 'tags': tags,
    'interactiveData': interactiveData,
    if (interactionGoal != null) 'interactionGoal': interactionGoal!.toMap(),
    if (interactions != null)
      'interactions': interactions!.map((e) => e.toMap()).toList(),
    if (allowSenderInteraction != null)
      'allowSenderInteraction': allowSenderInteraction,
  };
}
