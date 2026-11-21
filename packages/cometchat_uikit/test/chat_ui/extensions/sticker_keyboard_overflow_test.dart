import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'CometChatStickerKeyboard renders compact height without RenderFlex overflow',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: CometChatStickerKeyboard(
                  height: 160,
                  onStickerTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CometChatStickerKeyboard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
