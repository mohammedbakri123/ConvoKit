/// UserRepository contract according to API-DESIGN.md §4.
library;

import '../core/models/user.dart';
import 'pagination.dart';
import 'result.dart';

abstract class UserRepository {
  Future<ChatResult<ChatUser>> getUser(String id);
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  });
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  });
}
