import 'package:convokit/convokit.dart';

/// Offline simulated [ChatMediaProvider] for Atelier Studio.
///
/// Emits incremental [UploadProgress] callbacks, honors [CancellationToken]
/// cleanly without throwing, stores [UploadedMedia] metadata in memory, and
/// supports [delete].
class StudioMediaProvider implements ChatMediaProvider {
  StudioMediaProvider({
    this.stepDelay = const Duration(milliseconds: 20),
    this.progressSteps = 4,
  }) : assert(progressSteps > 0, 'progressSteps must be greater than 0');

  /// Delay between simulated upload progress ticks.
  final Duration stepDelay;

  /// Number of incremental progress updates emitted before completion.
  final int progressSteps;

  final Map<String, UploadedMedia> _uploadedMedia = <String, UploadedMedia>{};
  int _nextMediaId = 1;

  /// Returns the currently stored media record for [mediaId], if any.
  UploadedMedia? getMediaSync(String mediaId) => _uploadedMedia[mediaId];

  /// Clears all simulated uploaded media records and resets ID sequence.
  void reset() {
    _uploadedMedia.clear();
    _nextMediaId = 1;
  }

  @override
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.cancelled, 'Media upload was cancelled.'),
      );
    }

    final totalBytes = request.bytes?.length ?? _defaultSizeForKind(request.kind);
    final resolvedName = _resolveFileName(request);
    final resolvedMime = request.mimeType ?? _defaultMimeForKind(request.kind);

    for (var step = 1; step <= progressSteps; step++) {
      if (stepDelay > Duration.zero) {
        await Future<void>.delayed(stepDelay);
      }
      if (cancel?.isCancelled ?? false) {
        return const ChatResult.failure(
          ChatError(ChatErrorCode.cancelled, 'Media upload was cancelled.'),
        );
      }

      final sentBytes = step == progressSteps
          ? totalBytes
          : (totalBytes * step) ~/ progressSteps;
      onProgress?.call(
        UploadProgress(sentBytes: sentBytes, totalBytes: totalBytes),
      );
    }

    final id = 'media_studio_${_nextMediaId++}';
    final url = 'https://atelier.studio/uploads/$id/$resolvedName';
    final thumbnailUrl =
        request.kind == AttachmentKind.image ||
            request.kind == AttachmentKind.video
        ? 'https://atelier.studio/uploads/$id/thumb_$resolvedName'
        : null;

    final uploaded = UploadedMedia(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      mimeType: resolvedMime,
      sizeBytes: totalBytes,
      name: resolvedName,
    );
    _uploadedMedia[id] = uploaded;
    return ChatResult.success(uploaded);
  }

  @override
  Future<ChatResult<void>> delete(String mediaId) async {
    final removed = _uploadedMedia.remove(mediaId);
    if (removed == null) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Media "$mediaId" not found.'),
      );
    }
    return ChatResult.ok();
  }

  int _defaultSizeForKind(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => 480000,
    AttachmentKind.video => 3200000,
    AttachmentKind.audio => 240000,
    AttachmentKind.file => 640000,
  };

  String _defaultMimeForKind(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => 'image/png',
    AttachmentKind.video => 'video/mp4',
    AttachmentKind.audio => 'audio/m4a',
    AttachmentKind.file => 'application/octet-stream',
  };

  String _resolveFileName(UploadRequest request) {
    if (request.name != null && request.name!.trim().isNotEmpty) {
      return request.name!.trim();
    }
    final localPath = request.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      final segments = localPath.split(RegExp(r'[/\\]'));
      final candidate = segments.last.trim();
      if (candidate.isNotEmpty) return candidate;
    }
    return switch (request.kind) {
      AttachmentKind.image => 'studio_image.png',
      AttachmentKind.video => 'studio_clip.mp4',
      AttachmentKind.audio => 'studio_voice_note.m4a',
      AttachmentKind.file => 'studio_attachment.bin',
    };
  }
}
