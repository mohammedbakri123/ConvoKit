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

    test('shared_ui AI view directories do not exist', () {
      const dirs = [
        'lib/shared_ui/src/views/ai_smart_replies',
        'lib/shared_ui/src/views/ai_conversation_starter',
        'lib/shared_ui/src/views/ai_conversation_summary',
        'lib/shared_ui/src/views/ai_option_sheet',
      ];
      for (final path in dirs) {
        expect(
          Directory(path).existsSync(),
          isFalse,
          reason: '$path must not exist in v1',
        );
      }
    });

    test('lib/shared_ui/cometchat_uikit_shared.dart does not export AI views or option sheet', () {
      final sharedBarrel = File('lib/shared_ui/cometchat_uikit_shared.dart');
      expect(sharedBarrel.existsSync(), isTrue);
      final content = sharedBarrel.readAsStringSync();
      expect(
        content.contains('ai_smart_replies'),
        isFalse,
        reason: 'cometchat_uikit_shared.dart must not export ai_smart_replies',
      );
      expect(
        content.contains('ai_conversation_starter'),
        isFalse,
        reason: 'cometchat_uikit_shared.dart must not export ai_conversation_starter',
      );
      expect(
        content.contains('ai_conversation_summary'),
        isFalse,
        reason: 'cometchat_uikit_shared.dart must not export ai_conversation_summary',
      );
      expect(
        content.contains('ai_option_sheet'),
        isFalse,
        reason: 'cometchat_uikit_shared.dart must not export ai_option_sheet',
      );
      expect(
        content.contains('cometchat_stream_service.dart'),
        isFalse,
        reason: 'cometchat_uikit_shared.dart must not export cometchat_stream_service',
      );
    });

    test('message templates contain no AIAssistantBubble or StreamBubble references', () {
      final templateFile =
          File('lib/chat_ui/src/message_list/utils/message_template_utils.dart');
      expect(templateFile.existsSync(), isTrue);
      final content = templateFile.readAsStringSync();
      expect(
        content.contains('AIAssistantBubble'),
        isFalse,
        reason: 'message_template_utils.dart must not contain AIAssistantBubble references',
      );
      expect(
        content.contains('StreamBubble'),
        isFalse,
        reason: 'message_template_utils.dart must not contain StreamBubble references',
      );
    });

    test('message list bloc contains no addAIAssistantListener or AIAssistantListener references', () {
      final blocFile =
          File('lib/chat_ui/src/message_list/bloc/message_list_bloc.dart');
      expect(blocFile.existsSync(), isTrue);
      final content = blocFile.readAsStringSync();
      expect(
        content.contains('addAIAssistantListener'),
        isFalse,
        reason: 'message_list_bloc.dart must not contain addAIAssistantListener',
      );
      expect(
        content.contains('AIAssistantListener'),
        isFalse,
        reason: 'message_list_bloc.dart must not contain AIAssistantListener',
      );
    });
  });
}
