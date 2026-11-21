/// Tests for [BubbleFactoryRegistry] and built-in bubble factories (Core models).
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sender = ChatUser(id: 'u1', name: 'Alice');

  test('BubbleFactoryRegistry computes deterministic keys for sealed ChatMessage types', () {
    final text = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: sender,
      createdAt: DateTime(2026),
      text: 'Hello',
    );
    final img = MediaMessage(
      id: 'm2',
      localId: 'm2',
      conversationId: 'c1',
      sender: sender,
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
    final deleted = CustomMessage(
      id: 'm3',
      localId: 'm3',
      conversationId: 'c1',
      sender: sender,
      createdAt: DateTime(2026),
      kind: 'deleted',
      data: const {},
    );

    expect(BubbleFactory.getFactoryKey(text), 'message_text');
    expect(BubbleFactory.getFactoryKey(img), 'message_image');
    expect(BubbleFactory.getFactoryKey(deleted), 'deleted');
  });
}
