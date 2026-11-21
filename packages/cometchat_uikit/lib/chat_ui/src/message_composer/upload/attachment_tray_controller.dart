import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared_ui/src/clean_architecture/core/utils/platform_utils/platform_file_utils.dart'
    as platform;
import '../../../../shared_ui/src/logging/cometchat_log.dart';

/// Lifecycle state for a single staged tile in [AttachmentTrayController].
///
/// Preserves distinct [failed] (upload failed -> retry re-uploads) vs.
/// [sendFailed] (upload succeeded, message send failed -> retry sends without
/// re-uploading) states per API-DESIGN.md §§6–7.
enum AttachmentTileStatus { uploading, done, failed, sendFailed, rejected }

/// Plain-Dart input describing a local file or in-memory byte buffer to stage
/// in [AttachmentTrayController].
class StagedUploadFile {
  const StagedUploadFile({
    required this.name,
    required this.mimeType,
    required this.size,
    this.path,
    this.bytes,
  }) : assert(
         (path != null && path.length > 0) || bytes != null,
         'Either a non-empty file path or bytes must be provided',
       );

  final String name;
  final String mimeType;
  final int size;
  final String? path;
  final Uint8List? bytes;

  AttachmentKind get kind => AttachmentTrayController.classifyKind(mimeType, name);
}

/// Thrown by [AttachmentTrayController.stage] when a batch cannot be staged
/// (missing conversation context or unavailable [ChatMediaProvider]).
class AttachmentStageException implements Exception {
  AttachmentStageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AttachmentStageException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// One staged item in the composer attachment tray, keyed by client-generated [fileId].
class AttachmentTile {
  AttachmentTile({
    required this.fileId,
    required this.name,
    required this.mimeType,
    required this.size,
    this.localPath,
    this.bytes,
    this.loaded = 0,
    this.status = AttachmentTileStatus.uploading,
    this.thumbUrl,
    this.attachment,
    this.durationMillis,
    this.errorMessage,
    this.failure,
  });

  final String fileId;
  final String name;
  final String mimeType;
  final int size;
  final String? localPath;
  final Uint8List? bytes;

  /// Human-readable reason this tile failed or was rejected.
  String? errorMessage;

  /// Structured [ChatError] from upload or send failure.
  ChatError? failure;

  /// Video/audio playback length in milliseconds, probed from the local source.
  int? durationMillis;

  /// Bytes uploaded so far.
  int loaded;
  AttachmentTileStatus status;

  /// Local preview path/object URL while uploading; remote URL fallback once done.
  String? thumbUrl;

  /// Populated once upload completes (`state == AttachmentState.uploaded`).
  /// Retained across send failures so retrying send does not re-upload.
  ChatAttachment? attachment;

  int get percent =>
      size == 0 ? 0 : ((loaded / size) * 100).clamp(0, 100).round();

  AttachmentKind get kind => AttachmentTrayController.classifyKind(mimeType, name);

  bool get isImage => AttachmentTrayController.isImageType(mimeType, name);
  bool get isAudio => AttachmentTrayController.isAudioType(mimeType, name);
  bool get isVideo =>
      !isAudio && AttachmentTrayController.isVideoType(mimeType, name);

  /// True for a failed upload, failed send, or rejected tile.
  bool get hasError =>
      status == AttachmentTileStatus.failed ||
      status == AttachmentTileStatus.sendFailed ||
      status == AttachmentTileStatus.rejected;

  /// True when upload succeeded and only sending the message failed.
  bool get isSendFailed => status == AttachmentTileStatus.sendFailed;

