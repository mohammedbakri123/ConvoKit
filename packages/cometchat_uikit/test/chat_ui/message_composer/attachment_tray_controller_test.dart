import 'dart:typed_data';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';
import '../../helpers/fake_media_provider.dart';

void main() {
  group('AttachmentTrayController (ConvoKit two-step media flow)', () {
    late FakeChatMediaProvider mediaProvider;
    late AttachmentTrayController controller;

    setUp(() {
      mediaProvider = FakeChatMediaProvider();
      controller = AttachmentTrayController(
        mediaProvider: mediaProvider,
        conversationId: 'conv_1_2',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('stages file via UploadRequest.file and reports progress to done', () async {
      mediaProvider.autoProgressSteps = const [
        UploadProgress(sentBytes: 500, totalBytes: 1000),
        UploadProgress(sentBytes: 1000, totalBytes: 1000),
      ];

      final percents = <int>[];
      controller.addListener(() {
        if (controller.tiles.isNotEmpty) {
          percents.add(controller.tiles.first.percent);
        }
      });

      await controller.stage([
        const StagedUploadFile(
          name: 'photo.jpg',
          mimeType: 'image/jpeg',
          size: 1000,
          path: '/tmp/photo.jpg',
        ),
      ]);

      expect(mediaProvider.uploadCallCount, 1);
      expect(mediaProvider.uploadedRequests.single.localPath, '/tmp/photo.jpg');
      expect(mediaProvider.uploadedRequests.single.bytes, isNull);
      expect(percents, containsAll([0, 50, 100]));
      expect(controller.tiles, hasLength(1));
      expect(controller.tiles.single.status, AttachmentTileStatus.done);
      expect(controller.tiles.single.attachment?.state, AttachmentState.uploaded);
      expect(controller.canSend, isTrue);
    });

    test('stages in-memory bytes via UploadRequest.bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await controller.stage([
        StagedUploadFile(
          name: 'clip.png',
          mimeType: 'image/png',
          size: bytes.length,
          bytes: bytes,
        ),
      ]);

      expect(mediaProvider.uploadCallCount, 1);
      expect(mediaProvider.uploadedRequests.single.bytes, bytes);
      expect(mediaProvider.uploadedRequests.single.localPath, isNull);
      expect(controller.tiles.single.status, AttachmentTileStatus.done);
    });

    test('cancelOrRemove cancels active CancellationToken and deletes pending tile', () async {
      mediaProvider.manualCompletion = true;

      final stageFuture = controller.stage([
        const StagedUploadFile(
          name: 'video.mp4',
          mimeType: 'video/mp4',
          size: 2048,
          path: '/tmp/video.mp4',
        ),
      ]);

      expect(controller.tiles, hasLength(1));
      expect(controller.tiles.single.status, AttachmentTileStatus.uploading);
      final tileId = controller.tiles.single.fileId;
      final pending = mediaProvider.pendingUploads.single;

      await controller.cancelOrRemove(tileId);
      expect(pending.cancel?.isCancelled, isTrue);
      expect(controller.tiles, isEmpty);

      pending.completeFailure(
        const ChatError(ChatErrorCode.cancelled, 'Cancelled'),
      );
      await stageFuture;
      expect(controller.tiles, isEmpty);
    });

    test('upload failure sets failed status and retry re-runs upload', () async {
      mediaProvider.nextUploadError = const ChatError(
        ChatErrorCode.network,
        'Upload timed out',
      );

      await controller.stage([
        const StagedUploadFile(
          name: 'doc.pdf',
          mimeType: 'application/pdf',
          size: 512,
          path: '/tmp/doc.pdf',
        ),
      ]);

      expect(mediaProvider.uploadCallCount, 1);
      expect(controller.tiles.single.status, AttachmentTileStatus.failed);
      expect(controller.tiles.single.isUploadFailed, isTrue);
      expect(controller.tiles.single.errorMessage, 'Upload timed out');
      expect(controller.canSend, isFalse);

      await controller.retry(controller.tiles.single.fileId);
      expect(mediaProvider.uploadCallCount, 2);
      expect(controller.tiles.single.status, AttachmentTileStatus.done);
      expect(controller.canSend, isTrue);
    });

    test('send failure sets sendFailed and retry sends WITHOUT re-uploading', () async {
      final backend = FakeChatBackend(seededMessageCount: 2);
      final kit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: ChatCapabilities.basic(),
        groups: backend.groups,
        media: mediaProvider,
      );
      final coordinator = MessageCoordinator(kit);

      await controller.stage([
        const StagedUploadFile(
          name: 'report.pdf',
          mimeType: 'application/pdf',
          size: 1024,
          path: '/tmp/report.pdf',
        ),
      ]);
      expect(mediaProvider.uploadCallCount, 1);
      expect(controller.tiles.single.status, AttachmentTileStatus.done);

      // Fail the message send step while upload already succeeded.
      backend.failNextSend = true;
      final firstResults = await controller.sendAll(
        coordinator: coordinator,
        conversationId: 'conv_1_2',
        sender: backend.user1,
      );
      expect(firstResults.single.isFailure, isTrue);
      expect(backend.sendCallCount, 1);
      expect(controller.tiles, hasLength(1));
      expect(controller.tiles.single.status, AttachmentTileStatus.sendFailed);
      expect(controller.tiles.single.isSendFailed, isTrue);
      expect(controller.tiles.single.attachment?.state, AttachmentState.uploaded);

      // Retrying sendFailed must NOT call mediaProvider.upload again.
      await controller.retry(
        controller.tiles.single.fileId,
        coordinator: coordinator,
        sender: backend.user1,
      );
      expect(mediaProvider.uploadCallCount, 1);
      expect(backend.sendCallCount, 2);
      expect(controller.tiles, isEmpty);
    });

    test('throws AttachmentStageException when mediaProvider or conversationId missing', () async {
      final unbound = AttachmentTrayController();
      addTearDown(unbound.dispose);
      expect(
        () => unbound.stage([
          const StagedUploadFile(
            name: 'a.png',
            mimeType: 'image/png',
            size: 10,
            path: '/tmp/a.png',
          ),
        ]),
        throwsA(isA<AttachmentStageException>()),
      );
    });
  });
}
