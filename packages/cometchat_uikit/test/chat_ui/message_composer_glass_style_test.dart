import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageComposer L3 (glass blurSigma, outerMargin, boxShadow)', () {
    testWidgets(
      'omits BackdropFilter by default and wraps capsule in ClipRRect + BackdropFilter when blurSigma > 0',
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

        Widget buildApp({ConvoKitMessageComposerStyle? style}) {
          return ConvoKitScope(
            kit: kit,
            child: MaterialApp(
              localizationsDelegates: const [Translations.delegate],
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConvoKitMessageComposer(
                    conversationId: 'conv_1_2',
                    user: fake.user2,
                    messageComposerStyle: style,
                  ),
                ),
              ),
            ),
          );
        }

        // 1. Default style (blurSigma == null): no BackdropFilter.
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);

        // 2. Frosted glass capsule style (blurSigma > 0).
        const outerMargin = EdgeInsets.fromLTRB(12, 0, 12, 10);
        const shadows = <BoxShadow>[
          BoxShadow(
            color: Color(0x140F1F18),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];
        await tester.pumpWidget(
          buildApp(
            style: ConvoKitMessageComposerStyle(
              blurSigma: 24,
              outerMargin: outerMargin,
              boxShadow: shadows,
              borderRadius: BorderRadius.circular(28),
              backgroundColor: const Color(0xC7FFFFFF),
              filledColor: Colors.transparent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(BackdropFilter),
            matching: find.byType(ClipRRect),
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );

    test('ConvoKitMessageComposerStyle copyWith, merge, and lerp preserve L3 fields', () {
      const marginA = EdgeInsets.all(8);
      const marginB = EdgeInsets.fromLTRB(12, 0, 12, 10);
      const shadowA = <BoxShadow>[
        BoxShadow(color: Color(0x14000000), blurRadius: 12),
      ];
      const shadowB = <BoxShadow>[
        BoxShadow(color: Color(0x28000000), blurRadius: 24),
      ];

      const base = ConvoKitMessageComposerStyle();
      final copied = base.copyWith(
        blurSigma: 16,
        outerMargin: marginA,
        boxShadow: shadowA,
      );
      expect(copied.blurSigma, 16);
      expect(copied.outerMargin, marginA);
      expect(copied.boxShadow, shadowA);

      final merged = copied.merge(
        const ConvoKitMessageComposerStyle(
          blurSigma: 24,
          outerMargin: marginB,
          boxShadow: shadowB,
        ),
      );
      expect(merged.blurSigma, 24);
      expect(merged.outerMargin, marginB);
      expect(merged.boxShadow, shadowB);

      final lerped = copied.lerp(merged, 0.5);
      expect(lerped.blurSigma, 20);
      expect(lerped.outerMargin, isNotNull);
      expect(lerped.boxShadow, isNotNull);
    });
  });
}
