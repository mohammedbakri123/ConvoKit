import 'dart:async';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc hide CardMessage;

import 'package:convokit/convokit.dart' as ck;
import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../src/adapters/cometchat_conversation_adapter.dart';

/// Exception thrown when remote data source operations fail
class RemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const RemoteDataSourceException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() =>
      'RemoteDataSourceException(message: $message, code: $code)';
}

/// Abstract interface for conversations remote data source
/// Handles all interactions with CometChat SDK or ConvoKit contracts
abstract class ConversationsRemoteDataSource {
  /// Get conversations with optional pagination.
  Future<List<cc.Conversation>> getConversations({
    int limit = 30,
    String? fromId,
    cc.ConversationsRequestBuilder? requestBuilder,
  });

  /// Get a specific conversation by ID
  Future<cc.Conversation> getConversation(String conversationId);

  /// Delete a conversation
  /// Requires conversationWith (uid/guid) and conversationType
  Future<void> deleteConversation(
    String conversationWith,
    String conversationType,
  );

  /// Mark a message as read (which updates conversation unread count)
  Future<void> markMessageAsRead(cc.BaseMessage message);

  /// Update a conversation
  Future<cc.Conversation> updateConversation(cc.Conversation conversation);
}

/// Implementation of ConversationsRemoteDataSource using ConvoKit contracts with SDK fallback
class ConversationsRemoteDataSourceImpl
    implements ConversationsRemoteDataSource {
  final ck.ConversationRepository? _repository;

  ConversationsRemoteDataSourceImpl({ck.ConversationRepository? repository})
      : _repository = repository;

  ck.ConversationRepository? get _convoKitRepository =>
      _repository ??
      CometChatUIKit.conversationRepository ??
      CometChatUIKit.kit?.conversations;

  static final CometChatConversationAdapter _sdkAdapter =
      CometChatConversationAdapter();

  @override
  Future<List<cc.Conversation>> getConversations({
    int limit = 30,
    String? fromId,
    cc.ConversationsRequestBuilder? requestBuilder,
  }) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.listConversations(
        cursor: fromId,
        limit: limit,
      );

      return result.fold(
        onSuccess: (page) => page.items.map(_toSdkConversation).toList(),
        onFailure: (err) => throw RemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      return await _sdkAdapter.getSdkConversations(
        limit: limit,
        fromId: fromId,
        requestBuilder: requestBuilder,
      );
    } on cc.CometChatException catch (e) {
      throw RemoteDataSourceException(
        message: e.message ?? 'Failed to fetch conversations',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw RemoteDataSourceException(
        message: 'Unexpected error while fetching conversations: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.Conversation> getConversation(String conversationId) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.getConversation(conversationId);
      return result.fold(
        onSuccess: _toSdkConversation,
        onFailure: (err) => throw RemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    final conversations = await getConversations(limit: 100);
    return conversations.firstWhere(
      (conv) => conv.conversationId == conversationId,
      orElse: () => throw const RemoteDataSourceException(
        message: 'Conversation not found',
        code: 'CONVERSATION_NOT_FOUND',
      ),
    );
  }

  @override
  Future<void> deleteConversation(
    String conversationWith,
    String conversationType,
  ) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final conversationId = conversationType == 'group'
          ? 'group_$conversationWith'
          : conversationWith;
      final result = await repo.deleteConversation(conversationId);
      return result.fold(
        onSuccess: (_) {},
        onFailure: (err) => throw RemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      await _sdkAdapter.deleteSdkConversation(
        conversationWith,
        conversationType,
      );
    } on cc.CometChatException catch (e) {
      throw RemoteDataSourceException(
        message: e.message ?? 'Failed to delete conversation',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw RemoteDataSourceException(
        message: 'Unexpected error while deleting conversation: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> markMessageAsRead(cc.BaseMessage message) async {
    final repo = _convoKitRepository;
    if (repo != null) {
      final result = await repo.markAsRead(message.id.toString());
      return result.fold(
        onSuccess: (_) {},
        onFailure: (err) => throw RemoteDataSourceException(
          message: err.message,
          code: err.code.name,
        ),
      );
    }

    try {
      await _sdkAdapter.markSdkMessageAsRead(message);
    } on cc.CometChatException catch (e) {
      throw RemoteDataSourceException(
        message: e.message ?? 'Failed to mark message as read',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw RemoteDataSourceException(
        message: 'Unexpected error while marking message as read: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<cc.Conversation> updateConversation(cc.Conversation conversation) async {
    return conversation;
  }

  static cc.Conversation _toSdkConversation(ck.ChatConversation c) {
    final String convType;
    final dynamic convWith;

    if (c.type == ck.ChatConversationType.direct && c.peer != null) {
      convType = 'user';
      final peer = c.peer!;
      convWith = cc.User(
        uid: peer.id,
        name: peer.name,
        avatar: peer.avatarUrl,
        status: switch (peer.presence) {
          ck.UserPresence.online => 'online',
          ck.UserPresence.offline => 'offline',
          _ => 'offline',
        },
        blockedByMe: peer.isBlocked,
      );
    } else if (c.group != null) {
      convType = 'group';
      final g = c.group!;
      convWith = cc.Group(
        guid: g.id,
        name: g.name,
        icon: g.avatarUrl,
        type: switch (g.type) {
          ck.GroupType.public => 'public',
          ck.GroupType.private => 'private',
          ck.GroupType.passwordProtected => 'password',
        },
        membersCount: g.memberCount,
      );
    } else {
      convType = 'user';
      convWith = cc.User(uid: c.id, name: c.id);
    }

    final conv = cc.Conversation(
      conversationType: convType,
      conversationWith: convWith,
    );
    conv.conversationId = c.id;
    conv.unreadMessageCount = c.unreadCount;
    conv.updatedAt = c.updatedAt;

    if (c.lastMessage != null) {
      conv.lastMessage = _toSdkMessage(c.lastMessage!);
    }

    return conv;
  }

  static cc.BaseMessage _toSdkMessage(ck.ChatMessage msg) {
    final senderUser = cc.User(
      uid: msg.sender.id,
      name: msg.sender.name,
      avatar: msg.sender.avatarUrl,
    );
    final isGroup = msg.conversationId.startsWith('group_');
    final receiverType = isGroup ? cc.CometChatReceiverType.group : cc.CometChatReceiverType.user;
    final receiverUid = isGroup ? msg.conversationId.replaceFirst('group_', '') : msg.conversationId;
    final intMsgId = int.tryParse(msg.id ?? '') ?? 0;

    switch (msg) {
      case ck.TextMessage t:
        return cc.TextMessage(
          id: intMsgId,
          muid: t.localId,
          text: t.text,
          sender: senderUser,
          receiverUid: receiverUid,
          receiverType: receiverType,
          type: 'text',
          category: 'message',
          sentAt: t.serverCreatedAt ?? t.createdAt,
        );
      case ck.MediaMessage m:
        return cc.MediaMessage(
          id: intMsgId,
          muid: m.localId,
          file: m.attachment.localPath ?? '',
          sender: senderUser,
          receiverUid: receiverUid,
          receiverType: receiverType,
          type: switch (m.attachment.kind) {
            ck.AttachmentKind.image => 'image',
            ck.AttachmentKind.video => 'video',
            ck.AttachmentKind.audio => 'audio',
            ck.AttachmentKind.file => 'file',
          },
          category: 'message',
          sentAt: m.serverCreatedAt ?? m.createdAt,
        );
      case ck.CustomMessage c:
        return cc.CustomMessage(
          id: intMsgId,
          muid: c.localId,
          customData: c.data,
          subType: c.kind,
          sender: senderUser,
          receiverUid: receiverUid,
          receiverType: receiverType,
          type: 'custom',
          category: 'custom',
          sentAt: c.serverCreatedAt ?? c.createdAt,
        );
    }
  }
}
