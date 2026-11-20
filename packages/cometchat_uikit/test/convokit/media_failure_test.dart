import 'package:flutter_test/flutter_test.dart';
import 'package:cometchat_chat_uikit/convokit.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Media upload-failure vs send-failure tests (Plan §8.11)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend();
    });

    test('Upload failure: fails upload, enters failed state, retry re-uploads and sends same localId', () async {
      fake.failNextUpload = true;
      const localId = 'local_media_fail_test';
      final uploadReq = UploadRequest.file(
        '/tmp/test_photo.jpg',
        kind: AttachmentKind.image,
        name: 'test_photo.jpg',
        mimeType: 'image/jpeg',
      );

      // 1. Initial local state
      var attachment = const ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/test_photo.jpg',
        state: AttachmentState.local,
      );
      expect(attachment.state, AttachmentState.local);

      // 2. Start upload -> uploading state
      attachment = const ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/test_photo.jpg',
        state: AttachmentState.uploading,
        uploadProgress: 0.0,
      );
      expect(attachment.state, AttachmentState.uploading);

      // 3. Attempt upload -> injected failure occurs
      final uploadResult = await fake.media.upload(uploadReq);
      expect(uploadResult.isFailure, isTrue);
      expect(fake.uploadCallCount, 1);

      final error = uploadResult.errorOrNull!;
      expect(error.code, ChatErrorCode.uploadFailed);

      // Attachment enters failed state with uploadFailure
      attachment = ChatAttachment(
        id: 'att_1',
        kind: AttachmentKind.image,
        localPath: '/tmp/test_photo.jpg',
        state: AttachmentState.failed,
        uploadFailure: error,
      );
      expect(attachment.state, AttachmentState.failed);
      expect(attachment.uploadFailure, isNotNull);
      expect(attachment.uploadFailure!.code, ChatErrorCode.uploadFailed);

      // 4. Retry: re-uploads, then sends message with SAME localId
      final retryUploadResult = await fake.media.upload(uploadReq);
      expect(retryUploadResult.isSuccess, isTrue);
      expect(fake.uploadCallCount, 2, reason: 'Retry must re-upload');

      final uploadedMedia = retryUploadResult.getOrThrow();
      attachment = ChatAttachment(
        id: 'att_1',
        remoteId: uploadedMedia.id,
        kind: AttachmentKind.image,
        localPath: '/tmp/test_photo.jpg',
        url: uploadedMedia.url,
        state: AttachmentState.uploaded,
      );
      expect(attachment.state, AttachmentState.uploaded);

      final msg = MediaMessage(
        localId: localId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        attachment: attachment,
        caption: 'Look at this photo',
      );

      final sendResult = await fake.messages.sendMessage(msg);
      expect(sendResult.isSuccess, isTrue);
      expect(fake.sendCallCount, 1);
      final confirmed = sendResult.getOrThrow() as MediaMessage;
      expect(confirmed.localId, localId);
      expect(confirmed.attachment.remoteId, uploadedMedia.id);
    });

    test('Send failure: upload succeeds, send fails; retry sends ONLY without re-uploading', () async {
      fake.failNextSend = true;
      const localId = 'local_media_send_fail_test';
      final uploadReq = UploadRequest.file(
        '/tmp/document.pdf',
        kind: AttachmentKind.file,
        name: 'document.pdf',
      );

      // 1. Upload succeeds
      final uploadResult = await fake.media.upload(uploadReq);
      expect(uploadResult.isSuccess, isTrue);
      expect(fake.uploadCallCount, 1);

      final uploadedMedia = uploadResult.getOrThrow();
      final attachment = ChatAttachment(
        id: 'att_doc',
        remoteId: uploadedMedia.id,
        kind: AttachmentKind.file,
        localPath: '/tmp/document.pdf',
        url: uploadedMedia.url,
        state: AttachmentState.uploaded,
      );
      expect(attachment.state, AttachmentState.uploaded);

      // 2. Send fails
      final pendingMsg = MediaMessage(
        localId: localId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: DateTime.now(),
        sendState: SendState.sending,
        attachment: attachment,
      );

      final sendResult = await fake.messages.sendMessage(pendingMsg);
      expect(sendResult.isFailure, isTrue);
      expect(fake.sendCallCount, 1);
      expect(sendResult.errorOrNull!.code, ChatErrorCode.sendFailed);

      // Message enters failed sendState (NOT upload-failed state)
      final failedMsg = MediaMessage(
        localId: localId,
        conversationId: 'conv_1_2',
        sender: fake.user1,
        createdAt: pendingMsg.createdAt,
        sendState: SendState.failed,
        failure: sendResult.errorOrNull,
        attachment: attachment, // Attachment remains uploaded!
      );
      expect(failedMsg.sendState, SendState.failed);
      expect(failedMsg.attachment.state, AttachmentState.uploaded);

      // 3. Retry sends ONLY: assert upload is NOT called again
      final initialUploadCount = fake.uploadCallCount;
      final retrySendResult = await fake.messages.sendMessage(failedMsg);
      expect(retrySendResult.isSuccess, isTrue);
      expect(fake.uploadCallCount, initialUploadCount, reason: 'Retry must NOT re-upload already uploaded attachment');
      expect(fake.sendCallCount, 2);

      final confirmed = retrySendResult.getOrThrow() as MediaMessage;
      expect(confirmed.localId, localId);
      expect(confirmed.sendState, SendState.sent);
    });

    test('Cancel upload: in-flight cancellation deletes pending message entirely (no drafts)', () async {
      final token = CancellationToken();
      final uploadReq = UploadRequest.file(
        '/tmp/large_video.mp4',
        kind: AttachmentKind.video,
        name: 'large_video.mp4',
      );

      token.cancel();

      final res = await fake.media.upload(uploadReq, cancel: token);
      expect(res.isFailure, isTrue);
      expect(res.errorOrNull!.code, ChatErrorCode.cancelled);

      // Assert no message is added to conversation messages
      final messages = await fake.messages.fetchMessages(
        'conv_1_2',
        const MessagePageRequest(
          direction: MessagePageDirection.latest,
          limit: 30,
        ),
      );
      expect(
        messages.getOrThrow().items.any((m) => m is MediaMessage && m.attachment.localPath == '/tmp/large_video.mp4'),
        isFalse,
        reason: 'Cancelled upload must not leave a draft or pending message behind',
      );
    });
  });
}
