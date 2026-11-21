import 'dart:math' as math;

import 'package:convokit/convokit.dart';

import 'studio_event_source.dart';

/// In-memory [UserRepository] with deterministic cursor pagination and
/// case-insensitive user search.
class StudioUserRepository implements UserRepository {
  StudioUserRepository({
    required List<ChatUser> initialUsers,
    StudioEventSource? eventSource,
  }) : _eventSource = eventSource {
    reset(initialUsers);
  }

  final StudioEventSource? _eventSource;
  final List<ChatUser> _users = <ChatUser>[];

  /// Replaces the in-memory user list with [users].
  void reset(List<ChatUser> users) {
    _users
      ..clear()
      ..addAll(users);
  }

  /// Synchronous lookup helper used by sibling studio repositories.
  ChatUser? findByIdSync(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  /// Updates a teammate's [UserPresence] and emits [PresenceChanged].
  ChatResult<ChatUser> updatePresence(String userId, UserPresence presence) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'User "$userId" not found.'),
      );
    }
    final existing = _users[index];
    final updated = ChatUser(
      id: existing.id,
      name: existing.name,
      avatarUrl: existing.avatarUrl,
      presence: presence,
      isBlocked: existing.isBlocked,
    );
    _users[index] = updated;
    _eventSource?.emitPresenceChanged(user: updated, presence: presence);
    return ChatResult.success(updated);
  }

  @override
  Future<ChatResult<ChatUser>> getUser(String id) async {
    final user = findByIdSync(id);
    if (user == null) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'User "$id" not found.'),
      );
    }
    return ChatResult.success(user);
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async {
    return _paginate(_users, cursor: cursor, limit: limit);
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  }) async {
    final normalized = query.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? _users
        : _users
              .where(
                (user) =>
                    user.name.toLowerCase().contains(normalized) ||
                    user.id.toLowerCase().contains(normalized),
              )
              .toList(growable: false);
    return _paginate(filtered, cursor: cursor, limit: limit);
  }

  ChatResult<ChatPage<ChatUser>> _paginate(
    List<ChatUser> source, {
    required String? cursor,
    required int limit,
  }) {
    if (limit <= 0) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.validation, 'limit must be greater than 0.'),
      );
    }

    var offset = 0;
    if (cursor != null && cursor.isNotEmpty) {
      final parsed = int.tryParse(cursor);
      if (parsed == null || parsed < 0) {
        return ChatResult.failure(
          ChatError(ChatErrorCode.validation, 'Invalid cursor "$cursor".'),
        );
      }
      offset = parsed;
    }

    if (offset >= source.length) {
      return const ChatResult.success(ChatPage<ChatUser>(items: <ChatUser>[]));
    }

    final end = math.min(offset + limit, source.length);
    final slice = List<ChatUser>.unmodifiable(source.sublist(offset, end));
    final nextCursor = end < source.length ? '$end' : null;
    return ChatResult.success(
      ChatPage<ChatUser>(
        items: slice,
        olderCursor: nextCursor,
      ),
    );
  }
}
