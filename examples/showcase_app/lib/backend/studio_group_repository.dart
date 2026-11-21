import 'dart:math' as math;

import 'package:convokit/convokit.dart';

import 'studio_conversation_repository.dart';
import 'studio_session.dart';
import 'studio_user_repository.dart';

/// In-memory [GroupRepository] for Atelier Studio groups and memberships.
class StudioGroupRepository implements GroupRepository {
  StudioGroupRepository({
    required List<ChatGroup> initialGroups,
    required StudioSession session,
    required StudioUserRepository userRepository,
    required StudioConversationRepository conversationRepository,
  }) : _session = session,
       _userRepository = userRepository,
       _conversationRepository = conversationRepository {
    reset(initialGroups);
  }

  final StudioSession _session;
  final StudioUserRepository _userRepository;
  final StudioConversationRepository _conversationRepository;

  final List<ChatGroup> _groups = <ChatGroup>[];
  final Map<String, List<ChatMember>> _membersByGroup =
      <String, List<ChatMember>>{};

  /// Replaces the in-memory group catalog and member rosters.
  void reset(List<ChatGroup> groups) {
    _groups.clear();
    _membersByGroup.clear();
    for (final group in groups) {
      final members = List<ChatMember>.from(
        group.members ?? const <ChatMember>[],
      );
      _membersByGroup[group.id] = members;
      _groups.add(_buildGroup(group, members));
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  }) async {
    return _paginate(_groups, cursor: cursor, limit: limit);
  }

  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$id" not found.'),
      );
    }
    return ChatResult.success(_groups[index]);
  }

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    final members = _membersByGroup[groupId];
    if (members == null) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }
    return _paginate(members, cursor: cursor, limit: limit);
  }

  @override
  Future<ChatResult<void>> joinGroup(String groupId) async {
    final currentUser = _session.currentUser;
    if (currentUser == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unauthorized, 'No signed-in user.'),
      );
    }

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }

    final members = _membersByGroup[groupId]!;
    final alreadyMember = members.any((m) => m.user.id == currentUser.id);
    if (!alreadyMember) {
      members.add(ChatMember(user: currentUser, role: GroupRole.member));
      _syncGroupRecord(index);
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> leaveGroup(String groupId) async {
    final currentUser = _session.currentUser;
    if (currentUser == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unauthorized, 'No signed-in user.'),
      );
    }

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }

    final members = _membersByGroup[groupId]!;
    final before = members.length;
    members.removeWhere((m) => m.user.id == currentUser.id);
    if (members.length != before) {
      _syncGroupRecord(index);
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> addMembers(
    String groupId,
    List<String> userIds,
  ) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }

    final members = _membersByGroup[groupId]!;
    var changed = false;
    for (final userId in userIds) {
      final user = _userRepository.findByIdSync(userId);
      if (user == null) {
        return ChatResult.failure(
          ChatError(ChatErrorCode.notFound, 'User "$userId" not found.'),
        );
      }
      final alreadyMember = members.any((m) => m.user.id == userId);
      if (!alreadyMember) {
        members.add(ChatMember(user: user, role: GroupRole.member));
        changed = true;
      }
    }

    if (changed) {
      _syncGroupRecord(index);
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> removeMember(String groupId, String userId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }

    final members = _membersByGroup[groupId]!;
    final before = members.length;
    members.removeWhere((m) => m.user.id == userId);
    if (members.length == before) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.notFound,
          'Member "$userId" not found in group "$groupId".',
        ),
      );
    }

    _syncGroupRecord(index);
    return ChatResult.ok();
  }

  /// Updates a member's [GroupRole] in-memory (used by scope-change UI).
  ChatResult<ChatMember> updateMemberRole(
    String groupId,
    String userId,
    GroupRole role,
  ) {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Group "$groupId" not found.'),
      );
    }

    final members = _membersByGroup[groupId]!;
    final memberIndex = members.indexWhere((m) => m.user.id == userId);
    if (memberIndex == -1) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.notFound,
          'Member "$userId" not found in group "$groupId".',
        ),
      );
    }

    final updated = ChatMember(user: members[memberIndex].user, role: role);
    members[memberIndex] = updated;
    _syncGroupRecord(groupIndex);
    return ChatResult.success(updated);
  }

  void _syncGroupRecord(int index) {
    final existing = _groups[index];
    final members = _membersByGroup[existing.id]!;
    final updated = _buildGroup(existing, members);
    _groups[index] = updated;
    _conversationRepository.syncGroup(updated);
  }

  ChatGroup _buildGroup(ChatGroup base, List<ChatMember> members) {
    return ChatGroup(
      id: base.id,
      name: base.name,
      avatarUrl: base.avatarUrl,
      description: base.description,
      type: base.type,
      memberCount: members.length,
      members: List<ChatMember>.unmodifiable(members),
    );
  }

  ChatResult<ChatPage<T>> _paginate<T>(
    List<T> source, {
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
      return ChatResult.success(ChatPage<T>(items: List<T>.empty()));
    }

    final end = math.min(offset + limit, source.length);
    final slice = List<T>.unmodifiable(source.sublist(offset, end));
    final nextCursor = end < source.length ? '$end' : null;
    return ChatResult.success(
      ChatPage<T>(
        items: slice,
        olderCursor: nextCursor,
      ),
    );
  }
}
