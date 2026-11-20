import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5: AI views disabled (v1 build)', () {
    test('lib/chat_ui/src/ai_assistant_chat_history does not exist', () {
      final dir = Directory('lib/chat_ui/src/ai_assistant_chat_history');
      expect(
        dir.existsSync(),
        isFalse,
        reason: 'lib/chat_ui/src/ai_assistant_chat_history must be deleted for v1',
      );
    });

    test('lib/cometchat_chat_uikit.dart does not export ai_assistant_chat_history', () {
      final barrel = File('lib/cometchat_chat_uikit.dart');
      expect(barrel.existsSync(), isTrue);
      final content = barrel.readAsStringSync();
      expect(
        content.contains('ai_assistant_chat_history'),
        isFalse,
        reason: 'cometchat_chat_uikit.dart must not export ai_assistant_chat_history',
      );
    });

    test('test/chat_ui/ai_assistant_chat_history does not exist', () {
      final testDir = Directory('test/chat_ui/ai_assistant_chat_history');
      expect(
        testDir.existsSync(),
        isFalse,
        reason: 'test/chat_ui/ai_assistant_chat_history must be deleted for v1',
      );
    });

    test('examples/ai_sample_app does not exist in repo', () {
      final aiSampleAppDir = Directory('../../examples/ai_sample_app');
      expect(
        aiSampleAppDir.existsSync(),
        isFalse,
        reason: 'examples/ai_sample_app must be deleted for v1',
      );
    });
  });
}
