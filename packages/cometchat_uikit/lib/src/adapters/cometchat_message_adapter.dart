// ignore_for_file: public_member_api_docs
/// Internal adapter adapting the CometChat SDK into ConvoKit's [MessageRepository].
library;

import 'dart:async';

import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/message_repository.dart';
import '../contracts/pagination.dart';
import '../contracts/result.dart';
import '../core/models/attachment.dart';
import '../core/models/message.dart';
import '../core/models/user.dart';

/// Message adapter bridging ConvoKit MessageRepository with CometChat SDK.
class CometChatMessageAdapter implements MessageRepository {
  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async {
    try {
      final builder = cc.MessagesRequestBuilder()..limit = request.limit;
      final isGroup = conversationId.startsWith('group_');
      final withId = isGroup
          ? conversationId.replaceFirst('group_', '')
          : conversationId;

      if (isGroup) {
        builder.guid = withId;
      } else {
        builder.uid = withId;
      }

      if (request.cursor != null) {
        final cursorId = int.tryParse(request.cursor!) ?? -1;
        if (cursorId > 0) {
          builder.messageId = cursorId;
        }
      }

      final req = builder.build();
      final completer = Completer<List<cc.BaseMessage>>();

      if (request.direction == MessagePageDirection.older) {
        unawaited(
          req.fetchPrevious(
            onSuccess: (List<cc.BaseMessage> list) {
              if (!completer.isCompleted) completer.complete(list);
            },
            onError: (cc.CometChatException e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          ),
        );
      } else {
        unawaited(
          req.fetchNext(
            onSuccess: (List<cc.BaseMessage> list) {
              if (!completer.isCompleted) completer.complete(list);
            },
            onError: (cc.CometChatException e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          ),
        );
      }

      final sdkList = await completer.future;
      final items = sdkList.map(fromSdkMessage).whereType<ChatMessage>().toList();

      return ChatResult.success(
        ChatPage<ChatMessage>(
          items: items,
          olderCursor: items.isNotEmpty ? items.first.id : null,
          newerCursor: items.isNotEmpty ? items.last.id : null,
        ),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to fetch messages', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) async {
    try {
      final sdkMsg = toSdkMessage(message);
      final completer = Completer<cc.BaseMessage>();

      if (sdkMsg is cc.TextMessage) {
        unawaited(
          cc.CometChat.sendMessage(
            sdkMsg,
            onSuccess: (cc.TextMessage res) {
              if (!completer.isCompleted) completer.complete(res);
            },
            onError: (cc.CometChatException e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          ),
        );
      } else if (sdkMsg is cc.MediaMessage) {
        unawaited(
          cc.CometChat.sendMediaMessage(
            sdkMsg,
            onSuccess: (cc.MediaMessage res) {
              if (!completer.isCompleted) completer.complete(res);
            },
            onError: (cc.CometChatException e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          ),
        );
      } else if (sdkMsg is cc.CustomMessage) {
        unawaited(
          cc.CometChat.sendCustomMessage(
            sdkMsg,
            onSuccess: (cc.CustomMessage res) {
              if (!completer.isCompleted) completer.complete(res);
            },
            onError: (cc.CometChatException e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          ),
        );
      } else {
        throw UnsupportedError('Unsupported message type: ${message.runtimeType}');
      }

      final confirmed = await completer.future;
      final result = fromSdkMessage(confirmed);
      if (result != null) {
        return ChatResult.success(result);
      }
      return ChatResult.failure(
        const ChatError(ChatErrorCode.unknown, 'Failed to convert confirmed message'),
      );
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to send message', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> deleteMessage(String messageId) async {
    try {
      final intId = int.tryParse(messageId) ?? 0;
      final completer = Completer<void>();
      unawaited(
        cc.CometChat.deleteMessage(
          intId,
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
        ChatError(ChatErrorCode.network, e.message ?? 'Failed to delete message', cause: e),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> markAsDelivered(String messageId) async {
    try {
      final intId = int.tryParse(messageId) ?? 0;
      final dummy = cc.TextMessage(
        id: intId,
        receiverUid: '',
        type: 'text',
        receiverType: cc.CometChatReceiverType.user,
        text: '',
      );
      final completer = Completer<void>();
      unawaited(
        cc.CometChat.markAsDelivered(
          dummy,
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
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> markAsRead(String messageId) async {
    try {
      final intId = int.tryParse(messageId) ?? 0;
      final dummy = cc.TextMessage(
        id: intId,
        receiverUid: '',
        type: 'text',
        receiverType: cc.CometChatReceiverType.user,
        text: '',
      );
      final completer = Completer<void>();
      unawaited(
        cc.CometChat.markAsRead(
          dummy,
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
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping) async {
    try {
      final isGroup = conversationId.startsWith('group_');
      final withId = isGroup
          ? conversationId.replaceFirst('group_', '')
          : conversationId;
      final receiverType = isGroup
          ? cc.CometChatReceiverType.group
          : cc.CometChatReceiverType.user;

      if (isTyping) {
        await cc.CometChat.startTyping(
          receiverUid: withId,
          receiverType: receiverType,
        );
      } else {
        await cc.CometChat.endTyping(
          receiverUid: withId,
          receiverType: receiverType,
        );
      }
      return ChatResult.ok();
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.unknown, e.toString(), cause: e),
      );
    }
  }

  /// Direct SDK fetchPrevious (used for fallback by message list remote data source)
  Future<List<cc.BaseMessage>> fetchSdkPrevious(cc.MessagesRequest request) async {
    final completer = Completer<List<cc.BaseMessage>>();
    unawaited(
      request.fetchPrevious(
        onSuccess: (List<cc.BaseMessage> messages) {
          if (!completer.isCompleted) completer.complete(messages);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );
    return completer.future;
  }

  /// Direct SDK fetchNext (used for fallback by message list remote data source)
  Future<List<cc.BaseMessage>> fetchSdkNext(cc.MessagesRequest request) async {
    final completer = Completer<List<cc.BaseMessage>>();
    unawaited(
      request.fetchNext(
        onSuccess: (List<cc.BaseMessage> messages) {
          if (!completer.isCompleted) completer.complete(messages);
        },
        onError: (cc.CometChatException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      ),
    );
    return completer.future;
  }

  /// Direct SDK markAsRead
  Future<void> markSdkAsRead(cc.BaseMessage message) async {
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

  /// Direct SDK markAsDelivered
  Future<void> markSdkAsDelivered(cc.BaseMessage message) async {
    final completer = Completer<void>();
    await cc.CometChat.markAsDelivered(
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

  /// Direct SDK markMessageAsUnread
  Future<cc.Conversation> markSdkMessageAsUnread(cc.BaseMessage message) async {
    final completer = Completer<cc.Conversation>();
    await cc.CometChat.markMessageAsUnread(
      message,
      onSuccess: (cc.Conversation c) {
        if (!completer.isCompleted) completer.complete(c);
      },
      onError: (cc.CometChatException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Convert a ConvoKit ChatMessage to an SDK BaseMessage
  static cc.BaseMessage toSdkMessage(ChatMessage msg) {
    final senderUser = cc.User(
      uid: msg.sender.id,
      name: msg.sender.name,
      avatar: msg.sender.avatarUrl,
    );
    final isGroup = msg.conversationId.startsWith('group_');
    final receiverType = isGroup
        ? cc.CometChatReceiverType.group
        : cc.CometChatReceiverType.user;
    final receiverUid = isGroup
        ? msg.conversationId.replaceFirst('group_', '')
        : msg.conversationId;
    final intMsgId = int.tryParse(msg.id ?? '') ?? 0;

    switch (msg) {
      case TextMessage t:
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
      case MediaMessage m:
        return cc.MediaMessage(
          id: intMsgId,
          muid: m.localId,
          file: m.attachment.localPath ?? '',
          sender: senderUser,
          receiverUid: receiverUid,
          receiverType: receiverType,
          type: switch (m.attachment.kind) {
            AttachmentKind.image => 'image',
            AttachmentKind.video => 'video',
            AttachmentKind.audio => 'audio',
            AttachmentKind.file => 'file',
          },
          category: 'message',
          sentAt: m.serverCreatedAt ?? m.createdAt,
        );
      case CustomMessage c:
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

  /// Convert an SDK BaseMessage to a ConvoKit ChatMessage
  static ChatMessage? fromSdkMessage(cc.BaseMessage msg) {
    final senderEntity = _readNullable(() => msg.sender);
    final sender = ChatUser(
      id: senderEntity != null ? _read(() => senderEntity.uid, '') : '',
      name: senderEntity != null ? _read(() => senderEntity.name, '') : '',
      avatarUrl: senderEntity != null ? _readNullable(() => senderEntity.avatar) : null,
    );
    final id = _readNullable(() => msg.id.toString());
    final localId = _read(() => msg.muid, '');
    final effectiveLocalId = localId.isNotEmpty
        ? localId
        : (id != null ? 'sdk_$id' : 'msg_${DateTime.now().microsecondsSinceEpoch}');
    final createdAt = _read(() => msg.sentAt, DateTime.now());
    final receiverUid = _read(() => msg.receiverUid, '');
    final receiverType = _read(() => msg.receiverType, 'user');
    final conversationId = _read(
      () => msg.conversationId,
      receiverType == 'group' ? 'group_$receiverUid' : receiverUid,
    );

    if (msg is cc.TextMessage) {
      return TextMessage(
        id: id,
        localId: effectiveLocalId,
        conversationId: conversationId,
        sender: sender,
        createdAt: createdAt,
        serverCreatedAt: createdAt,
        sendState: SendState.sent,
        text: _read(() => msg.text, ''),
      );
    } else if (msg is cc.MediaMessage) {
      final attachmentUrl = _readNullable(() => msg.attachment?.fileUrl) ?? '';
      final mimeType = _readNullable(() => msg.attachment?.fileMimeType);
      final fileName = _readNullable(() => msg.attachment?.fileName);
      final fileSize = _readNullable(() => msg.attachment?.fileSize);
      final kind = switch (_read(() => msg.type, 'file')) {
        'image' => AttachmentKind.image,
        'video' => AttachmentKind.video,
        'audio' => AttachmentKind.audio,
        _ => AttachmentKind.file,
      };
      return MediaMessage(
        id: id,
        localId: effectiveLocalId,
        conversationId: conversationId,
        sender: sender,
        createdAt: createdAt,
        serverCreatedAt: createdAt,
        sendState: SendState.sent,
        attachment: ChatAttachment(
          id: id ?? effectiveLocalId,
          remoteId: id ?? effectiveLocalId,
          url: attachmentUrl.isNotEmpty ? attachmentUrl : 'https://placeholder.url',
          kind: kind,
          mimeType: mimeType ?? 'application/octet-stream',
          name: fileName,
          sizeBytes: fileSize,
          state: AttachmentState.uploaded,
        ),
      );
    } else if (msg is cc.CustomMessage) {
      return CustomMessage(
        id: id,
        localId: effectiveLocalId,
        conversationId: conversationId,
        sender: sender,
        createdAt: createdAt,
        serverCreatedAt: createdAt,
        sendState: SendState.sent,
        kind: _read(() => msg.subType, 'custom'),
        data: _readNullable(() => msg.customData) ?? const {},
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
