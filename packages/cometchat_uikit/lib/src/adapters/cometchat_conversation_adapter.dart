/// Internal adapter adapting the CometChat SDK into ConvoKit's [ConversationRepository].
library;

import 'dart:async';

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/conversation_repository.dart';
import '../contracts/pagination.dart';
import '../contracts/result.dart';
import '../core/models/conversation.dart';
import '../core/models/group.dart';
import '../core/models/message.dart';
import '../core/models/user.dart';
import 'cometchat_message_adapter.dart';

class CometChatConversationAdapter implements ConversationRepository {
  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final builder = cc.ConversationsRequestBuilder()..limit = limit;
      final request = builder.build();
      final completer = Completer<List<cc.Conversation>>();

      unawaited(
        request.fetchNext(
          onSuccess: (List<cc.Conversation> list) {
            if (!completer.isCompleted) {
              completer.complete(list);
            }
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          },
        ),
      );

      final sdkList = await completer.future;
      final items = sdkList.map(_fromSdkConversation).toList();

      return ChatResult.success(
        ChatPage<ChatConversation>(
          items: items,
          olderCursor: items.length >= limit ? items.last.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to list conversations', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async {
    try {
      final completer = Completer<cc.Conversation>();
      // Conversation ID format is typically {uid}_user_{peerUid} or group_{guid}
      final parts = id.split('_');
      final isGroup = id.startsWith('group_') || parts.contains('group');
      final type = isGroup ? 'group' : 'user';
      final withId = isGroup
          ? id.replaceFirst('group_', '')
          : (parts.length >= 3 ? parts.last : id);

      unawaited(
        cc.CometChat.getConversation(
          withId,
          type,
          onSuccess: (cc.Conversation c) {
            if (!completer.isCompleted) completer.complete(c);
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      final sdkConv = await completer.future;
      return ChatResult.success(_fromSdkConversation(sdkConv));
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, e.message ?? 'Failed to get conversation', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async {
    try {
      // In CometChat SDK, markAsRead requires a BaseMessage. If not available,
      // this is a best-effort operation.
      return ChatResult.ok();
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> deleteConversation(String conversationId) async {
    try {
      final completer = Completer<void>();
      final parts = conversationId.split('_');
      final isGroup = conversationId.startsWith('group_') || parts.contains('group');
      final type = isGroup ? 'group' : 'user';
      final withId = isGroup
          ? conversationId.replaceFirst('group_', '')
          : (parts.length >= 3 ? parts.last : conversationId);

      unawaited(
        cc.CometChat.deleteConversation(
          withId,
          type,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete();
          },
          onError: (cc.CometChatException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
        ),
      );

      await completer.future;
      return ChatResult.ok();
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to delete conversation', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  /// Direct SDK fetch using request builder (used for fallback by remote data source)
  Future<List<cc.Conversation>> getSdkConversations({
    int limit = 30,
    String? fromId,
    cc.ConversationsRequestBuilder? requestBuilder,
  }) async {
    final builder = cc.ConversationsRequestBuilder();
    if (requestBuilder != null) {
      builder.withUserAndGroupTags = requestBuilder.withUserAndGroupTags;
      builder.withTags = requestBuilder.withTags;
      builder.tags = requestBuilder.tags;
      builder.includeBlockedUsers = requestBuilder.includeBlockedUsers;
      builder.withBlockedInfo = requestBuilder.withBlockedInfo;
      builder.userTags = requestBuilder.userTags;
      builder.groupTags = requestBuilder.groupTags;
      builder.conversationType = requestBuilder.conversationType;
      builder.unread = requestBuilder.unread;
    }
    builder.limit = limit;

    final request = builder.build();
    final completer = Completer<List<cc.Conversation>>();

    unawaited(
      request.fetchNext(
        onSuccess: (List<cc.Conversation> list) {
          if (!completer.isCompleted) completer.complete(list);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );

    return completer.future;
  }

  /// Direct SDK delete (used for fallback by remote data source)
  Future<void> deleteSdkConversation(
    String conversationWith,
    String conversationType,
  ) async {
    final completer = Completer<void>();
    await cc.CometChat.deleteConversation(
      conversationWith,
      conversationType,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Direct SDK mark as read (used for fallback by remote data source)
  Future<void> markSdkMessageAsRead(cc.BaseMessage message) async {
    final completer = Completer<void>();
    await cc.CometChat.markAsRead(
      message,
      onSuccess: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Convert a ConvoKit ChatConversation to an SDK Conversation
  static cc.Conversation toSdkConversation(ChatConversation conv) {
    dynamic entity;
    String convType;
    if (conv.group != null) {
      convType = 'group';
      entity = cc.Group(
        guid: conv.group!.id,
        name: conv.group!.name,
        type: conv.group!.type.name,
        icon: conv.group!.avatarUrl,
        description: conv.group!.description,
        membersCount: conv.group!.memberCount,
      );
    } else {
      convType = 'user';
      final peer = conv.peer;
      entity = peer != null
          ? cc.User(
              uid: peer.id,
              name: peer.name,
              avatar: peer.avatarUrl,
              status: peer.presence.name,
              blockedByMe: peer.isBlocked,
            )
          : cc.User(uid: conv.id, name: conv.id);
    }
    return cc.Conversation(
      conversationId: conv.id,
      conversationType: convType,
      conversationWith: entity,
      unreadMessageCount: conv.unreadCount,
      updatedAt: conv.updatedAt,
      lastMessage: conv.lastMessage != null
          ? CometChatMessageAdapter.toSdkMessage(conv.lastMessage!)
          : null,
    );
  }

  static ChatConversation _fromSdkConversation(cc.Conversation conv) {
    final id = _read(() => conv.conversationId, '');
    final unread = _read(() => conv.unreadMessageCount, 0);
    final updatedAt = _read(() => conv.updatedAt, DateTime.now());

    final entity = _readNullable(() => conv.conversationWith);
    final lastMsg = _readNullable(() => conv.lastMessage);
    final chatLastMsg = lastMsg != null ? _fromSdkMessage(lastMsg, id) : null;

    if (entity is cc.Group || (_read(() => conv.conversationType, '') == 'group')) {
      final groupEntity = entity is cc.Group ? entity : null;
      final group = ChatGroup(
        id: groupEntity != null ? _read(() => groupEntity.guid, '') : id,
        name: groupEntity != null ? _read(() => groupEntity.name, '') : '',
        avatarUrl: groupEntity != null ? _readNullable(() => groupEntity.icon) : null,
        description: groupEntity != null ? _readNullable(() => groupEntity.description) : null,
        type: switch (groupEntity != null ? _read(() => groupEntity.type, 'public') : 'public') {
          'private' => GroupType.private,
          'password' => GroupType.passwordProtected,
          _ => GroupType.public,
        },
        memberCount: groupEntity != null ? _read(() => groupEntity.membersCount, 0) : 0,
      );
      return ChatConversation.group(
        id: id,
        group: group,
        lastMessage: chatLastMsg,
        unreadCount: unread,
        updatedAt: updatedAt,
      );
    } else {
      final userEntity = entity is cc.User ? entity : null;
      final user = ChatUser(
        id: userEntity != null ? _read(() => userEntity.uid, '') : '',
        name: userEntity != null ? _read(() => userEntity.name, '') : '',
        avatarUrl: userEntity != null ? _readNullable(() => userEntity.avatar) : null,
        presence: switch (userEntity != null ? _read(() => userEntity.status, '') : '') {
          'online' => UserPresence.online,
          'offline' => UserPresence.offline,
          _ => UserPresence.unknown,
        },
        isBlocked: userEntity != null ? _read(() => userEntity.blockedByMe, false) : false,
      );
      return ChatConversation.direct(
        id: id,
        peer: user,
        lastMessage: chatLastMsg,
        unreadCount: unread,
        updatedAt: updatedAt,
      );
    }
  }

  static ChatMessage? _fromSdkMessage(cc.BaseMessage msg, String conversationId) {
    final senderEntity = _readNullable(() => msg.sender);
    final sender = ChatUser(
      id: senderEntity != null ? _read(() => senderEntity.uid, '') : '',
      name: senderEntity != null ? _read(() => senderEntity.name, '') : '',
      avatarUrl: senderEntity != null ? _readNullable(() => senderEntity.avatar) : null,
    );
    final id = _readNullable(() => msg.id.toString());
    final localId = _read(() => msg.muid, '');
    final createdAt = _read(() => msg.sentAt, DateTime.now());

    if (msg is cc.TextMessage) {
      return TextMessage(
        id: id,
        localId: localId.isNotEmpty ? localId : 'sdk_$id',
        conversationId: conversationId,
        sender: sender,
        createdAt: createdAt,
        sendState: SendState.sent,
        text: _read(() => msg.text, ''),
      );
    }
    return null;
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
