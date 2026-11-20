import 'dart:async';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc hide CardMessage;

import 'package:cometchat_chat_uikit/convokit.dart' as ck;
import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../src/adapters/cometchat_user_adapter.dart';

/// Exception thrown when remote data source operations fail
class UsersRemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const UsersRemoteDataSourceException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() =>
      'UsersRemoteDataSourceException(message: $message, code: $code)';
}

/// Abstract interface for users remote data source
/// Handles all interactions with CometChat SDK
abstract class UsersRemoteDataSource {
  /// Get users with optional pagination and search.
  /// On the first call (or after [resetRequest]) a new SDK request is built;
  /// subsequent calls reuse the same request so the SDK cursor advances.
  Future<List<cc.User>> getUsers({
    int limit = 30,
    String? searchKeyword,
    cc.UsersRequestBuilder? usersRequestBuilder,
  });

  /// Reset the internal SDK request so the next [getUsers] call starts fresh.
  /// Call this when doing a fresh load or when the search keyword changes.
  void resetRequest();

  /// Get a specific user by UID
  Future<cc.User> getUser(String uid);

  /// Block a user
  Future<void> blockUser(String uid);

  /// Unblock a user
  Future<void> unblockUser(String uid);
}

/// Implementation of UsersRemoteDataSource using ConvoKit contracts with SDK fallback
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final ck.UserRepository? _repository;
  cc.UsersRequest? _currentRequest;

  UsersRemoteDataSourceImpl({ck.UserRepository? repository})
      : _repository = repository;

  ck.UserRepository? get _convoKitRepository =>
      _repository ??
      CometChatUIKit.userRepository ??
      CometChatUIKit.kit?.users;

  static final CometChatUserAdapter _sdkAdapter = CometChatUserAdapter();

  @override
  void resetRequest() {
    _currentRequest = null;
  }

  @override
  Future<List<cc.User>> getUsers({
    int limit = 30,
    String? searchKeyword,
    cc.UsersRequestBuilder? usersRequestBuilder,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final ck.ChatResult<ck.ChatPage<ck.ChatUser>> result;
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        result = await repo.searchUsers(searchKeyword, limit: limit);
      } else {
        result = await repo.listUsers(limit: limit);
      }

      return result.fold(
        onSuccess: (page) => page.items.map(CometChatUserAdapter.toSdkUser).toList(),
        onFailure: (err) => throw UsersRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      if (_currentRequest == null) {
        if (usersRequestBuilder != null) {
          final appSearchKeyword = usersRequestBuilder.searchKeyword;
          try {
            if (searchKeyword != null && searchKeyword.isNotEmpty) {
              usersRequestBuilder.searchKeyword = searchKeyword;
            }
            _currentRequest = usersRequestBuilder.build();
          } finally {
            usersRequestBuilder.searchKeyword = appSearchKeyword;
          }
        } else {
          final requestBuilder = cc.UsersRequestBuilder()..limit = limit;
          if (searchKeyword != null && searchKeyword.isNotEmpty) {
            requestBuilder.searchKeyword = searchKeyword;
          }
          _currentRequest = requestBuilder.build();
        }
      }

      return await _sdkAdapter.getSdkUsers(
        limit: limit,
        searchKeyword: searchKeyword,
        existingRequest: _currentRequest,
      );
    } on cc.CometChatException catch (e) {
      throw UsersRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch users',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UsersRemoteDataSourceException(
        message: 'Unexpected error while fetching users: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.User> getUser(String uid) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.getUser(uid);
      return result.fold(
        onSuccess: CometChatUserAdapter.toSdkUser,
        onFailure: (err) => throw UsersRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      final result = await _sdkAdapter.getUser(uid);
      final user = result.fold(
        onSuccess: CometChatUserAdapter.toSdkUser,
        onFailure: (err) => throw UsersRemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
      return user;
    } on cc.CometChatException catch (e) {
      throw UsersRemoteDataSourceException(
        message: e.message ?? 'Failed to get user',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UsersRemoteDataSourceException(
        message: 'Unexpected error while getting user: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> blockUser(String uid) async {
    try {
      await _sdkAdapter.blockSdkUser(uid);
    } on cc.CometChatException catch (e) {
      throw UsersRemoteDataSourceException(
        message: e.message ?? 'Failed to block user',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UsersRemoteDataSourceException(
        message: 'Unexpected error while blocking user: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> unblockUser(String uid) async {
    try {
      await _sdkAdapter.unblockSdkUser(uid);
    } on cc.CometChatException catch (e) {
      throw UsersRemoteDataSourceException(
        message: e.message ?? 'Failed to unblock user',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UsersRemoteDataSourceException(
        message: 'Unexpected error while unblocking user: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }
}
