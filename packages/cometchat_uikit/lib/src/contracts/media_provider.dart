/// Media provider contracts according to API-DESIGN.md §7.
library;

import 'dart:typed_data';

import '../core/models/attachment.dart';
import 'result.dart';

/// Exactly one source must be supplied. Enforced by the factories + assert.
class UploadRequest {
  final String? localPath;
  final Uint8List? bytes;
  final AttachmentKind kind;
  final String? mimeType;
  final String? name;

  factory UploadRequest.file(
    String localPath, {
    required AttachmentKind kind,
    String? mimeType,
    String? name,
  }) => UploadRequest._(
    localPath: localPath,
    kind: kind,
    mimeType: mimeType,
    name: name,
  );

  factory UploadRequest.bytes(
    Uint8List bytes, {
    required AttachmentKind kind,
    String? mimeType,
    String? name,
  }) => UploadRequest._(
    bytes: bytes,
    kind: kind,
    mimeType: mimeType,
    name: name,
  );

  UploadRequest._({
    this.localPath,
    this.bytes,
    required this.kind,
    this.mimeType,
    this.name,
  }) : assert(
         (localPath == null) != (bytes == null),
         'Exactly one of localPath/bytes must be supplied',
       );
}

class UploadedMedia {
  /// Server media id. Core stores it as the attachment's `remoteId`.
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? sizeBytes;
  final String? name;

  const UploadedMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.mimeType,
    this.sizeBytes,
    this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadedMedia &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          thumbnailUrl == other.thumbnailUrl &&
          mimeType == other.mimeType &&
          sizeBytes == other.sizeBytes &&
          name == other.name;

  @override
  int get hashCode =>
      Object.hash(id, url, thumbnailUrl, mimeType, sizeBytes, name);

  @override
  String toString() => 'UploadedMedia(id: $id, url: $url)';
}

class UploadProgress {
  final int sentBytes;
  final int totalBytes;

  const UploadProgress({required this.sentBytes, required this.totalBytes});

  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;
}

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

abstract class ChatMediaProvider {
  Future<ChatResult<UploadedMedia>> upload(
    UploadRequest request, {
    void Function(UploadProgress progress)? onProgress,
    CancellationToken? cancel,
  });

  /// Best-effort delete. Backends without delete report
  /// `capabilities.mediaDelete == false` and the UI hides the action.
  Future<ChatResult<void>> delete(String mediaId);
}
