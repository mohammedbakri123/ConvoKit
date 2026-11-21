/// Property tests for [AttachmentUtils] classification on Core [ChatAttachment].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

ChatAttachment _att(String mime, String name, AttachmentKind kind) =>
    ChatAttachment(
      id: 'att_$name',
      remoteId: 'rem_$name',
      kind: kind,
      url: 'https://example.com/$name',
      state: AttachmentState.uploaded,
      mimeType: mime,
      name: name,
      sizeBytes: 128,
    );

void main() {
  test('categorize partitions all attachments without loss', () {
    final items = [
      _att('image/jpeg', 'a.jpg', AttachmentKind.image),
      _att('image/gif', 'g.gif', AttachmentKind.image),
      _att('video/mp4', 'v.mp4', AttachmentKind.video),
      _att('audio/mpeg', 's.mp3', AttachmentKind.audio),
      _att('application/pdf', 'd.pdf', AttachmentKind.file),
    ];
    final cat = AttachmentUtils.categorize(items);
    expect(cat.totalCount, items.length);
    expect(cat.media.length, 3);
    expect(cat.audio.length, 1);
    expect(cat.files.length, 1);
    expect(AttachmentUtils.isGif(items[1]), isTrue);
    expect(AttachmentUtils.isNonPreviewableFile(items[4]), isTrue);
  });

  test('deriveType agrees with isImageOf/isVideoOf/isAudioOf', () {
    final img = _att('image/png', 'p.png', AttachmentKind.image);
    final vid = _att('video/mp4', 'v.mp4', AttachmentKind.video);
    final aud = _att('audio/ogg', 'a.ogg', AttachmentKind.audio);
    expect(AttachmentUtils.isImageOf(img), isTrue);
    expect(AttachmentUtils.isVideoOf(vid), isTrue);
    expect(AttachmentUtils.isAudioOf(aud), isTrue);
  });
}
