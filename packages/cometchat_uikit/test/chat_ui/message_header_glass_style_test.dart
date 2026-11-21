import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageHeader L4 (glass blurSigma & boxShadow)', () {
    testWidgets(
      'omits BackdropFilter by default and renders ClipRect + BackdropFilter when blurSigma > 0',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 1);
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: ChatCapabilities.basic(),
          groups: fake.groups,
          media: fake.media,
        );

        Widget buildApp({ConvoKitMessageHeaderStyle? style}) {
          return MaterialApp(
            localizationsDelegates: Translations.localizationsDelegates,
            supportedLocales: Translations.supportedLocales,
            home: ConvoKitScope(
              kit: kit,
              child: Scaffold(
                extendBodyBehindAppBar: style?.blurSigma != null,
                appBar: ConvoKitMessageHeader(
                  user: fake.user2,
                  conversationId: 'conv_1_2',
                  messageHeaderStyle: style,
                ),
                body: const SizedBox.expand(),
              ),
            ),
          );
        }

        // 1. Default style (blurSigma == null): no BackdropFilter.
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);

        // 2. Frosted glass header style (blurSigma > 0).
        await tester.pumpWidget(
          buildApp(
            style: const ConvoKitMessageHeaderStyle(
              blurSigma: 24,
              backgroundColor: Color(0xC7FFFFFF),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x140F1F18),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(BackdropFilter),
            matching: find.byType(ClipRect),
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );

    test('ConvoKitMessageHeaderStyle copyWith, merge, and lerp preserve L4 fields', () {
      const shadowA = <BoxShadow>[
        BoxShadow(color: Color(0x14000000), blurRadius: 8),
      ];
      const shadowB = <BoxShadow>[
        BoxShadow(color: Color(0x28000000), blurRadius: 20),
      ];

      const base = ConvoKitMessageHeaderStyle();
      final copied = base.copyWith(blurSigma: 12, boxShadow: shadowA);
      expect(copied.blurSigma, 12);
      expect(copied.boxShadow, shadowA);

      final merged = copied.merge(
        const ConvoKitMessageHeaderStyle(blurSigma: 24, boxShadow: shadowB),
      );
      expect(merged.blurSigma, 24);
      expect(merged.boxShadow, shadowB);

      final lerped = copied.lerp(merged, 0.5);
      expect(lerped.blurSigma, 18);
      expect(lerped.boxShadow, isNotNull);
    });
  });
}
