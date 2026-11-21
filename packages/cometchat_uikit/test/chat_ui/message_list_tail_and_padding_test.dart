import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageList L2 (listPadding, bubble tails & style forwarding)', () {
    testWidgets(
      'preserves default behavior when new props are null and applies listPadding, bubble tails, avatarStyle, border, shadow, and receiptStyle when set',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 2);
        final convId = fake.conversationsList.first.id;
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(receipts: true),
        );

        Widget buildApp({
          EdgeInsetsGeometry? listPadding,
          ConvoKitMessageListStyle? style,
        }) {
          return MaterialApp(
            localizationsDelegates: Translations.localizationsDelegates,
            supportedLocales: Translations.supportedLocales,
            home: ConvoKitScope(
              kit: kit,
              child: Scaffold(
                body: ConvoKitMessageList(
                  conversationId: convId,
                  listPadding: listPadding,
                  style: style,
                ),
              ),
            ),
          );
        }

        // 1. Default behavior: no tails painted.
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('outgoing_bubble_tail')), findsNothing);
        expect(find.byKey(const Key('incoming_bubble_tail')), findsNothing);

        // 2. With L2 options configured: custom listPadding, tails, avatarStyle,
        //    bubbleShadow, border, and messageReceiptStyle are all forwarded.
        const customPadding = EdgeInsets.fromLTRB(16, 88, 16, 104);
        const avatarStyle = ConvoKitAvatarStyle(
          monogramPalette: <Color>[Color(0xFF1B5E43), Color(0xFF24577A)],
        );
        final receiptStyle = CometChatMessageReceiptStyle(
          sentIconColor: const Color(0xFF3B5248),
          deliveredIconColor: const Color(0xFF3B5248),
          readIconColor: const Color(0xFF53BDEB),
        );
        const shadow = <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ];

        await tester.pumpWidget(
          buildApp(
            listPadding: customPadding,
            style: ConvoKitMessageListStyle(
              showBubbleTail: true,
              bubbleShadow: shadow,
              avatarStyle: avatarStyle,
              outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                backgroundColor: const Color(0xFFDCF8C6),
                border: Border.all(color: const Color(0xFFC8E6C9)),
                borderRadius: BorderRadius.circular(20),
                messageReceiptStyle: receiptStyle,
              ),
              incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                backgroundColor: Colors.white,
                border: Border.all(color: const Color(0xFFE3EAE6)),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, customPadding);

        expect(find.byKey(const Key('outgoing_bubble_tail')), findsOneWidget);
        expect(find.byKey(const Key('incoming_bubble_tail')), findsOneWidget);

        final avatar = tester.widget<ConvoKitAvatar>(
          find.byType(ConvoKitAvatar).first,
        );
        expect(avatar.style, avatarStyle);

        final receipt = tester.widget<ConvoKitReceipt>(
          find.byType(ConvoKitReceipt).first,
        );
        expect(receipt.style, receiptStyle);
      },
    );

    test('ConvoKitMessageListStyle copyWith, merge, and lerp preserve L2 fields', () {
      const shadowA = <BoxShadow>[
        BoxShadow(color: Color(0x11000000), blurRadius: 4),
      ];
      const shadowB = <BoxShadow>[
        BoxShadow(color: Color(0x22000000), blurRadius: 12),
      ];

      const base = ConvoKitMessageListStyle();
      final updated = base.copyWith(
        showBubbleTail: true,
        bubbleShadow: shadowA,
      );
      expect(updated.showBubbleTail, isTrue);
      expect(updated.bubbleShadow, shadowA);

      final merged = base.merge(
        const ConvoKitMessageListStyle(
          showBubbleTail: true,
          bubbleShadow: shadowB,
        ),
      );
      expect(merged.showBubbleTail, isTrue);
      expect(merged.bubbleShadow, shadowB);

      final lerped = updated.lerp(
        const ConvoKitMessageListStyle(
          showBubbleTail: false,
          bubbleShadow: shadowB,
        ),
        0.75,
      );
      expect(lerped.showBubbleTail, isFalse);
      expect(lerped.bubbleShadow, isNotNull);
    });
  });
}
