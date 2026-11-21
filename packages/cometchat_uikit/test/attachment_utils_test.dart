import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

ChatAttachment _att(
  String mime, {
  String name = 'f.bin',
  AttachmentKind kind = AttachmentKind.file,
}) => ChatAttachment(
  id: 'att_$name',
  kind: kind,
  localPath: '/tmp/$name',
  state: AttachmentState.local,
  mimeType: mime,
  name: name,
  sizeBytes: 1024,
);

MediaMessage _msg(ChatAttachment attachment) => MediaMessage(
  localId: 'local_1',
  conversationId: 'conv_1',
  sender: const ChatUser(id: 'u1', name: 'User 1'),
  createdAt: DateTime(2026),
  attachment: attachment,
);

void main() {
  group('attachmentsOf', () {
    test('returns the singular attachment in a list', () {
      final single = _att('application/pdf', name: 'doc.pdf');
      final out = AttachmentUtils.attachmentsOf(_msg(single));
      expect(out.length, 1);
      expect(identical(out.first, single), isTrue);
    });

    test('returns empty for text messages', () {
      final text = TextMessage(
        localId: 'local_2',
        conversationId: 'conv_1',
        sender: const ChatUser(id: 'u1', name: 'User 1'),
        createdAt: DateTime(2026),
        text: 'hello',
      );
      expect(AttachmentUtils.attachmentsOf(text), isEmpty);
    });
  });

  group('categorize', () {
    test('partitions attachments into images, videos, audios, and files', () {
      final img = _att('image/jpeg', name: 'a.jpg', kind: AttachmentKind.image);
      final vid = _att('video/mp4', name: 'b.mp4', kind: AttachmentKind.video);
      final aud = _att('audio/mpeg', name: 'c.mp3', kind: AttachmentKind.audio);
      final doc = _att('application/pdf', name: 'd.pdf', kind: AttachmentKind.file);
      final cat = AttachmentUtils.categorize([img, vid, aud, doc]);
      expect(cat.media, [img, vid]);
      expect(cat.audio, [aud]);
      expect(cat.files, [doc]);
      expect(cat.totalCount, 4);
    });
  });

  group('deriveType and classification', () {
    test('classifies image, video, audio, and file attachments', () {
      final img = _att('image/png', name: 'a.png', kind: AttachmentKind.image);
      final vid = _att('video/mp4', name: 'b.mp4', kind: AttachmentKind.video);
      final aud = _att('audio/mpeg', name: 'c.mp3', kind: AttachmentKind.audio);
      final doc = _att('application/pdf', name: 'd.pdf', kind: AttachmentKind.file);

      expect(AttachmentUtils.deriveType(img), MessageTypeConstants.image);
      expect(AttachmentUtils.deriveType(vid), MessageTypeConstants.video);
      expect(AttachmentUtils.deriveType(aud), MessageTypeConstants.audio);
      expect(AttachmentUtils.deriveType(doc), MessageTypeConstants.file);
      expect(AttachmentUtils.isVisualMedia(img), isTrue);
      expect(AttachmentUtils.isVisualMedia(vid), isTrue);
      expect(AttachmentUtils.isVisualMedia(doc), isFalse);
      expect(AttachmentUtils.isNonPreviewableFile(doc), isTrue);
      expect(AttachmentUtils.isNonPreviewableFile(img), isFalse);
    });
  });
}
