/// Attachment models and state machine according to API-DESIGN.md §2.2.
library;

import '../../contracts/result.dart';

enum AttachmentKind { image, video, file, audio }

enum AttachmentState { local, uploading, uploaded, failed }

class ChatAttachment {
  /// Client-generated, stable across the attachment's life.
  final String id;

  /// Server media id. Non-null if and only if state == uploaded.
  final String? remoteId;

  final AttachmentKind kind;

  /// Non-null while state is local, uploading, or failed. Optional when
  /// uploaded: the host may retain it for a local cache/thumbnail or drop
  /// it; rendering always uses `url`. One rule, stated here and in the
  /// invariant below.
  final String? localPath;

  /// Non-null if and only if state == uploaded.
  final String? url;

  /// Non-null if and only if state == uploaded (when the backend provides one).
  final String? thumbnailUrl;

  final AttachmentState state;

  /// 0..1. Non-null if and only if state == uploading.
  final double? uploadProgress;

  /// Non-null if and only if state == failed.
  final ChatError? uploadFailure;

  final String? mimeType;
  final int? sizeBytes;
  final String? name;

  const ChatAttachment({
    required this.id,
    this.remoteId,
    required this.kind,
    this.localPath,
    this.url,
    this.thumbnailUrl,
    required this.state,
    this.uploadProgress,
    this.uploadFailure,
    this.mimeType,
    this.sizeBytes,
    this.name,
  }) : assert(
         state == AttachmentState.uploaded || localPath != null,
         'localPath is required until upload completes',
       ),
       assert(
         (url != null) == (state == AttachmentState.uploaded),
         'url must be non-null if and only if state == uploaded',
       ),
       assert(
         (remoteId != null) == (state == AttachmentState.uploaded),
         'remoteId must be non-null if and only if state == uploaded',
       ),
       assert(
         (uploadProgress != null) == (state == AttachmentState.uploading),
         'uploadProgress must be non-null if and only if state == uploading',
       ),
       assert(
         (uploadFailure != null) == (state == AttachmentState.failed),
         'uploadFailure must be non-null if and only if state == failed',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          remoteId == other.remoteId &&
          kind == other.kind &&
          localPath == other.localPath &&
          url == other.url &&
          thumbnailUrl == other.thumbnailUrl &&
          state == other.state &&
          uploadProgress == other.uploadProgress &&
          uploadFailure == other.uploadFailure &&
          mimeType == other.mimeType &&
          sizeBytes == other.sizeBytes &&
          name == other.name;

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    kind,
    localPath,
    url,
    thumbnailUrl,
    state,
    uploadProgress,
    uploadFailure,
    mimeType,
    sizeBytes,
    name,
  );

  @override
  String toString() =>
      'ChatAttachment(id: $id, kind: $kind, state: $state, remoteId: $remoteId)';
}
