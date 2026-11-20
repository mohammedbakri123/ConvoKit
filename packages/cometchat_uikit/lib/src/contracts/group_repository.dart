/// GroupRepository contract according to API-DESIGN.md §4.
library;

import '../core/models/group.dart';
import 'pagination.dart';
import 'result.dart';

abstract class GroupRepository {
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  });
  Future<ChatResult<ChatGroup>> getGroup(String id);
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  });
  Future<ChatResult<void>> joinGroup(String groupId);
  Future<ChatResult<void>> leaveGroup(String groupId);
  Future<ChatResult<void>> addMembers(String groupId, List<String> userIds);
  Future<ChatResult<void>> removeMember(String groupId, String userId);
}
