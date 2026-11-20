import 'package:flutter_test/flutter_test.dart';
import 'package:cometchat_chat_uikit/convokit.dart';

void main() {
  group('Attachment state machine tests (API-DESIGN.md §2)', () {
    test('State machine transitions: local -> uploading -> uploaded', () {
      // 1. Initial local state
      const local = ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/avatar.png',
        name: 'avatar.png',
        mimeType: 'image/png',
        sizeBytes: 1024,
        state: AttachmentState.local,
      );

      expect(local.state, AttachmentState.local);
      expect(local.localPath, '/tmp/avatar.png');
      expect(local.remoteId, isNull);
      expect(local.url, isNull);
      expect(local.uploadProgress, isNull);
      expect(local.uploadFailure, isNull);

      // 2. Transition to uploading with progress
      const uploading = ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/avatar.png',
        name: 'avatar.png',
        mimeType: 'image/png',
        sizeBytes: 1024,
        state: AttachmentState.uploading,
        uploadProgress: 0.45,
      );

      expect(uploading.state, AttachmentState.uploading);
      expect(uploading.uploadProgress, 0.45);
      expect(uploading.remoteId, isNull);
      expect(uploading.url, isNull);

      // 3. Transition to uploaded with remote metadata
      const uploaded = ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/avatar.png',
        remoteId: 'remote_media_999',
        url: 'https://cdn.example.com/media/remote_media_999.png',
        thumbnailUrl: 'https://cdn.example.com/media/remote_media_999_thumb.png',
        name: 'avatar.png',
        mimeType: 'image/png',
        sizeBytes: 1024,
        state: AttachmentState.uploaded,
      );

      expect(uploaded.state, AttachmentState.uploaded);
      expect(uploaded.remoteId, 'remote_media_999');
      expect(uploaded.url, 'https://cdn.example.com/media/remote_media_999.png');
      expect(uploaded.thumbnailUrl, 'https://cdn.example.com/media/remote_media_999_thumb.png');
      expect(uploaded.uploadFailure, isNull);
    });

    test('State machine transitions: local -> uploading -> failed', () {
      // 1. Local
      const local = ChatAttachment(
        id: 'att_2',
        kind: AttachmentKind.file,
        localPath: '/tmp/report.pdf',
        state: AttachmentState.local,
      );

      // 2. Uploading
      const uploading = ChatAttachment(
        id: 'att_2',
        kind: AttachmentKind.file,
        localPath: '/tmp/report.pdf',
        state: AttachmentState.uploading,
        uploadProgress: 0.1,
      );

      // 3. Upload fails
      const failureError = ChatError(ChatErrorCode.uploadFailed, 'Network timeout during upload');
      const failed = ChatAttachment(
        id: 'att_2',
        kind: AttachmentKind.file,
        localPath: '/tmp/report.pdf',
        state: AttachmentState.failed,
        uploadFailure: failureError,
      );

      expect(failed.state, AttachmentState.failed);
      expect(failed.uploadFailure, isNotNull);
      expect(failed.uploadFailure!.code, ChatErrorCode.uploadFailed);
      expect(failed.uploadFailure!.message, 'Network timeout during upload');
    });

    test('State machine invariants: assertions hold', () {
      // State invariant: failed requires uploadFailure
      expect(
        () => ChatAttachment(
          id: 'att_inv_1',
          kind: AttachmentKind.video,
          localPath: '/tmp/video.mp4',
          state: AttachmentState.failed,
          // uploadFailure omitted -> must throw AssertionError
        ),
        throwsA(isA<AssertionError>()),
      );

      // State invariant: uploading requires uploadProgress
      expect(
        () => ChatAttachment(
          id: 'att_inv_2',
          kind: AttachmentKind.audio,
          localPath: '/tmp/audio.mp3',
          state: AttachmentState.uploading,
          // uploadProgress omitted -> must throw AssertionError
        ),
        throwsA(isA<AssertionError>()),
      );

      // State invariant: uploaded requires remoteId and url
      expect(
        () => ChatAttachment(
          id: 'att_inv_3',
          kind: AttachmentKind.file,
          state: AttachmentState.uploaded,
          // remoteId and url omitted -> must throw AssertionError
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Attachment value equality', () {
      const a1 = ChatAttachment(
        id: 'att_eq',
        kind: AttachmentKind.image,
        localPath: '/tmp/img.png',
        state: AttachmentState.local,
      );
      const a2 = ChatAttachment(
        id: 'att_eq',
        kind: AttachmentKind.image,
        localPath: '/tmp/img.png',
        state: AttachmentState.local,
      );
      const a3 = ChatAttachment(
        id: 'att_eq',
        kind: AttachmentKind.image,
        localPath: '/tmp/img.png',
        state: AttachmentState.uploading,
        uploadProgress: 0.5,
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(a3)));
    });
  });
}
