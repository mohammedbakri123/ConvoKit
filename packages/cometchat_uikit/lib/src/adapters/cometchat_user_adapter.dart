/// Internal adapter adapting the CometChat SDK into ConvoKit's [UserRepository].
library;

import 'dart:async';

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/pagination.dart';
import '../contracts/result.dart';
import '../contracts/user_repository.dart';
import '../core/models/user.dart';

class CometChatUserAdapter implements UserRepository {
  @override
  Future<ChatResult<ChatUser>> getUser(String id) async {
    try {
      final completer = Completer<cc.User>();
      unawaited(
        cc.CometChat.getUser(
          id,
          onSuccess: (cc.User user) {
            if (!completer.isCompleted) completer.complete(user);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkUser = await completer.future;
      return ChatResult.success(_fromSdkUser(sdkUser));
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, e.message ?? 'User not found', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final builder = cc.UsersRequestBuilder()..limit = limit;
      final request = builder.build();
      final completer = Completer<List<cc.User>>();

      unawaited(
        request.fetchNext(
          onSuccess: (List<cc.User> list) {
            if (!completer.isCompleted) completer.complete(list);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkList = await completer.future;
      final items = sdkList.map(_fromSdkUser).toList();

      return ChatResult.success(
        ChatPage<ChatUser>(
          items: items,
          olderCursor: items.length >= limit ? items.last.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to list users', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final builder = cc.UsersRequestBuilder()
        ..searchKeyword = query
        ..limit = limit;
      final request = builder.build();
      final completer = Completer<List<cc.User>>();

      unawaited(
        request.fetchNext(
          onSuccess: (List<cc.User> list) {
            if (!completer.isCompleted) completer.complete(list);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkList = await completer.future;
      final items = sdkList.map(_fromSdkUser).toList();

      return ChatResult.success(
        ChatPage<ChatUser>(
          items: items,
          olderCursor: items.length >= limit ? items.last.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to search users', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  /// Direct SDK fetch using request builder (used for fallback by remote data source)
  Future<List<cc.User>> getSdkUsers({
    int limit = 30,
    String? searchKeyword,
    cc.UsersRequestBuilder? usersRequestBuilder,
    cc.UsersRequest? existingRequest,
  }) async {
    final cc.UsersRequest request;
    if (existingRequest != null) {
      request = existingRequest;
    } else if (usersRequestBuilder != null) {
      final appSearchKeyword = usersRequestBuilder.searchKeyword;
      try {
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          usersRequestBuilder.searchKeyword = searchKeyword;
        }
        request = usersRequestBuilder.build();
      } finally {
        usersRequestBuilder.searchKeyword = appSearchKeyword;
      }
    } else {
      final builder = cc.UsersRequestBuilder()..limit = limit;
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        builder.searchKeyword = searchKeyword;
      }
      request = builder.build();
    }

    final completer = Completer<List<cc.User>>();
    unawaited(
      request.fetchNext(
        onSuccess: (List<cc.User> list) {
          if (!completer.isCompleted) completer.complete(list);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );

    return completer.future;
  }

  /// Direct SDK block user
  Future<void> blockSdkUser(String uid) async {
    final completer = Completer<void>();
    await cc.CometChat.blockUser(
      [uid],
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK unblock user
  Future<void> unblockSdkUser(String uid) async {
    final completer = Completer<void>();
    await cc.CometChat.unblockUser(
      [uid],
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  static ChatUser _fromSdkUser(cc.User u) {
    return ChatUser(
      id: _read(() => u.uid, ''),
      name: _read(() => u.name, ''),
      avatarUrl: _readNullable(() => u.avatar),
      presence: switch (_read(() => u.status, '')) {
        'online' => UserPresence.online,
        'offline' => UserPresence.offline,
        _ => UserPresence.unknown,
      },
      isBlocked: _read(() => u.blockedByMe, false),
    );
  }

  static cc.User toSdkUser(ChatUser u) {
    return cc.User(
      uid: u.id,
      name: u.name,
      avatar: u.avatarUrl,
      status: switch (u.presence) {
        UserPresence.online => 'online',
        UserPresence.offline => 'offline',
        _ => 'offline',
      },
      blockedByMe: u.isBlocked,
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
