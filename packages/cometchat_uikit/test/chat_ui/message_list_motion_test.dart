import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageList L6 (entry motion & reduced-motion support)', () {
    testWidgets(
      'renders instantaneously by default, animates when curve/duration set, and skips animation when disableAnimations is true',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 2);
        final convId = fake.conversationsList.first.id;
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(),
        );

        Widget buildApp({
          ConvoKitMessageListStyle? style,
          bool disableAnimations = false,
        }) {
          return MaterialApp(
            localizationsDelegates: Translations.localizationsDelegates,
            supportedLocales: Translations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: ConvoKitScope(
                kit: kit,
                child: Scaffold(
                  body: ConvoKitMessageList(
                    conversationId: convId,
                    style: style,
                  ),
                ),
              ),
            ),
          );
        }

        // 1. Default (null curve & duration): no TweenAnimationBuilder wrapper.
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

        // 2. With curve & duration set and animations enabled: wraps rows.
        const animatedStyle = ConvoKitMessageListStyle(
          messageEntryCurve: Curves.easeOutBack,
          messageEntryDuration: Duration(milliseconds: 240),
        );
        await tester.pumpWidget(buildApp(style: animatedStyle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          find.byType(TweenAnimationBuilder<double>),
          findsNWidgets(2),
        );

        await tester.pumpAndSettle();

        // 3. With MediaQuery.disableAnimations == true: skips animation wrapper.
        await tester.pumpWidget(
          buildApp(
            style: animatedStyle,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      },
    );

    test('ConvoKitMessageListStyle copyWith, merge, and lerp preserve L6 fields', () {
      const styleA = ConvoKitMessageListStyle(
        messageEntryCurve: Curves.easeOutCubic,
        messageEntryDuration: Duration(milliseconds: 200),
      );
      const styleB = ConvoKitMessageListStyle(
        messageEntryCurve: Curves.easeOutBack,
        messageEntryDuration: Duration(milliseconds: 240),
      );

      final copied = styleA.copyWith(
        messageEntryCurve: Curves.easeInOut,
        messageEntryDuration: const Duration(milliseconds: 180),
      );
      expect(copied.messageEntryCurve, Curves.easeInOut);
      expect(copied.messageEntryDuration, const Duration(milliseconds: 180));

      final merged = styleA.merge(styleB);
      expect(merged.messageEntryCurve, Curves.easeOutBack);
      expect(merged.messageEntryDuration, const Duration(milliseconds: 240));

      final lerpedEarly = styleA.lerp(styleB, 0.25);
      expect(lerpedEarly.messageEntryCurve, Curves.easeOutCubic);
      expect(lerpedEarly.messageEntryDuration, const Duration(milliseconds: 200));

      final lerpedLate = styleA.lerp(styleB, 0.75);
      expect(lerpedLate.messageEntryCurve, Curves.easeOutBack);
      expect(lerpedLate.messageEntryDuration, const Duration(milliseconds: 240));
    });
  });
}
