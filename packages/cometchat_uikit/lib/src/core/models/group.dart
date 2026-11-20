/// Core group models according to API-DESIGN.md §2.
library;

import 'user.dart';

enum GroupRole { owner, admin, member }

class ChatMember {
  final ChatUser user;
  final GroupRole role;

  const ChatMember({required this.user, required this.role});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMember &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          role == other.role;

  @override
  int get hashCode => Object.hash(user, role);

  @override
  String toString() => 'ChatMember(user: ${user.id}, role: $role)';
}

enum GroupType { public, private, passwordProtected }

class ChatGroup {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final GroupType type;
  final int memberCount;

  /// Null = members not loaded; empty list = group has no members.
  final List<ChatMember>? members;

  const ChatGroup({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.type = GroupType.public,
    this.memberCount = 0,
    this.members,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl &&
          description == other.description &&
          type == other.type &&
          memberCount == other.memberCount;

  @override
  int get hashCode =>
      Object.hash(id, name, avatarUrl, description, type, memberCount);

  @override
  String toString() => 'ChatGroup(id: $id, name: $name, type: $type)';
}
