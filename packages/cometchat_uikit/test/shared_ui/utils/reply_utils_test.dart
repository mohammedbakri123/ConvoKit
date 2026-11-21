/// Tests for reply preview helpers on Core [ChatMessage].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextMessage carries repliedTo reference', () {
    const alice = ChatUser(id: 'u1', name: 'Alice');
    final parent = TextMessage(
      id: 'm1',
      localId: 'm1',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      text: 'Original',
    );
    final reply = TextMessage(
      id: 'm2',
      localId: 'm2',
      conversationId: 'c1',
      sender: alice,
      createdAt: DateTime(2026),
      repliedTo: parent,
      text: 'Reply',
    );
    expect(reply.repliedTo?.id, 'm1');
  });
}
