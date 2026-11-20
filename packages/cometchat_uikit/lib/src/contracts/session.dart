/// Read-only ChatSession contract according to API-DESIGN.md §4, §10.
library;

import '../core/models/user.dart';

/// Session: who is signed in. Read-only observable state.
/// The host owns sign-in, sign-out, token storage and session restore.
/// The library never sees credentials and never calls a login endpoint.
abstract class ChatSession {
  ChatUser? get currentUser;
  Stream<ChatUser?> get currentUserStream;
}
