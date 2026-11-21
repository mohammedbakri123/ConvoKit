/// Per-type bubble style contract tests (SDK-free & BLoC-free).
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Per-type bubble styles', () {
    test('image, video, audio, file, and delete bubble styles hold fields', () {
      const imageStyle = CometChatImageBubbleStyle(
        backgroundColor: Color(0xFF010203),
      );
      const videoStyle = CometChatVideoBubbleStyle(
        backgroundColor: Color(0xFF040506),
      );
      const fileStyle = CometChatFileBubbleStyle(
        backgroundColor: Color(0xFF070809),
      );
      const deleteStyle = ConvoKitDeletedBubbleStyle(
        backgroundColor: Color(0xFF0A0B0C),
      );
      expect(imageStyle.backgroundColor, const Color(0xFF010203));
      expect(videoStyle.backgroundColor, const Color(0xFF040506));
      expect(fileStyle.backgroundColor, const Color(0xFF070809));
      expect(deleteStyle.backgroundColor, const Color(0xFF0A0B0C));
    });
  });
}
