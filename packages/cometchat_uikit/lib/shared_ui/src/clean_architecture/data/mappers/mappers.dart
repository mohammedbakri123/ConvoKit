import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/group_entity.dart';

/// Mapper to convert CometChat SDK BaseMessage to MessageEntity
class MessageMapper {
  /// Convert SDK BaseMessage to domain MessageEntity
  /// Note: Adjust property names based on actual SDK BaseMessage interface
  static MessageEntity fromSDK(dynamic message) {
    final map = message as Map<dynamic, dynamic>;
    // This is a placeholder mapper - update property names to match actual SDK
    return MessageEntity(
      id: map['id']?.toString() ?? 'unknown',
      text: _extractText(map),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderAvatar: map['senderAvatar'],
      receiverId: null,
      receiverName: null,
      timestamp: (map['timestamp'] ?? 0) as int,
      type: MessageType.text,
      status: MessageStatus.sent,
      isDeleted: false,
      deletedAt: null,
      attachmentUrls: null,
      metadata: map['metadata'],
      parentMessageId: null,
      replyCount: null,
      reactionCount: null,
    );
  }

  /// Convert list of SDK messages to domain entities
  static List<MessageEntity> fromSDKList(List<dynamic> messages) {
    return messages.map((msg) => fromSDK(msg)).toList();
  }

  // Helper methods

  static String _extractText(dynamic message) {
    final map = message as Map<dynamic, dynamic>;
    return map['text'] ?? map['caption'] ?? '';
  }
}

/// Mapper to convert CometChat SDK User to UserEntity
class UserMapper {
  /// Convert SDK User to domain UserEntity
  /// Note: Adjust property names based on actual SDK User interface
  static UserEntity fromSDK(dynamic user) {
    final map = user as Map<dynamic, dynamic>;
    return UserEntity(
      id: map['id'] ?? 'unknown',
      name: map['name'] ?? 'Unknown',
      avatar: map['avatar'],
      status: map['status'],
      isOnline: map['status'] == 'online',
      lastActive: map['lastActive'],
      statusMessage: map['statusMessage'],
      metadata: map['metadata'],
    );
  }

  /// Convert list of SDK users to domain entities
  static List<UserEntity> fromSDKList(List<dynamic> users) {
    return users.map((user) => fromSDK(user)).toList();
  }
}

/// Mapper to convert CometChat SDK Group to GroupEntity
class GroupMapper {
  /// Convert SDK Group to domain GroupEntity
  /// Note: Adjust property names based on actual SDK Group interface
  static GroupEntity fromSDK(dynamic group) {
    final map = group as Map<dynamic, dynamic>;
    return GroupEntity(
      id: map['id'] ?? 'unknown',
      name: map['name'] ?? 'Unknown',
      icon: map['icon'],
      description: map['description'],
      owner: map['owner'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      members: const [],
      metadata: map['metadata'],
      type: map['type'] ?? 'public',
    );
  }

  /// Convert list of SDK groups to domain entities
  static List<GroupEntity> fromSDKList(List<dynamic> groups) {
    return groups.map((group) => fromSDK(group)).toList();
  }
}
