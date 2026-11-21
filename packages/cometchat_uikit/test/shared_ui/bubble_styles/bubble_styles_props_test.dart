/// Style contract tests for incoming/outgoing message bubble styles.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message bubble styles', () {
    test('CometChatTextBubbleStyle preserves fields', () {
      const style = CometChatTextBubbleStyle(
        backgroundColor: Color(0xFF112233),
        textStyle: TextStyle(fontSize: 15),
      );
      expect(style.backgroundColor, const Color(0xFF112233));
      expect(style.textStyle?.fontSize, 15);
    });

    test('CometChatOutgoingMessageBubbleStyle merges textBubbleStyle', () {
      const base = CometChatOutgoingMessageBubbleStyle(
        backgroundColor: Color(0xFF102030),
        textBubbleStyle: CometChatTextBubbleStyle(
          backgroundColor: Color(0xFF405060),
        ),
      );
      expect(base.backgroundColor, const Color(0xFF102030));
      expect(base.textBubbleStyle?.backgroundColor, const Color(0xFF405060));
    });

    test('CometChatIncomingMessageBubbleStyle merges textBubbleStyle', () {
      const base = CometChatIncomingMessageBubbleStyle(
        backgroundColor: Color(0xFFAAAAAA),
        textBubbleStyle: CometChatTextBubbleStyle(
          backgroundColor: Color(0xFFBBBBBB),
        ),
      );
      expect(base.backgroundColor, const Color(0xFFAAAAAA));
      expect(base.textBubbleStyle?.backgroundColor, const Color(0xFFBBBBBB));
    });
  });
}
