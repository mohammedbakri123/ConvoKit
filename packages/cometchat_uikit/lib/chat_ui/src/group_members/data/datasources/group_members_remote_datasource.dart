import 'dart:async';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc hide CardMessage;

import 'package:convokit/convokit.dart' as ck;
import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../shared_ui/src/constants/ui_kit_constants.dart';
import '../../../../../shared_ui/src/logging/cometchat_log.dart';
import '../../../../../src/adapters/cometchat_group_adapter.dart';
import '../../../../../src/adapters/cometchat_sdk_adapter.dart';

/// Exception thrown when remote data source operations fail.
class GroupMembersRemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const GroupMembersRemoteDataSourceException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() =>
      'GroupMembersRemoteDataSourceException(message: $message, code: $code)';
}

/// Abstract interface for group members remote data source.
/// Handles all interactions with CometChat SDK for group member operations.
abstract class GroupMembersRemoteDataSource {
  /// Get group members with pagination.
  Future<List<cc.GroupMember>> getGroupMembers({
    required String guid,
    int limit = 30,
    String? searchKeyword,
  });

  /// Kick a member from the group.
  Future<void> kickGroupMember({required String guid, required String uid});

  /// Ban a member from the group.
  Future<void> banGroupMember({required String guid, required String uid});

  /// Update member scope (role) within the group.
  Future<void> updateMemberScope({
    required String guid,
    required String uid,
    required String scope,
  });

  /// Get the currently logged-in user.
  Future<cc.User?> getLoggedInUser();

  /// Get conversation for the group.
  Future<cc.Conversation?> getConversation(String guid);

  /// Reset the data source state (clears pagination).
  void reset();
}

/// Implementation of GroupMembersRemoteDataSource using ConvoKit contracts with SDK fallback
class GroupMembersRemoteDataSourceImpl implements GroupMembersRemoteDataSource {
  final ck.GroupRepository? _repository;
  cc.GroupMembersRequest? _currentRequest;
  String? _currentGuid;
  String? _currentSearchKeyword;
  cc.GroupMembersRequestBuilder? _currentRequestBuilder;

  GroupMembersRemoteDataSourceImpl({ck.GroupRepository? repository})
      : _repository = repository;

  ck.GroupRepository? get _convoKitRepository =>
      _repository ??
      CometChatUIKit.groupRepository ??
      CometChatUIKit.kit?.groups;

  static final CometChatGroupAdapter _sdkAdapter = CometChatGroupAdapter();

  @override
  Future<List<cc.GroupMember>> getGroupMembers({
    required String guid,
    int limit = 30,
    String? searchKeyword,
    cc.GroupMembersRequestBuilder? groupMembersRequestBuilder,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.listMembers(guid, limit: limit);
      return result.fold(
        onSuccess: (page) {
          var items = page.items;
          if (searchKeyword != null && searchKeyword.isNotEmpty) {
            items = items
                .where((m) => m.user.name
                    .toLowerCase()
                    .contains(searchKeyword.toLowerCase()))
                .toList();
          }
          return items.map(CometChatGroupAdapter.toSdkGroupMember).toList();
        },
        onFailure: (err) => throw GroupMembersRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      final needsNewRequest = _currentRequest == null ||
          _currentGuid != guid ||
          _currentSearchKeyword != searchKeyword ||
          _currentRequestBuilder != groupMembersRequestBuilder;

      if (needsNewRequest) {
        _currentGuid = guid;
        _currentSearchKeyword = searchKeyword;
        _currentRequestBuilder = groupMembersRequestBuilder;

        if (groupMembersRequestBuilder != null) {
          final appGuid = groupMembersRequestBuilder.guid;
          final appLimit = groupMembersRequestBuilder.limit;
          final appSearchKeyword = groupMembersRequestBuilder.searchKeyword;
          if (appGuid != guid) {
            ccLog(
              'GroupMembersRemoteDataSource: '
              'ConvoKitGroupMembers: groupMembersRequestBuilder is for group '
              '"$appGuid", but the list shows group "$guid"; loading "$guid" with '
              "the builder's other settings.",
            );
          }
          try {
            groupMembersRequestBuilder
              ..guid = guid
              ..limit = appLimit ?? limit;
            if (searchKeyword != null && searchKeyword.isNotEmpty) {
              groupMembersRequestBuilder.searchKeyword = searchKeyword;
            }
            _currentRequest = groupMembersRequestBuilder.build();
          } finally {
            groupMembersRequestBuilder
              ..guid = appGuid
              ..limit = appLimit
              ..searchKeyword = appSearchKeyword;
          }
        } else {
          final builder = cc.GroupMembersRequestBuilder(guid)..limit = limit;
          if (searchKeyword != null && searchKeyword.isNotEmpty) {
            builder.searchKeyword = searchKeyword;
          }
          _currentRequest = builder.build();
        }
      }

      return await _sdkAdapter.getSdkGroupMembers(
        guid: guid,
        limit: limit,
        searchKeyword: searchKeyword,
        existingRequest: _currentRequest,
      );
    } on cc.CometChatException catch (e) {
      throw GroupMembersRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch group members',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is GroupMembersRemoteDataSourceException) rethrow;
      throw GroupMembersRemoteDataSourceException(
        message: 'Unexpected error while fetching group members: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> kickGroupMember({
    required String guid,
    required String uid,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.removeMember(guid, uid);
      return result.fold(
        onSuccess: (_) {},
        onFailure: (err) => throw GroupMembersRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      await _sdkAdapter.kickSdkGroupMember(guid: guid, uid: uid);
    } on cc.CometChatException catch (e) {
      throw GroupMembersRemoteDataSourceException(
        message: e.message ?? 'Failed to kick group member',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is GroupMembersRemoteDataSourceException) rethrow;
      throw GroupMembersRemoteDataSourceException(
        message: 'Unexpected error while kicking group member: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> banGroupMember({
    required String guid,
    required String uid,
  }) async {
    try {
      await _sdkAdapter.banSdkGroupMember(guid: guid, uid: uid);
    } on cc.CometChatException catch (e) {
      throw GroupMembersRemoteDataSourceException(
        message: e.message ?? 'Failed to ban group member',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is GroupMembersRemoteDataSourceException) rethrow;
      throw GroupMembersRemoteDataSourceException(
        message: 'Unexpected error while banning group member: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> updateMemberScope({
    required String guid,
    required String uid,
    required String scope,
  }) async {
    try {
      await _sdkAdapter.updateSdkMemberScope(guid: guid, uid: uid, scope: scope);
    } on cc.CometChatException catch (e) {
      throw GroupMembersRemoteDataSourceException(
        message: e.message ?? 'Failed to update member scope',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is GroupMembersRemoteDataSourceException) rethrow;
      throw GroupMembersRemoteDataSourceException(
        message: 'Unexpected error while updating member scope: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.User?> getLoggedInUser() async {
    return CometChatSdkAdapter.getLoggedInUser();
  }

  @override
  Future<cc.Conversation?> getConversation(String guid) async {
    try {
      return await CometChatSdkAdapter.getConversation(
        guid,
        ReceiverTypeConstants.group,
      );
    } on cc.CometChatException catch (e) {
      throw GroupMembersRemoteDataSourceException(
        message: e.message ?? 'Failed to get conversation',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is GroupMembersRemoteDataSourceException) rethrow;
      throw GroupMembersRemoteDataSourceException(
        message: 'Unexpected error while getting conversation: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  void reset() {
    _currentRequest = null;
    _currentGuid = null;
    _currentSearchKeyword = null;
    _currentRequestBuilder = null;
  }
}
