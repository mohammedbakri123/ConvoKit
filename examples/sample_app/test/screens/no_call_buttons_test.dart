import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app/screens/home_screen.dart';
import 'package:sample_app/screens/user_info_screen.dart';

void main() {
  group('Phase 4: Sample app exposes no call buttons or call UI', () {
    testWidgets('CometChatMessageHeader exposes no call buttons or call action items', (tester) async {
      final testUser = User(uid: 'u_tester', name: 'Tester', status: 'online');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            appBar: CometChatMessageHeader(
              user: testUser,
            ),
          ),
        ),
      );
      await tester.pump();

      // Ensure no voice or video call icons/buttons exist in header
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);
      expect(find.byIcon(Icons.videocam_outlined), findsNothing);
      expect(find.byTooltip('Voice call'), findsNothing);
      expect(find.byTooltip('Video call'), findsNothing);
    });

    test('Message templates contain no call or meeting templates', () {
      final templates = MessageTemplateUtils.getAllMessageTemplates();
      for (final template in templates) {
        expect(
          template.category.toLowerCase(),
          isNot('call'),
          reason: 'Call category message templates must be removed',
        );
        expect(
          template.type.toLowerCase(),
          isNot('meeting'),
          reason: 'Meeting type message templates must be removed',
        );
      }

      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'audio',
          messageCategory: 'call',
        ),
        isNull,
      );
      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'video',
          messageCategory: 'call',
        ),
        isNull,
      );
      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'meeting',
          messageCategory: 'call',
        ),
        isNull,
      );
    });

    testWidgets('HomeScreen exposes no Calls tab or call actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // No Calls tab in bottom nav or app bar
      expect(find.text('Calls'), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byIcon(Icons.call_rounded), findsNothing);
    });

    testWidgets('UserInfoScreen exposes no call buttons', (tester) async {
      final testUser = User(uid: 'u_info_tester', name: 'Info Tester', status: 'offline');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: UserInfoScreen(user: testUser),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byIcon(Icons.videocam_outlined), findsNothing);
      expect(find.text('Voice'), findsNothing);
      expect(find.text('Video'), findsNothing);
    });
  });
}