  /// True when upload itself failed (retry re-runs upload).
  bool get isUploadFailed => status == AttachmentTileStatus.failed;
}

/// Owns the composer's multi-attachment staging tray and drives the two-step
/// ConvoKit media flow:
/// 1. Upload via [ChatMediaProvider.upload] (`UploadRequest.file` / `UploadRequest.bytes`)
///    with live [UploadProgress] callbacks and per-tile [CancellationToken].
/// 2. Send via [MessageCoordinator.sendMediaMessage] using the uploaded [ChatAttachment].
///
/// Cancelling an in-flight upload cancels its [CancellationToken] and deletes
/// the pending tile immediately. Upload failures (`failed`) and send failures
/// (`sendFailed`) are tracked distinctly so retrying a send failure never
/// re-uploads already uploaded media.
class AttachmentTrayController extends ChangeNotifier {
  AttachmentTrayController({
    this.mediaProvider,
    this.conversationId,
    int maxFileCount = 10,
    int maxFileSize = 100 * 1024 * 1024,
  }) : _maxFileCount = maxFileCount,
       _maxFileSize = maxFileSize;

  static const Set<String> _imageExts = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'svg',
  };
  static const Set<String> _videoExts = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v',
  };
  static const Set<String> _audioExts = {
    'mp3', 'wav', 'aac', 'm4a', 'ogg', 'opus', 'flac', 'amr',
  };

  static bool isImageType(String mimeType, String name) {
    final lowerMime = mimeType.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return lowerMime.startsWith('image/') || _imageExts.contains(ext);
  }

  static bool isAudioType(String mimeType, String name) {
    final lowerMime = mimeType.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return ext == 'ogg' ||
        lowerMime.startsWith('audio/') ||
        _audioExts.contains(ext);
  }

  static bool isVideoType(String mimeType, String name) {
    final lowerMime = mimeType.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return lowerMime.startsWith('video/') || _videoExts.contains(ext);
  }

  /// Classifies a file by MIME type or filename extension.
  static AttachmentKind classifyKind(String mimeType, String name) {
    if (isAudioType(mimeType, name)) return AttachmentKind.audio;
    if (isImageType(mimeType, name)) return AttachmentKind.image;
    if (isVideoType(mimeType, name)) return AttachmentKind.video;
    return AttachmentKind.file;
  }

  /// Active [ChatMediaProvider] from [ConvoKit.media]. Null when media is unsupported.
  ChatMediaProvider? mediaProvider;

  /// Active conversation id bound by the composer.
  String? conversationId;

  final int _maxFileCount;
  final int _maxFileSize;

  int _tileSeq = 0;
  int _localRejectSeq = 0;
  final List<AttachmentTile> _tiles = [];
  final Map<String, CancellationToken> _activeTokens = {};
  final Map<String, String> _failedSendLocalIds = {};

  List<AttachmentTile> get tiles => List.unmodifiable(_tiles);

  String caption = '';
  bool _disposed = false;

  /// Send is enabled once >=1 tile is `done`, none are `uploading`, and none
  /// are in an error state.
  bool get canSend =>
      _tiles.any((t) => t.status == AttachmentTileStatus.done) &&
      !_tiles.any((t) => t.status == AttachmentTileStatus.uploading) &&
      !hasErrors;

  int get maxFileCount => _maxFileCount;
  int get maxFileSize => _maxFileSize;

  /// Tiles that count against [maxFileCount] (excludes rejected tiles).
  int get activeCount =>
      _tiles.where((t) => t.status != AttachmentTileStatus.rejected).length;

  int get remainingSlots {
    final left = maxFileCount - activeCount;
    return left > 0 ? left : 0;
  }

  bool get canAddMore => remainingSlots > 0;

  List<AttachmentTile> get errorTiles =>
      _tiles.where((t) => t.hasError).toList();

  bool get hasErrors => errorTiles.isNotEmpty;

  /// Byte-weighted aggregate `[loaded, total]`.
  List<int> get aggregate {
    var loaded = 0, total = 0;
    for (final t in _tiles) {
      loaded += t.loaded;
      total += t.size;
    }
    return [loaded, total];
  }

  /// The uploaded [ChatAttachment]s ready to send, in tile order.
  List<ChatAttachment> get doneAttachments => _tiles
      .where(
        (t) => t.status == AttachmentTileStatus.done && t.attachment != null,
      )
      .map((t) => t.attachment!)
      .toList();

  AttachmentTile? _byId(String fileId) {
    for (final t in _tiles) {
      if (t.fileId == fileId) return t;
    }
    return null;
  }

  /// Stages a batch of files and starts uploading each via [mediaProvider].
  Future<void> stage(List<StagedUploadFile> files) async {
    if (files.isEmpty) return;
    if ((conversationId ?? '').isEmpty) {
      throw AttachmentStageException(
        'No conversation context (conversationId) for upload',
      );
    }
    final provider = mediaProvider;
    if (provider == null) {
      throw AttachmentStageException(
        'Media uploads are not supported by the active ConvoKit backend',
      );
    }

    final stagedTiles = <AttachmentTile>[];
    for (final f in files) {
      if (f.size > maxFileSize) {
        addLimitRejected(
          f,
          'File exceeds maximum size of ${(maxFileSize / (1024 * 1024)).round()} MB',
        );
        continue;
      }
      if (activeCount >= maxFileCount) {
        addLimitRejected(f, 'Maximum of $maxFileCount attachments reached');
        continue;
      }

      final id = 'tile_${_tileSeq++}';
      final kind = f.kind;
      final isMedia =
          kind == AttachmentKind.image ||
          kind == AttachmentKind.video ||
          kind == AttachmentKind.audio;
      final localThumb = (f.path != null && f.path!.isNotEmpty)
          ? f.path
          : (isMedia && f.bytes != null
                ? platform.objectUrlFromBytes(f.bytes!, f.mimeType)
                : null);

      final tile = AttachmentTile(
        fileId: id,
        name: f.name,
        mimeType: f.mimeType,
        size: f.size,
        localPath: f.path,
        bytes: f.bytes,
        thumbUrl: localThumb,
      );
      _tiles.add(tile);
      stagedTiles.add(tile);

      if ((tile.isVideo || tile.isAudio) &&
          localThumb != null &&
          localThumb.isNotEmpty) {
        unawaited(_probeDuration(tile, localThumb));
      }
    }
    _safeNotify();

    await Future.wait(stagedTiles.map((tile) => _uploadTile(tile, provider)));
  }

  Future<void> _uploadTile(
    AttachmentTile tile,
    ChatMediaProvider provider,
  ) async {
    final token = CancellationToken();
    _activeTokens[tile.fileId] = token;

    final request = (tile.localPath != null && tile.localPath!.isNotEmpty)
        ? UploadRequest.file(
            tile.localPath!,
            kind: tile.kind,
            mimeType: tile.mimeType,
            name: tile.name,
          )
        : UploadRequest.bytes(
            tile.bytes!,
            kind: tile.kind,
            mimeType: tile.mimeType,
            name: tile.name,
          );

    try {
      final result = await provider.upload(
        request,
        cancel: token,
        onProgress: (UploadProgress progress) {
          if (_disposed || token.isCancelled) return;
          final live = _byId(tile.fileId);
          if (live == null) return;
          live.loaded = progress.sentBytes;
          _safeNotify();
        },
      );

      _activeTokens.remove(tile.fileId);
      if (_disposed) return;

      final live = _byId(tile.fileId);
      if (live == null) return;

      if (token.isCancelled) {
        _removeTileInternal(tile.fileId);
        return;
      }

      result.fold(
        onSuccess: (UploadedMedia uploaded) {
          live.status = AttachmentTileStatus.done;
          live.loaded = live.size;
          live.errorMessage = null;
          live.failure = null;
          live.attachment = ChatAttachment(
            id: live.fileId,
            remoteId: uploaded.id,
            kind: live.kind,
            localPath: live.localPath,
            url: uploaded.url,
            thumbnailUrl: uploaded.thumbnailUrl,
            state: AttachmentState.uploaded,
            mimeType: uploaded.mimeType ?? live.mimeType,
            sizeBytes: uploaded.sizeBytes ?? live.size,
            name: uploaded.name ?? live.name,
          );
          live.thumbUrl ??= uploaded.url;
          _safeNotify();
        },
        onFailure: (ChatError error) {
          if (error.code == ChatErrorCode.cancelled || token.isCancelled) {
            _removeTileInternal(tile.fileId);
            return;
          }
          ccLog(
            '[AttachmentTrayController] Upload failed for ${tile.fileId}: ${error.code} ${error.message}',
          );
          live.status = error.code == ChatErrorCode.validation
              ? AttachmentTileStatus.rejected
              : AttachmentTileStatus.failed;
          live.errorMessage = error.message;
          live.failure = error;
          _safeNotify();
        },
      );
    } catch (e) {
      _activeTokens.remove(tile.fileId);
      if (_disposed) return;
      final live = _byId(tile.fileId);
      if (live == null) return;
      if (token.isCancelled) {
        _removeTileInternal(tile.fileId);
        return;
      }
      live.status = AttachmentTileStatus.failed;
      live.errorMessage = e.toString();
      live.failure = ChatError(ChatErrorCode.network, e.toString());
      _safeNotify();
    }
  }

  /// Adds a client-side-rejected tile (over max count or size) without uploading.
  void addLimitRejected(StagedUploadFile file, String reason) {
    final kind = file.kind;
    final isMedia =
        kind == AttachmentKind.image ||
        kind == AttachmentKind.video ||
        kind == AttachmentKind.audio;
    final localThumb = (file.path != null && file.path!.isNotEmpty)
        ? file.path
        : (isMedia && file.bytes != null
              ? platform.objectUrlFromBytes(file.bytes!, file.mimeType)
              : null);
    _tiles.add(
      AttachmentTile(
        fileId: 'local_reject_${_localRejectSeq++}',
        name: file.name,
        mimeType: file.mimeType,
        size: file.size,
        localPath: file.path,
        bytes: file.bytes,
        thumbUrl: localThumb,
        status: AttachmentTileStatus.rejected,
        errorMessage: reason,
        failure: ChatError(ChatErrorCode.validation, reason),
      ),
    );
    _safeNotify();
  }

  /// Sends all uploaded (`done`) tiles via [MessageCoordinator.sendMediaMessage].
  ///
  /// Because each tile's [ChatAttachment] already has
  /// `state == AttachmentState.uploaded`, [MessageCoordinator.sendMediaMessage]
  /// sends the message directly without re-uploading. If sending fails for a
  /// tile, that tile transitions to [AttachmentTileStatus.sendFailed] while
  /// retaining its uploaded [ChatAttachment] so a retry only re-sends.
  Future<List<ChatResult<ChatMessage>>> sendAll({
    required MessageCoordinator coordinator,
    required String conversationId,
    required ChatUser sender,
    ChatMessage? repliedTo,
  }) async {
    final sendable = _tiles
        .where(
          (t) =>
              (t.status == AttachmentTileStatus.done ||
                  t.status == AttachmentTileStatus.sendFailed) &&
              t.attachment != null,
        )
        .toList();
    if (sendable.isEmpty) return const [];

    final cap = caption.trim();
    final results = <ChatResult<ChatMessage>>[];
    final succeededIds = <String>[];

    for (var i = 0; i < sendable.length; i++) {
      final tile = sendable[i];
      final isLast = i == sendable.length - 1;
      final existingLocalId = _failedSendLocalIds[tile.fileId];

      final res = existingLocalId != null
          ? await coordinator.retryFailed(
              existingLocalId,
              conversationId: conversationId,
            )
          : await coordinator.sendMediaMessage(
              conversationId: conversationId,
              attachment: tile.attachment!,
              sender: sender,
              caption: isLast && cap.isNotEmpty ? cap : null,
              repliedTo: repliedTo,
              localId: 'tray_${tile.fileId}',
            );

      results.add(res);
      res.fold(
        onSuccess: (_) {
          _failedSendLocalIds.remove(tile.fileId);
          succeededIds.add(tile.fileId);
        },
        onFailure: (ChatError error) {
          _failedSendLocalIds[tile.fileId] =
              existingLocalId ?? 'tray_${tile.fileId}';
          tile.status = AttachmentTileStatus.sendFailed;
          tile.errorMessage = error.message;
          tile.failure = error;
        },
      );
    }

    for (final id in succeededIds) {
      _removeTileInternal(id, notify: false);
    }
    if (_tiles.isEmpty) {
      caption = '';
    }
    _safeNotify();
    return results;
  }

  /// Cancels an in-flight upload (deleting the pending tile) or removes a tile.
  Future<void> cancelOrRemove(String fileId) async {
    final token = _activeTokens.remove(fileId);
    token?.cancel();
    _failedSendLocalIds.remove(fileId);
    _removeTileInternal(fileId);
  }

  /// Retries a failed tile:
  /// - If [AttachmentTileStatus.failed] (upload failed): re-runs [mediaProvider.upload].
  /// - If [AttachmentTileStatus.sendFailed] (send failed after upload): marks
  ///   tile back to [AttachmentTileStatus.done] (or immediately re-sends when
  ///   [coordinator] + [sender] are supplied) without re-uploading.
  Future<void> retry(
    String fileId, {
    MessageCoordinator? coordinator,
    ChatUser? sender,
    ChatMessage? repliedTo,
  }) async {
    final tile = _byId(fileId);
    if (tile == null) return;
    if (fileId.startsWith('local_reject_') ||
        tile.status == AttachmentTileStatus.rejected) {
      return;
    }

    if (tile.status == AttachmentTileStatus.sendFailed &&
        tile.attachment != null &&
        tile.attachment!.state == AttachmentState.uploaded) {
      tile.status = AttachmentTileStatus.done;
      tile.errorMessage = null;
      tile.failure = null;
      _safeNotify();
      if (coordinator != null &&
          sender != null &&
          (conversationId ?? '').isNotEmpty) {
        await sendAll(
          coordinator: coordinator,
          conversationId: conversationId!,
          sender: sender,
          repliedTo: repliedTo,
        );
      }
      return;
    }

    final provider = mediaProvider;
    if (provider == null) return;
    tile.loaded = 0;
    tile.errorMessage = null;
    tile.failure = null;
    tile.status = AttachmentTileStatus.uploading;
    _safeNotify();
    await _uploadTile(tile, provider);
  }

  void setCaption(String value) => caption = value;

  /// Cancels all active uploads and clears every tile from the tray.
  Future<void> clear() async {
    for (final token in _activeTokens.values) {
      token.cancel();
    }
    _activeTokens.clear();
    _failedSendLocalIds.clear();
    _tiles.forEach(_releaseThumb);
    _tiles.clear();
    caption = '';
    _safeNotify();
  }

  void _removeTileInternal(String fileId, {bool notify = true}) {
    for (final t in _tiles) {
      if (t.fileId == fileId) _releaseThumb(t);
    }
    _tiles.removeWhere((t) => t.fileId == fileId);
    if (notify) _safeNotify();
  }

  void _releaseThumb(AttachmentTile tile) {
    final t = tile.thumbUrl;
    if (t != null) platform.revokeObjectUrl(t);
  }

  Future<void> _probeDuration(AttachmentTile tile, String source) async {
    final d = await platform.probeMediaDuration(source);
    if (d != null && _tiles.contains(tile)) {
      tile.durationMillis = d.inMilliseconds;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _activeTokens.values) {
      token.cancel();
    }
    _activeTokens.clear();
    _failedSendLocalIds.clear();
    _tiles.forEach(_releaseThumb);
    _tiles.clear();
    super.dispose();
  }
}
