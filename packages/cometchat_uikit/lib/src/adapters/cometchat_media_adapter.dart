// ignore_for_file: public_member_api_docs
/// Internal adapter adapting the CometChat SDK into ConvoKit's [ChatMediaProvider].
library;

import 'dart:async';
import 'dart:io' if (dart.library.html) '';
import 'package:flutter/foundation.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart' as cc;

import '../contracts/media_provider.dart';
import '../contracts/result.dart';
import 'cometchat_sdk_adapter.dart';

class CometChatMediaAdapter implements ChatMediaProvider {
  final String defaultReceiverId;
  final String defaultReceiverType;

  CometChatMediaAdapter({
    this.defaultReceiverId = 'system',
    this.defaultReceiverType = 'user',
  });

  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
      );
    }

    try {
      final String fileName = request.name ??
          (request.localPath != null
              ? request.localPath!.split(RegExp(r'[/\\]')).last
              : 'upload');
      final String mimeType = request.mimeType ?? 'application/octet-stream';

      int size = 0;
      if (!kIsWeb && request.localPath != null) {
        try {
          final file = File(request.localPath!);
          if (file.existsSync()) {
            size = file.lengthSync();
          }
        } catch (_) {}
      }
      if (size == 0 && request.bytes != null) {
        size = request.bytes!.length;
      }
      if (size <= 0) size = 1;

      final cc.UploadFile uploadFile = request.bytes != null
          ? cc.UploadFile.fromBytes(
              request.bytes!,
              name: fileName,
              size: size,
              mimeType: mimeType,
            )
          : cc.UploadFile.fromPath(
              request.localPath!,
              name: fileName,
              size: size,
              mimeType: mimeType,
            );

      final req = CometChatSdkAdapter.createUploadFileRequest(
        defaultReceiverId,
        defaultReceiverType,
      );

      final completer = Completer<ChatResult<UploadedMedia>>();
      final fileId = 'media_${DateTime.now().microsecondsSinceEpoch}';

      req.uploadAttachment(
        fileId,
        uploadFile,
        _MediaUploadListener(
          fileId: fileId,
          req: req,
          request: request,
          cancel: cancel,
          onProgress: onProgress,
          completer: completer,
        ),
      );

      return await completer.future;
    } on cc.CometChatException catch (e) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.uploadFailed,
          e.message ?? 'Upload failed',
          cause: e,
        ),
      );
    } catch (e) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.uploadFailed, e.toString(), cause: e),
      );
    }
  }

  @override
  Future<ChatResult<void>> delete(String mediaId) async {
    return ChatResult.ok();
  }
}

class _MediaUploadListener extends cc.UploadFileListener {
  final String fileId;
  final cc.UploadFileRequest req;
  final UploadRequest request;
  final CancellationToken? cancel;
  final void Function(UploadProgress progress)? onProgress;
  final Completer<ChatResult<UploadedMedia>> completer;

  _MediaUploadListener({
    required this.fileId,
    required this.req,
    required this.request,
    this.cancel,
    this.onProgress,
    required this.completer,
  });

  @override
  void onFileProgress(String id, int loaded, int total, int percent) {
    if (id != fileId) return;
    if (cancel?.isCancelled ?? false) {
      req.removeAttachment(id);
      if (!completer.isCompleted) {
        completer.complete(
          const ChatResult.failure(
            ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
          ),
        );
      }
      return;
    }
    onProgress?.call(UploadProgress(sentBytes: loaded, totalBytes: total));
  }

  @override
  void onFileUploaded(String id, cc.Attachment attachment) {
    if (id != fileId) return;
    if (!completer.isCompleted) {
      completer.complete(
        ChatResult.success(
          UploadedMedia(
            id: id,
            url: attachment.fileUrl,
            name: attachment.fileName,
            mimeType: attachment.fileMimeType,
            sizeBytes: attachment.fileSize,
            thumbnailUrl: attachment.fileUrl,
          ),
        ),
      );
    }
  }

  @override
  void onFileFailure(String id, cc.CometChatException error) {
    if (id != fileId) return;
    if (!completer.isCompleted) {
      completer.complete(
        ChatResult.failure(
          ChatError(
            ChatErrorCode.uploadFailed,
            error.message ?? 'Upload failed',
            cause: error,
          ),
        ),
      );
    }
  }

  @override
  void onFileError(String id, cc.CometChatException error) {
    if (id != fileId) return;
    if (!completer.isCompleted) {
      completer.complete(
        ChatResult.failure(
          ChatError(
            ChatErrorCode.uploadFailed,
            error.message ?? 'Upload error',
            cause: error,
          ),
        ),
      );
    }
  }
}
