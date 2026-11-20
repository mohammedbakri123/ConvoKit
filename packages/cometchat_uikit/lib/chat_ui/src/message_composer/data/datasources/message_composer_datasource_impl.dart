import 'dart:async';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc hide CardMessage;
import 'package:convokit/convokit.dart' as ck;

import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../src/adapters/cometchat_message_adapter.dart';
import '../../../../../src/adapters/cometchat_sdk_adapter.dart';
import 'message_composer_datasource.dart';
import '../../../../../shared_ui/src/logging/cometchat_log.dart';

/// Implementation of MessageComposerDataSource using ConvoKit contracts with SDK fallback
class MessageComposerDataSourceImpl implements MessageComposerDataSource {
  final ck.MessageRepository? _messageRepository;
  final ck.ChatMediaProvider? _mediaProvider;

  MessageComposerDataSourceImpl({
    ck.MessageRepository? messageRepository,
    ck.ChatMediaProvider? mediaProvider,
  })  : _messageRepository = messageRepository,
        _mediaProvider = mediaProvider;

  ck.MessageRepository? get _effectiveMessageRepo =>
      _messageRepository ??
      ConvoKitUIKit.messageRepository ??
      ConvoKitUIKit.kit?.messages;

  ck.ChatMediaProvider? get _effectiveMediaProvider =>
      _mediaProvider ??
      ConvoKitUIKit.mediaProvider ??
      ConvoKitUIKit.kit?.media;

