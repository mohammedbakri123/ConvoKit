/// Core user models according to API-DESIGN.md §2.
library;

enum UserPresence { online, offline, away, unknown }

/// A person. `id` is opaque — the library never interprets it.
class ChatUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final UserPresence presence;
  final bool isBlocked;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.presence = UserPresence.unknown,
    this.isBlocked = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl &&
          presence == other.presence &&
          isBlocked == other.isBlocked;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, presence, isBlocked);

  @override
  String toString() => 'ChatUser(id: $id, name: $name, presence: $presence)';
}
