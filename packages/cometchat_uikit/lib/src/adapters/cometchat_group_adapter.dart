/// Internal adapter adapting the CometChat SDK into ConvoKit's [GroupRepository].
library;

import 'dart:async';

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/group_repository.dart';
import '../contracts/pagination.dart';
import '../contracts/result.dart';
import '../core/models/group.dart';
import '../core/models/user.dart';

class CometChatGroupAdapter implements GroupRepository {
  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async {
    try {
      final completer = Completer<cc.Group>();
      unawaited(
        cc.CometChat.getGroup(
          id,
          onSuccess: (cc.Group group) {
            if (!completer.isCompleted) completer.complete(group);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkGroup = await completer.future;
      return ChatResult.success(_fromSdkGroup(sdkGroup));
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, e.message ?? 'Group not found', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final builder = cc.GroupsRequestBuilder()..limit = limit;
      final request = builder.build();
      final completer = Completer<List<cc.Group>>();

      unawaited(
        request.fetchNext(
          onSuccess: (List<cc.Group> list) {
            if (!completer.isCompleted) completer.complete(list);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkList = await completer.future;
      final items = sdkList.map(_fromSdkGroup).toList();

      return ChatResult.success(
        ChatPage<ChatGroup>(
          items: items,
          olderCursor: items.length >= limit ? items.last.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to list groups', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final builder = cc.GroupMembersRequestBuilder(groupId)..limit = limit;
      final request = builder.build();
      final completer = Completer<List<cc.GroupMember>>();

      unawaited(
        request.fetchNext(
          onSuccess: (List<cc.GroupMember> list) {
            if (!completer.isCompleted) completer.complete(list);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkList = await completer.future;
      final items = sdkList.map(_fromSdkMember).toList();

      return ChatResult.success(
        ChatPage<ChatMember>(
          items: items,
          olderCursor: items.length >= limit ? items.last.user.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to list members', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> joinGroup(String groupId) async {
    try {
      final completer = Completer<cc.Group>();
      unawaited(
        cc.CometChat.joinGroup(
          groupId,
          'public',
          onSuccess: (cc.Group group) {
            if (!completer.isCompleted) completer.complete(group);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      await completer.future;
      return ChatResult.ok();
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to join group', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> leaveGroup(String groupId) async {
    try {
      final completer = Completer<void>();
      unawaited(
        cc.CometChat.leaveGroup(
          groupId,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      await completer.future;
      return ChatResult.ok();
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to leave group', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> addMembers(String groupId, List<String> userIds) async {
    try {
      final completer = Completer<void>();
      final members = userIds
          .map((uid) => cc.GroupMember(uid: uid, name: uid, scope: 'participant'))
          .toList();
      unawaited(
        cc.CometChat.addMembersToGroup(
          guid: groupId,
          groupMembers: members,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      await completer.future;
      return ChatResult.ok();
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to add members', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> removeMember(String groupId, String userId) async {
    try {
      final completer = Completer<void>();
      unawaited(
        cc.CometChat.kickGroupMember(
          guid: groupId,
          uid: userId,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      await completer.future;
      return ChatResult.ok();
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to remove member', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  /// Direct SDK fetch using request builder (used for fallback by groups remote data source)
  Future<List<cc.Group>> getSdkGroups({
    int limit = 30,
    String? searchKeyword,
    bool? joinedOnly,
    cc.GroupsRequestBuilder? groupsRequestBuilder,
    cc.GroupsRequest? existingRequest,
  }) async {
    final cc.GroupsRequest request;
    if (existingRequest != null) {
      request = existingRequest;
    } else if (groupsRequestBuilder != null) {
      final appSearchKeyword = groupsRequestBuilder.searchKeyword;
      final appJoinedOnly = groupsRequestBuilder.joinedOnly;
      final appLimit = groupsRequestBuilder.limit;
      try {
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          groupsRequestBuilder.searchKeyword = searchKeyword;
        }
        if (joinedOnly != null) {
          groupsRequestBuilder.joinedOnly = joinedOnly;
        }
        groupsRequestBuilder.limit = limit;
        request = groupsRequestBuilder.build();
      } finally {
        groupsRequestBuilder.searchKeyword = appSearchKeyword;
        groupsRequestBuilder.joinedOnly = appJoinedOnly;
        groupsRequestBuilder.limit = appLimit;
      }
    } else {
      final builder = cc.GroupsRequestBuilder()..limit = limit;
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        builder.searchKeyword = searchKeyword;
      }
      if (joinedOnly != null) {
        builder.joinedOnly = joinedOnly;
      }
      request = builder.build();
    }

    final completer = Completer<List<cc.Group>>();
    unawaited(
      request.fetchNext(
        onSuccess: (List<cc.Group> list) {
          if (!completer.isCompleted) completer.complete(list);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );

    return completer.future;
  }

  /// Direct SDK getGroup
  Future<cc.Group> getSdkGroup(String guid) async {
    final completer = Completer<cc.Group>();
    await cc.CometChat.getGroup(
      guid,
      onSuccess: (cc.Group group) {
        if (!completer.isCompleted) completer.complete(group);
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK joinGroup
  Future<cc.Group> joinSdkGroup({
    required String guid,
    required String groupType,
    String? password,
  }) async {
    final completer = Completer<cc.Group>();
    await cc.CometChat.joinGroup(
      guid,
      groupType,
      password: password ?? '',
      onSuccess: (cc.Group group) {
        if (!completer.isCompleted) completer.complete(group);
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK leaveGroup
  Future<void> leaveSdkGroup(String guid) async {
    final completer = Completer<void>();
    await cc.CometChat.leaveGroup(
      guid,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK getGroupMembers
  Future<List<cc.GroupMember>> getSdkGroupMembers({
    required String guid,
    int limit = 30,
    String? searchKeyword,
    cc.GroupMembersRequestBuilder? groupMembersRequestBuilder,
    cc.GroupMembersRequest? existingRequest,
  }) async {
    final cc.GroupMembersRequest request;
    if (existingRequest != null) {
      request = existingRequest;
    } else if (groupMembersRequestBuilder != null) {
      final appSearchKeyword = groupMembersRequestBuilder.searchKeyword;
      final appGuid = groupMembersRequestBuilder.guid;
      try {
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          groupMembersRequestBuilder.searchKeyword = searchKeyword;
        }
        groupMembersRequestBuilder.guid = guid;
        request = groupMembersRequestBuilder.build();
      } finally {
        groupMembersRequestBuilder.searchKeyword = appSearchKeyword;
        groupMembersRequestBuilder.guid = appGuid;
      }
    } else {
      final builder = cc.GroupMembersRequestBuilder(guid)..limit = limit;
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        builder.searchKeyword = searchKeyword;
      }
      request = builder.build();
    }

    final completer = Completer<List<cc.GroupMember>>();
    unawaited(
      request.fetchNext(
        onSuccess: (List<cc.GroupMember> list) {
          if (!completer.isCompleted) completer.complete(list);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );

    return completer.future;
  }

  /// Direct SDK kickGroupMember
  Future<void> kickSdkGroupMember({
    required String guid,
    required String uid,
  }) async {
    final completer = Completer<void>();
    await cc.CometChat.kickGroupMember(
      guid: guid,
      uid: uid,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK banGroupMember
  Future<void> banSdkGroupMember({
    required String guid,
    required String uid,
  }) async {
    final completer = Completer<void>();
    await cc.CometChat.banGroupMember(
      guid: guid,
      uid: uid,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK updateGroupMemberScope
  Future<void> updateSdkMemberScope({
    required String guid,
    required String uid,
    required String scope,
  }) async {
    final completer = Completer<void>();
    await cc.CometChat.updateGroupMemberScope(
      guid: guid,
      uid: uid,
      scope: scope,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  static ChatGroup _fromSdkGroup(cc.Group g) {
    return ChatGroup(
      id: _read(() => g.guid, ''),
      name: _read(() => g.name, ''),
      avatarUrl: _readNullable(() => g.icon),
      description: _readNullable(() => g.description),
      type: switch (_read(() => g.type, 'public')) {
        'private' => GroupType.private,
        'password' => GroupType.passwordProtected,
        _ => GroupType.public,
      },
      memberCount: _read(() => g.membersCount, 0),
    );
  }

  static cc.Group toSdkGroup(ChatGroup g) {
    return cc.Group(
      guid: g.id,
      name: g.name,
      icon: g.avatarUrl,
      description: g.description,
      type: switch (g.type) {
        GroupType.public => 'public',
        GroupType.private => 'private',
        GroupType.passwordProtected => 'password',
      },
      membersCount: g.memberCount,
    );
  }

  static ChatMember _fromSdkMember(cc.GroupMember m) {
    final user = ChatUser(
      id: _read(() => m.uid, ''),
      name: _read(() => m.name, ''),
      avatarUrl: _readNullable(() => m.avatar),
      presence: switch (_read(() => m.status, '')) {
        'online' => UserPresence.online,
        'offline' => UserPresence.offline,
        _ => UserPresence.unknown,
      },
      isBlocked: _read(() => m.blockedByMe, false),
    );
    return ChatMember(
      user: user,
      role: switch (_read(() => m.scope, 'participant')) {
        'admin' => GroupRole.admin,
        'moderator' => GroupRole.admin,
        _ => GroupRole.member,
      },
    );
  }

  static cc.GroupMember toSdkGroupMember(ChatMember m) {
    return cc.GroupMember(
      uid: m.user.id,
      name: m.user.name,
      avatar: m.user.avatarUrl,
      scope: switch (m.role) {
        GroupRole.admin => 'admin',
        GroupRole.owner => 'admin',
        GroupRole.member => 'participant',
      },
    );
  }

  static T _read<T>(T? Function() read, T fallback) {
    try {
      final val = read();
      return val ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static T? _readNullable<T>(T? Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }
}
