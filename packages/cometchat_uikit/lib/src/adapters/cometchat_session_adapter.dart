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
    return ChatUser(
      id: user.uid,
      name: user.name ?? '',
      avatarUrl: user.avatar,
      presence: switch (user.status) {
        'online' => UserPresence.online,
        'offline' => UserPresence.offline,
        _ => UserPresence.unknown,
      },
      // `blockedByMe` is read defensively: legacy tests set
      // `CometChatUIKit.loggedInUser` with mocktail `Fake` users that only
      // implement uid/name/status/avatar/role/link. The old setter stored
      // the user without touching `blockedByMe`; this conversion must not
      // throw on a partially-implemented User. Real SDK users always
      // provide the value.
      isBlocked: _blockedByMe(user),
    );
  }

  static bool _blockedByMe(cc.User user) {
    try {
      return user.blockedByMe ?? false;
    } catch (_) {
      return false;
    }
  }
}
