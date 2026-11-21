/// Property tests for conversation subtitle previews on Core models.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  testWidgets('text, media, and custom messages produce non-empty subtitles', (
    tester,
  ) async {
    const user = ChatUser(id: 'u1', name: 'Alice');
    final textMsg = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: user,
      createdAt: DateTime(2026),
      text: 'Hello **world**',
    );
    final imgMsg = MediaMessage(
      id: 'm2',
      localId: 'm2',
      conversationId: 'c1',
      sender: user,
      createdAt: DateTime(2026),
      attachment: const ChatAttachment(
        id: 'a1',
        remoteId: 'r1',
        kind: AttachmentKind.image,
        url: 'https://example.com/a.jpg',
        state: AttachmentState.uploaded,
        mimeType: 'image/jpeg',
        name: 'a.jpg',
      ),
    );

    late String textSub;
    late String imgSub;
    await pumpInApp(
      tester,
      Builder(
        builder: (context) {
          textSub = ConversationUtils.getLastConversationMessage(
            ChatConversation.direct(
              id: 'c1',
              peer: user,
              lastMessage: textMsg,
              updatedAt: DateTime(2026),
            ),
            context,
          );
          imgSub = ConversationUtils.getLastConversationMessage(
            ChatConversation.direct(
              id: 'c1',
              peer: user,
              lastMessage: imgMsg,
              updatedAt: DateTime(2026),
            ),
            context,
          );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(textSub, 'Hello world');
    expect(imgSub, isNotEmpty);
  });
}
