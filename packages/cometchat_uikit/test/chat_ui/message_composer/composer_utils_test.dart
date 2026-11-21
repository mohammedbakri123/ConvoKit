import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sender = ChatUser(id: 'u1', name: 'Alice');

  MediaMessage media(AttachmentKind kind) => MediaMessage(
        localId: 'loc_${kind.name}',
        conversationId: 'conv_1',
        sender: sender,
        createdAt: DateTime(2026),
        attachment: ChatAttachment(
          id: 'att_${kind.name}',
          kind: kind,
          localPath: '/tmp/sample',
          state: AttachmentState.local,
        ),
      );

  testWidgets('ComposerUtils.getReplyIcon returns null for TextMessage', (
    tester,
  ) async {
    Widget? icon;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            icon = ComposerUtils.getReplyIcon(
              TextMessage(
                localId: 'loc_text',
                conversationId: 'conv_1',
                sender: sender,
                createdAt: DateTime(2026),
                text: 'hello',
              ),
              context,
              Colors.grey,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(icon, isNull);
  });

  testWidgets('ComposerUtils.getReplyIcon maps AttachmentKind to Icons', (
    tester,
  ) async {
    final icons = <AttachmentKind, IconData>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            for (final kind in AttachmentKind.values) {
              final widget =
                  ComposerUtils.getReplyIcon(media(kind), context, Colors.blue)
                      as Icon;
              icons[kind] = widget.icon!;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(icons[AttachmentKind.image], Icons.image_outlined);
    expect(icons[AttachmentKind.video], Icons.videocam_outlined);
    expect(icons[AttachmentKind.audio], Icons.mic_outlined);
    expect(icons[AttachmentKind.file], Icons.insert_drive_file_outlined);
  });
}
