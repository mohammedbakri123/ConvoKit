/// Conversation models and invariants according to API-DESIGN.md §2.
library;

import 'group.dart';
import 'message.dart';
import 'user.dart';

enum ChatConversationType { direct, group }

class ChatConversation {
  final String id;
  final ChatUser? peer; // direct only, null for groups
  final ChatGroup? group; // group only, null for direct
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversationType get type =>
      peer != null ? ChatConversationType.direct : ChatConversationType.group;

  factory ChatConversation.direct({
    required String id,
    required ChatUser peer,
    ChatMessage? lastMessage,
    int unreadCount = 0,
    required DateTime updatedAt,
  }) => ChatConversation._(
    id: id,
    peer: peer,
    lastMessage: lastMessage,
    unreadCount: unreadCount,
    updatedAt: updatedAt,
  );

  factory ChatConversation.group({
    required String id,
    required ChatGroup group,
    ChatMessage? lastMessage,
    int unreadCount = 0,
    required DateTime updatedAt,
  }) => ChatConversation._(
    id: id,
    group: group,
    lastMessage: lastMessage,
    unreadCount: unreadCount,
    updatedAt: updatedAt,
  );

  const ChatConversation._({
    required this.id,
    this.peer,
    this.group,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  }) : assert(
         (peer == null) != (group == null),
         'Exactly one of peer/group must be set',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          peer == other.peer &&
          group == other.group &&
          lastMessage == other.lastMessage &&
          unreadCount == other.unreadCount &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, peer, group, lastMessage, unreadCount, updatedAt);

  @override
  String toString() =>
      'ChatConversation(id: $id, type: $type, unreadCount: $unreadCount)';
}
