import 'dart:async';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc hide CardMessage;

import 'package:convokit/convokit.dart' as ck;
import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../src/adapters/cometchat_group_adapter.dart';
import '../../../../../src/adapters/cometchat_sdk_adapter.dart';

/// Exception thrown when remote data source operations fail
class GroupsRemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const GroupsRemoteDataSourceException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() =>
      'GroupsRemoteDataSourceException(message: $message, code: $code)';
}

/// Abstract interface for groups remote data source
/// Handles all interactions with CometChat SDK for groups
abstract class GroupsRemoteDataSource {
  /// Get groups with optional pagination and search.
  Future<List<cc.Group>> getGroups({
    int limit = 30,
    String? searchKeyword,
    bool? joinedOnly,
  });

  /// Reset the internal SDK request so the next [getGroups] call starts fresh.
  void resetRequest();

  /// Get a specific group by GUID
  Future<cc.Group> getGroupById(String guid);

  /// Join a group
  Future<cc.Group> joinGroup({
    required String guid,
    required String groupType,
    String? password,
  });

  /// Leave a group
  Future<void> leaveGroup(String guid);

  /// Get the currently logged in user
  Future<cc.User?> getLoggedInUser();
}

/// Implementation of GroupsRemoteDataSource using ConvoKit contracts with SDK fallback
class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  final ck.GroupRepository? _repository;
  cc.GroupsRequest? _currentRequest;

  GroupsRemoteDataSourceImpl({ck.GroupRepository? repository})
      : _repository = repository;

  ck.GroupRepository? get _convoKitRepository =>
      _repository ??
      CometChatUIKit.groupRepository ??
      CometChatUIKit.kit?.groups;

  static final CometChatGroupAdapter _sdkAdapter = CometChatGroupAdapter();

  @override
  void resetRequest() {
    _currentRequest = null;
  }

  @override
  Future<List<cc.Group>> getGroups({
    int limit = 30,
    String? searchKeyword,
    bool? joinedOnly,
    cc.GroupsRequestBuilder? groupsRequestBuilder,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.listGroups(limit: limit);
      return result.fold(
        onSuccess: (page) {
          var items = page.items;
          if (searchKeyword != null && searchKeyword.isNotEmpty) {
            items = items
                .where((g) =>
                    g.name.toLowerCase().contains(searchKeyword.toLowerCase()))
                .toList();
          }
          return items.map(CometChatGroupAdapter.toSdkGroup).toList();
        },
        onFailure: (err) => throw GroupsRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      if (_currentRequest == null) {
        if (groupsRequestBuilder != null) {
          final appLimit = groupsRequestBuilder.limit;
          final appSearchKeyword = groupsRequestBuilder.searchKeyword;
          final appJoinedOnly = groupsRequestBuilder.joinedOnly;
          try {
            groupsRequestBuilder.limit = appLimit ?? limit;
            if (searchKeyword != null && searchKeyword.isNotEmpty) {
              groupsRequestBuilder.searchKeyword = searchKeyword;
            }
            if (joinedOnly != null) groupsRequestBuilder.joinedOnly = joinedOnly;
            _currentRequest = groupsRequestBuilder.build();
          } finally {
            groupsRequestBuilder
              ..limit = appLimit
              ..searchKeyword = appSearchKeyword
              ..joinedOnly = appJoinedOnly;
          }
        } else {
          final requestBuilder = cc.GroupsRequestBuilder()..limit = limit;
          if (searchKeyword != null && searchKeyword.isNotEmpty) {
            requestBuilder.searchKeyword = searchKeyword;
          }
          if (joinedOnly != null) {
            requestBuilder.joinedOnly = joinedOnly;
          }
          _currentRequest = requestBuilder.build();
        }
      }

      return await _sdkAdapter.getSdkGroups(
        limit: limit,
        searchKeyword: searchKeyword,
        joinedOnly: joinedOnly,
        existingRequest: _currentRequest,
      );
    } on cc.CometChatException catch (e) {
      throw GroupsRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch groups',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw GroupsRemoteDataSourceException(
        message: 'Unexpected error while fetching groups: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.Group> getGroupById(String guid) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.getGroup(guid);
      return result.fold(
        onSuccess: CometChatGroupAdapter.toSdkGroup,
        onFailure: (err) => throw GroupsRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      return await _sdkAdapter.getSdkGroup(guid);
    } on cc.CometChatException catch (e) {
      throw GroupsRemoteDataSourceException(
        message: e.message ?? 'Failed to get group',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw GroupsRemoteDataSourceException(
        message: 'Unexpected error while getting group: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.Group> joinGroup({
    required String guid,
    required String groupType,
    String? password,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.joinGroup(guid);
      return result.fold(
        onSuccess: (_) => getGroupById(guid),
        onFailure: (err) => throw GroupsRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      return await _sdkAdapter.joinSdkGroup(
        guid: guid,
        groupType: groupType,
        password: password,
      );
    } on cc.CometChatException catch (e) {
      throw GroupsRemoteDataSourceException(
        message: e.message ?? 'Failed to join group',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw GroupsRemoteDataSourceException(
        message: 'Unexpected error while joining group: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> leaveGroup(String guid) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.leaveGroup(guid);
      return result.fold(
        onSuccess: (_) {},
        onFailure: (err) => throw GroupsRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      await _sdkAdapter.leaveSdkGroup(guid);
    } on cc.CometChatException catch (e) {
      throw GroupsRemoteDataSourceException(
        message: e.message ?? 'Failed to leave group',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw GroupsRemoteDataSourceException(
        message: 'Unexpected error while leaving group: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.User?> getLoggedInUser() async {
    return CometChatSdkAdapter.getLoggedInUser();
  }
}
