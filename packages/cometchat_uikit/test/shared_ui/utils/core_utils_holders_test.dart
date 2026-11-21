/// Tests for [CategorizedAttachments] and core utility holders.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CategorizedAttachments exposes media, audio, files, and totalCount', () {
    const img = ChatAttachment(
      id: 'a1',
      remoteId: 'r1',
      kind: AttachmentKind.image,
      url: 'https://example.com/1.png',
      state: AttachmentState.uploaded,
      mimeType: 'image/png',
      name: '1.png',
    );
    const aud = ChatAttachment(
      id: 'a2',
      remoteId: 'r2',
      kind: AttachmentKind.audio,
      url: 'https://example.com/2.mp3',
      state: AttachmentState.uploaded,
      mimeType: 'audio/mpeg',
      name: '2.mp3',
    );
    const doc = ChatAttachment(
      id: 'a3',
      remoteId: 'r3',
      kind: AttachmentKind.file,
      url: 'https://example.com/3.pdf',
      state: AttachmentState.uploaded,
      mimeType: 'application/pdf',
      name: '3.pdf',
    );

    final cat = AttachmentUtils.categorize([img, aud, doc]);
    expect(cat.media, [img]);
    expect(cat.audio, [aud]);
    expect(cat.files, [doc]);
    expect(cat.totalCount, 3);
    expect(cat.isEmpty, isFalse);
  });
}
