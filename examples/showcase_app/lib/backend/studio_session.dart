import 'dart:async';

import 'package:convokit/convokit.dart';

/// In-memory [ChatSession] implementation for the offline Atelier Studio backend.
///
/// Supports switching the active studio teammate, signing out, and resetting
/// back to the default current user while broadcasting changes on
/// [currentUserStream].
class StudioSession implements ChatSession {
  StudioSession({required ChatUser initialUser}) : _currentUser = initialUser;

  final StreamController<ChatUser?> _controller =
      StreamController<ChatUser?>.broadcast();

  ChatUser? _currentUser;
  bool _isDisposed = false;

  @override
  ChatUser? get currentUser => _currentUser;

  @override
  Stream<ChatUser?> get currentUserStream => _controller.stream;

  /// Switches the signed-in user (or signs out when [user] is `null`).
  void switchUser(ChatUser? user) {
    if (_isDisposed) return;
    _currentUser = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  /// Signs out the current user by emitting `null`.
  void signOut() => switchUser(null);

  /// Resets the active session back to [initialUser].
  void reset(ChatUser initialUser) => switchUser(initialUser);

  /// Closes the underlying broadcast stream controller.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _controller.close();
  }
}
