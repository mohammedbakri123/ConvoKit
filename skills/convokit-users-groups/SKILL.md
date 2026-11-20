---
name: convokit-users-groups
description: >
  Use when implementing user lists, group management, member pickers, or UserRepository / GroupRepository contracts.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Users & Groups

Managing user contacts, group chats, and group membership.

## Public Widgets

- `ConvoKitUsers`: Displays user contact list with search and pagination.
- `ConvoKitGroups`: Displays available groups with join/leave actions.
- `ConvoKitGroupMembers`: Manages members, roles (admin, moderator, participant), and bans.

## Optional Group Capability

If your backend does not support groups:
- Set `ChatCapabilities(groups: false)`.
- Pass `groups: null` to `ConvoKit`.
- The library completely hides all group affordances and group tabs.
- Direct 1-on-1 chats continue to work seamlessly.

## Contracts

```dart
abstract class UserRepository {
  Future<ChatResult<ChatUser>> getUser(String id);
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({String? cursor, int limit = 30});
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(String query, {String? cursor, int limit = 30});
}

abstract class GroupRepository {
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({String? cursor, int limit = 30});
  Future<ChatResult<ChatGroup>> getGroup(String id);
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(String groupId, {String? cursor, int limit = 30});
  Future<ChatResult<void>> joinGroup(String groupId, {String? password});
  Future<ChatResult<void>> leaveGroup(String groupId);
}
```
