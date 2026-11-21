/// Regression tests for ENG-39489 — the sender could not play an audio file
/// they had just sent.
///
/// The composer stamps `metadata['localPath']` on anything it sends, and every
/// other bubble reads it through [FileUtils] — image, video, file, voice note.
/// [CometChatAudiosBubble] was the one that didn't: its only route to a local
/// file was the *download* cache, keyed by the attachment's file name. So the
/// sender, who already had the file on disk, was made to fetch their own
/// upload back from the CDN before it would play — and a signed url that was
/// not servable yet left the row on a sticky error while the receiver, whose
/// download had populated the cache, played it fine.
///
/// The observable difference is the clock: a row with no local copy shows the
/// file size, a row that has one shows a duration placeholder instead.
///
///   flutter test test/shared_ui/bubbles/audios_bubble_local_copy_test.dart
library;

import 'dart:io';

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2048 bytes, so the row's size label is a distinctive "2 KB".
const _fileSize = 2048;
const _sizeLabel = '2 KB';

MediaMessage _audioMessage({required int attachmentCount, String? localPath}) {
  final attachments = List.generate(
    attachmentCount,
    (i) => ChatAttachment(
      id: 'att_clip_$i.mp3',
      remoteId: 'rem_clip_$i.mp3',
      kind: AttachmentKind.audio,
      url: 'https://files.invalid/clip_$i.mp3',
      state: AttachmentState.uploaded,
      mimeType: 'audio/mpeg',
      sizeBytes: _fileSize,
      name: 'clip_$i.mp3',
    ),
  );
  final meta = <String, dynamic>{
    'localPath': ?localPath,
    if (attachmentCount != 1) 'attachments': attachments,
  };
  return MediaMessage(
    id: 'm1',
    localId: 'm1',
    conversationId: 'c1',
    sender: const ChatUser(id: 'uid', name: 'User'),
    createdAt: DateTime(2026),
    attachment: attachments.first,
    metadata: meta.isEmpty ? null : meta,
  );
}

Future<void> _pump(WidgetTester tester, MediaMessage message) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: CometChatAudiosBubble(
            message: message,
            alignment: BubbleAlignment.right,
          ),
        ),
      ),
    ),
  );
  // The local-copy lookup is async; give it frames to resolve.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

bool _showsFileSize(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).any((t) => t.data == _sizeLabel);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('audios_bubble_test');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  testWidgets('with no local copy the row falls back to the file size', (
    tester,
  ) async {
    await _pump(tester, _audioMessage(attachmentCount: 1));
    expect(
      _showsFileSize(tester),
      isTrue,
      reason: 'nothing on disk — the row has only the size to show',
    );
  });

  testWidgets("the sender's stamped copy is used instead of a download", (
    tester,
  ) async {
    final file = File('${dir.path}/sent.m4a')
      ..writeAsBytesSync(List<int>.filled(_fileSize, 0));

    await _pump(
      tester,
      _audioMessage(attachmentCount: 1, localPath: file.path),
    );

    expect(
      _showsFileSize(tester),
      isFalse,
      reason:
          'the file is already on this device; making the sender re-download '
          'their own upload is what ENG-39489 was',
    );
  });

  testWidgets('a stamped path that no longer resolves is ignored', (
    tester,
  ) async {
    // iOS hands the app a new container UUID after a reinstall, so a path
    // stamped in server metadata can outlive the file it pointed at.
    await _pump(
      tester,
      _audioMessage(attachmentCount: 1, localPath: '${dir.path}/gone.m4a'),
    );
    expect(_showsFileSize(tester), isTrue);
  });

  testWidgets('a multi-attachment message does not borrow one path for every '
      'row', (tester) async {
    final file = File('${dir.path}/one.m4a')
      ..writeAsBytesSync(List<int>.filled(_fileSize, 0));

    await _pump(
      tester,
      _audioMessage(attachmentCount: 3, localPath: file.path),
    );

    // metadata['localPath'] is a single path with nothing to say which row it
    // belongs to, so it must not be applied to any of them.
    final sizeLabels = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data == _sizeLabel)
        .length;
    expect(
      sizeLabels,
      3,
      reason: 'every row still has to fetch its own attachment',
    );
  });
}