  @override
  Future<cc.TextMessage> sendTextMessage(cc.TextMessage message) async {
    final repo = _effectiveMessageRepo;
    if (repo != null) {
      final isGroup = message.receiverType == 'group';
      final convId =
          isGroup ? 'group_${message.receiverUid}' : message.receiverUid;
      final senderUser = ck.ChatUser(
        id: message.sender?.uid ?? '',
        name: message.sender?.name ?? '',
        avatarUrl: message.sender?.avatar,
      );
      final ckMsg = ck.TextMessage(
        localId: message.muid.isNotEmpty
            ? message.muid
            : 'msg_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: convId,
        sender: senderUser,
        createdAt: message.sentAt ?? DateTime.now(),
        text: message.text,
      );
      final res = await repo.sendMessage(ckMsg);
      return res.fold(
        onFailure: (err) => throw MessageComposerDataSourceException(
          message: err.message,
          code: err.code.name,
          originalException:
              err.cause is Exception ? err.cause as Exception : null,
        ),
        onSuccess: (sent) =>
            CometChatMessageAdapter.toSdkMessage(sent) as cc.TextMessage,
      );
    }

    final completer = Completer<cc.TextMessage>();
    unawaited(
      CometChatSdkAdapter.sendMessage(
        message,
        onSuccess: (cc.TextMessage sentMessage) {
          completer.complete(sentMessage);
        },
        onError: (cc.CometChatException e) {
          completer.completeError(
            MessageComposerDataSourceException(
              message: e.message ?? 'Failed to send text message',
              code: e.code,
              originalException: e,
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<cc.MediaMessage> sendMediaMessage(cc.MediaMessage message) async {
    final repo = _effectiveMessageRepo;
    final mediaProvider = _effectiveMediaProvider;

    if (repo != null) {
      if (mediaProvider == null) {
        throw const MessageComposerDataSourceException(
          message: 'Media provider is not configured',
          code: 'UNSUPPORTED',
        );
      }

      final attachmentKind = switch (message.type) {
        'image' => ck.AttachmentKind.image,
        'video' => ck.AttachmentKind.video,
        'audio' => ck.AttachmentKind.audio,
        _ => ck.AttachmentKind.file,
      };
      final filePath = (message.file != null && message.file!.isNotEmpty)
          ? message.file!
          : (message.attachment?.fileUrl != null &&
                  message.attachment!.fileUrl.isNotEmpty)
              ? message.attachment!.fileUrl
              : 'local_file';
      final attId = 'att_${DateTime.now().microsecondsSinceEpoch}';

      // 1. Initial local state
      var attachment = ck.ChatAttachment(
        id: attId,
        kind: attachmentKind,
        localPath: filePath,
        state: ck.AttachmentState.local,
      );

      // 2. Uploading state
      attachment = ck.ChatAttachment(
        id: attId,
        kind: attachmentKind,
        localPath: filePath,
        state: ck.AttachmentState.uploading,
        uploadProgress: 0.0,
      );

      final uploadReq = ck.UploadRequest.file(
        filePath,
        kind: attachmentKind,
        mimeType: message.attachment?.fileMimeType,
        name: message.attachment?.fileName,
      );

      final uploadResult = await mediaProvider.upload(
        uploadReq,
        onProgress: (progress) {
          // Upload progress updates
        },
      );

      final uploadedMedia = uploadResult.fold(
        onFailure: (err) {
          if (err.code == ck.ChatErrorCode.cancelled) {
            // Cancel deletes pending message entirely (no drafts)
            throw const MessageComposerDataSourceException(
              message: 'Upload cancelled',
              code: 'CANCELLED',
            );
          }
          // Failed attachment state
          attachment = ck.ChatAttachment(
            id: attId,
            kind: attachmentKind,
            localPath: filePath,
            state: ck.AttachmentState.failed,
            uploadFailure: err,
          );
          throw MessageComposerDataSourceException(
            message: err.message,
            code: 'UPLOAD_FAILED',
            originalException:
                err.cause is Exception ? err.cause as Exception : null,
          );
        },
        onSuccess: (uploaded) => uploaded,
      );

      // 3. Uploaded state
      attachment = ck.ChatAttachment(
        id: attId,
        remoteId: uploadedMedia.id,
        kind: attachmentKind,
        localPath: filePath,
        url: uploadedMedia.url,
        thumbnailUrl: uploadedMedia.thumbnailUrl,
        mimeType: uploadedMedia.mimeType,
        sizeBytes: uploadedMedia.sizeBytes,
        name: uploadedMedia.name,
        state: ck.AttachmentState.uploaded,
      );

      // 4. Send step (separate from upload)
      final isGroup = message.receiverType == 'group';
      final convId =
          isGroup ? 'group_${message.receiverUid}' : message.receiverUid;
      final senderUser = ck.ChatUser(
        id: message.sender?.uid ?? '',
        name: message.sender?.name ?? '',
        avatarUrl: message.sender?.avatar,
      );
      final ckMediaMsg = ck.MediaMessage(
        localId: message.muid.isNotEmpty
            ? message.muid
            : 'msg_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: convId,
        sender: senderUser,
        createdAt: message.sentAt ?? DateTime.now(),
        attachment: attachment,
        caption: message.caption,
      );

      final sendResult = await repo.sendMessage(ckMediaMsg);
      return sendResult.fold(
        onFailure: (err) {
          // Distinct send-failure state (attachment remains uploaded)
          throw MessageComposerDataSourceException(
            message: err.message,
            code: 'SEND_FAILED',
            originalException:
                err.cause is Exception ? err.cause as Exception : null,
          );
        },
        onSuccess: (sentMsg) =>
            CometChatMessageAdapter.toSdkMessage(sentMsg) as cc.MediaMessage,
      );
    }

    final completer = Completer<cc.MediaMessage>();

    ccLog(
      '[ComposerDatasource] sendMediaMessage — file: ${message.file}, type: ${message.type}',
    );

    await CometChatSdkAdapter.sendMediaMessage(
      message,
      onSuccess: (cc.MediaMessage sentMessage) {
        ccLog(
          '[ComposerDatasource] sendMediaMessage SUCCESS — id: ${sentMessage.id}, attachment: ${sentMessage.attachment?.fileUrl}',
        );
        completer.complete(sentMessage);
      },
      onError: (cc.CometChatException e) {
        ccLog(
          '[ComposerDatasource] sendMediaMessage ERROR — code: ${e.code}, message: ${e.message}, details: ${e.details}',
        );
        completer.completeError(
          MessageComposerDataSourceException(
            message: e.message ?? 'Failed to send media message',
            code: e.code,
            originalException: e,
          ),
        );
      },
    );

    return completer.future;
  }

  @override
  Future<cc.CustomMessage> sendCustomMessage(cc.CustomMessage message) async {
    final repo = _effectiveMessageRepo;
    if (repo != null) {
      final isGroup = message.receiverType == 'group';
      final convId =
          isGroup ? 'group_${message.receiverUid}' : message.receiverUid;
      final senderUser = ck.ChatUser(
        id: message.sender?.uid ?? '',
        name: message.sender?.name ?? '',
        avatarUrl: message.sender?.avatar,
      );
      final subType = (message.subType != null && message.subType!.isNotEmpty)
          ? message.subType!
          : 'custom';
      final ckMsg = ck.CustomMessage(
        localId: message.muid.isNotEmpty
            ? message.muid
            : 'msg_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: convId,
        sender: senderUser,
        createdAt: message.sentAt ?? DateTime.now(),
        kind: subType,
        data: message.customData ?? const {},
      );
      final res = await repo.sendMessage(ckMsg);
      return res.fold(
        onFailure: (err) => throw MessageComposerDataSourceException(
          message: err.message,
          code: err.code.name,
          originalException:
              err.cause is Exception ? err.cause as Exception : null,
        ),
        onSuccess: (sent) =>
            CometChatMessageAdapter.toSdkMessage(sent) as cc.CustomMessage,
      );
    }

    final completer = Completer<cc.CustomMessage>();

    unawaited(
      CometChatSdkAdapter.sendCustomMessage(
        message,
        onSuccess: (cc.CustomMessage sentMessage) {
          completer.complete(sentMessage);
        },
        onError: (cc.CometChatException e) {
          completer.completeError(
            MessageComposerDataSourceException(
              message: e.message ?? 'Failed to send custom message',
              code: e.code,
              originalException: e,
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<cc.BaseMessage> editMessage(cc.BaseMessage message) async {
    final completer = Completer<cc.BaseMessage>();

    unawaited(
      CometChatSdkAdapter.editMessage(
        message,
        onSuccess: (cc.BaseMessage editedMessage) {
          completer.complete(editedMessage);
        },
        onError: (cc.CometChatException e) {
          completer.completeError(
            MessageComposerDataSourceException(
              message: e.message ?? 'Failed to edit message',
              code: e.code,
              originalException: e,
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  @override
  void startTyping({
    required String receiverUid,
    required String receiverType,
  }) {
    final repo = _effectiveMessageRepo;
    if (repo != null) {
      final convId =
          receiverType == 'group' ? 'group_$receiverUid' : receiverUid;
      unawaited(repo.sendTyping(convId, true));
      return;
    }
    CometChatSdkAdapter.startTyping(
      receiverUid: receiverUid,
      receiverType: receiverType,
    );
  }

  @override
  void endTyping({required String receiverUid, required String receiverType}) {
    final repo = _effectiveMessageRepo;
    if (repo != null) {
      final convId =
          receiverType == 'group' ? 'group_$receiverUid' : receiverUid;
      unawaited(repo.sendTyping(convId, false));
      return;
    }
    CometChatSdkAdapter.endTyping(
      receiverUid: receiverUid,
      receiverType: receiverType,
    );
  }

  @override
  Future<cc.User?> getLoggedInUser() async {
    final session = ConvoKitUIKit.session ?? ConvoKitUIKit.kit?.session;
    if (session?.currentUser != null) {
      final u = session!.currentUser!;
      return cc.User(uid: u.id, name: u.name, avatar: u.avatarUrl);
    }
    return await CometChatSdkAdapter.getLoggedInUser();
  }
}
