/// Internal adapter keeping the CometChat SDK behind the read-only ChatSession contract.
library;

import 'dart:async';

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/session.dart';
import '../core/models/user.dart';

/// Internal adapter adapting the CometChat SDK session into ConvoKit's read-only [ChatSession].
class CometChatSessionAdapter implements ChatSession {
  final StreamController<ChatUser?> _streamController =
      StreamController<ChatUser?>.broadcast();

  ChatUser? _cachedUser;

  CometChatSessionAdapter({cc.User? initialUser}) {
    if (initialUser != null) {
      _cachedUser = _fromCometChatUser(initialUser);
    }
  }

  @override
  ChatUser? get currentUser => _cachedUser;

  @override
  Stream<ChatUser?> get currentUserStream => _streamController.stream;

  void updateUser(cc.User? user) {
    final mapped = user != null ? _fromCometChatUser(user) : null;
    _cachedUser = mapped;
    _streamController.add(mapped);
  }

  void dispose() {
    _streamController.close();
  }

  static ChatUser _fromCometChatUser(cc.User user) {
    // Every property is read defensively: legacy tests set
    // `CometChatUIKit.loggedInUser` with mocktail `Fake` users that only
    // implement a subset of `User` (one fake implements just `uid`). The
    // old setter stored the user without reading any property; this
    // conversion must not throw on a partially-implemented User. Real SDK
    // users always provide every value, so production behaviour is
    // unchanged.
    return ChatUser(
      id: _read(() => user.uid, ''),
      name: _read(() => user.name, null) ?? '',
      avatarUrl: _read(() => user.avatar, null),
      presence: switch (_read(() => user.status, null)) {
        'online' => UserPresence.online,
        'offline' => UserPresence.offline,
        _ => UserPresence.unknown,
      },
      isBlocked: _read(() => user.blockedByMe, null) ?? false,
    );
  }

  /// Best-effort read of a property that a partial `Fake` may not
  /// implement (throws `UnimplementedError` via `Fake.noSuchMethod`).
  static T _read<T>(T Function() read, T fallback) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }
}
