import 'dart:io';

import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app/screens/home_screen.dart';

void main() {
  group('Phase 5: Sample app exposes no AI entry points or AI views', () {
    testWidgets('HomeScreen exposes no Agents tab or AI action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // No Agents tab or AI navigation icons in HomeScreen
      expect(find.text('Agents'), findsNothing);
      expect(find.byTooltip('Agents'), findsNothing);
      expect(find.byTooltip('AI'), findsNothing);
      expect(find.byIcon(Icons.smart_toy), findsNothing);
      expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
    });

    testWidgets('Message header exposes no AI buttons for regular user', (tester) async {
      final testUser = User(uid: 'u_tester', name: 'Tester', status: 'online');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            appBar: ConvoKitMessageHeader(
              user: testUser,
              hideNewChatButton: true,
              hideChatHistoryButton: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Ensure no AI Chat History or New Chat buttons in header
      expect(find.byTooltip('AI Chat History'), findsNothing);
      expect(find.byTooltip('New Chat'), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
    });

    testWidgets('Message header exposes no AI action buttons even for role=ai user', (tester) async {
      final aiUser = User(uid: 'u_ai_agent', name: 'AI Assistant', status: 'online', role: 'ai');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            appBar: ConvoKitMessageHeader(
              user: aiUser,
              hideNewChatButton: true,
              hideChatHistoryButton: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // In v1, an AI user in the sample app has AI buttons suppressed
      expect(find.byTooltip('AI Chat History'), findsNothing);
      expect(find.byTooltip('New Chat'), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
    });

    test('sample app lib/ contains ZERO references to AI views or AI constants', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final forbiddenAiTerms = [
        'CometChatAIAssistantChatHistory',
        'CometChatAISmartReplies',
        'CometChatAIConversationStarter',
        'CometChatAIConversationSummary',
        'CometChatAiOptionSheet',
        'AIConstants',
      ];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final term in forbiddenAiTerms) {
          expect(
            content.contains(term),
            isFalse,
            reason: '${file.path} must not reference $term in v1',
          );
        }
      }
    });

    test('ai_sample_app example directory is completely deleted', () {
      final aiAppDir = Directory('../../examples/ai_sample_app');
      final aiAppDirect = Directory('../ai_sample_app');
      final aiAppAbsolute = Directory('/home/hatch/workspace/repos/ChatUI/examples/ai_sample_app');

      expect(aiAppDir.existsSync() || aiAppDirect.existsSync() || aiAppAbsolute.existsSync(), isFalse,
          reason: 'examples/ai_sample_app/ must be deleted for v1');
    });

    test('ai_assistant_chat_history directory in library is completely deleted', () {
      final aiViewsDir = Directory('/home/hatch/workspace/repos/ChatUI/packages/cometchat_uikit/lib/chat_ui/src/ai_assistant_chat_history');
      expect(aiViewsDir.existsSync(), isFalse,
          reason: 'ai_assistant_chat_history/ must be deleted from uikit lib');
    });
  });
}
