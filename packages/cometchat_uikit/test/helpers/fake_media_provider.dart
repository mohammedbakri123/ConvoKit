// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:convokit/convokit.dart';

/// Controllable in-memory [ChatMediaProvider] harness for unit and widget tests.
///
/// Replaces `fake_upload_sdk.dart` with zero legacy SDK imports. Supports:
/// - Synchronous or deferred (manual-completer) uploads
/// - Scripted progress callbacks ([UploadProgress])
/// - Failure injection (network error, validation rejection, cancellation)
/// - Call counters and recorded [UploadRequest]s
class FakeChatMediaProvider implements ChatMediaProvider {
  int uploadCallCount = 0;
  int deleteCallCount = 0;
  final List<UploadRequest> uploadedRequests = [];
  final List<String> deletedMediaIds = [];
  final List<PendingUpload> pendingUploads = [];

  /// When true, uploads stay pending in [pendingUploads] until manually driven.
  bool manualCompletion = false;

  /// When non-null, the next upload fails with this error (cleared after use).
  ChatError? nextUploadError;

  /// Optional progress steps emitted before automatic completion.
  List<UploadProgress> autoProgressSteps = const [];

  int _seq = 0;

  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    uploadCallCount++;
    uploadedRequests.add(request);

    if (cancel?.isCancelled ?? false) {
      return ChatResult.failure(
        const ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
      );
    }

    if (manualCompletion) {
      final completer = Completer<ChatResult<UploadedMedia>>();
      pendingUploads.add(
        PendingUpload(
          request: request,
          onProgress: onProgress,
          cancel: cancel,
          completer: completer,
        ),
      );
      return completer.future;
    }

    for (final step in autoProgressSteps) {
      if (cancel?.isCancelled ?? false) {
        return ChatResult.failure(
          const ChatError(ChatErrorCode.cancelled, 'Upload cancelled'),
        );
      }
      onProgress?.call(step);
    }

    if (nextUploadError != null) {
      final err = nextUploadError!;
      nextUploadError = null;
      return ChatResult.failure(err);
    }

    final id = 'media_${++_seq}';
    return ChatResult.success(
      UploadedMedia(
        id: id,
        url: 'https://cdn.example.com/$id/${request.name ?? 'file'}',
        thumbnailUrl: request.kind == AttachmentKind.image
            ? 'https://cdn.example.com/$id/thumb.png'
            : null,
        mimeType: request.mimeType,
        sizeBytes: request.bytes?.length ?? 1024,
        name: request.name,
      ),
    );
  }

  @override
  Future<ChatResult<void>> delete(String mediaId) async {
    deleteCallCount++;
    deletedMediaIds.add(mediaId);
    return ChatResult.ok();
  }
}

class PendingUpload {
  PendingUpload({
    required this.request,
    required this.onProgress,
    required this.cancel,
    required this.completer,
  });

  final UploadRequest request;
  final void Function(UploadProgress progress)? onProgress;
  final CancellationToken? cancel;
  final Completer<ChatResult<UploadedMedia>> completer;

  void emitProgress(int sentBytes, int totalBytes) {
    onProgress?.call(
      UploadProgress(sentBytes: sentBytes, totalBytes: totalBytes),
    );
  }

  void completeSuccess({
    String id = 'media_1',
    String? url,
  }) {
    if (completer.isCompleted) return;
    completer.complete(
      ChatResult.success(
        UploadedMedia(
          id: id,
          url: url ?? 'https://cdn.example.com/$id/${request.name ?? 'file'}',
          mimeType: request.mimeType,
          sizeBytes: request.bytes?.length ?? 1024,
          name: request.name,
        ),
      ),
    );
  }

  void completeFailure(ChatError error) {
    if (completer.isCompleted) return;
    completer.complete(ChatResult.failure(error));
  }
}
