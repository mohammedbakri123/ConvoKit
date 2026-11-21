import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Extensions widgets (Core models, zero SDK)', () {
    const sender = ChatUser(id: 'u1', name: 'Alice');

    test('ExtensionModerator scans injected extensions in CustomMessage.data', () {
      final msg = CustomMessage(
        id: 'm1',
        localId: 'l1',
        conversationId: 'c1',
        sender: sender,
        createdAt: DateTime(2026, 1, 1),
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
        kind: ExtensionConstants.polls,
        data: {
          '@injected': {
            ExtensionConstants.extensions: {
              ExtensionConstants.polls: {'question': 'Lunch?'},
            },
          },
        },
      );

      final result = ExtensionModerator.extensionCheck(msg);
      expect(result, isNotNull);
      expect(result!.containsKey(ExtensionConstants.polls), isTrue);
    });

    testWidgets('CometChatStickerKeyboard renders empty state without SDK', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
          home: Scaffold(
            body: CometChatStickerKeyboard(
              emptyStateView: (_) => const Text('No stickers available'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No stickers available'), findsOneWidget);
    });
  });
}
