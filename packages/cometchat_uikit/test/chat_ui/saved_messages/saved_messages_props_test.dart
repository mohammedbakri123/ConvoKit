import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConvoKitSavedMessages (Core models)', () {
    final user = const ChatUser(id: 'u1', name: 'Alice');
    final msg = TextMessage(
      id: 'm1',
      localId: 'l1',
      conversationId: 'c1',
      sender: user,
      createdAt: DateTime(2026, 1, 1),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Saved bookmark',
    );

    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: Translations.localizationsDelegates,
      supportedLocales: Translations.supportedLocales,
      home: child,
    );

    testWidgets('renders empty state when no initialMessages are supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ConvoKitSavedMessages(
            emptyStateView: (_) => const Text('Nothing saved'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing saved'), findsOneWidget);
    });

    testWidgets('renders saved ChatMessages and handles tap & unsave', (
      tester,
    ) async {
      ChatMessage? tapped;
      ChatMessage? unsaved;

      await tester.pumpWidget(
        wrap(
          ConvoKitSavedMessages(
            initialMessages: [msg],
            onItemTap: (m) => tapped = m,
            onUnsave: (m) async => unsaved = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved bookmark'), findsOneWidget);
      await tester.tap(find.text('Saved bookmark'));
      await tester.pump();
      expect(tapped, msg);

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      expect(unsaved, msg);
      expect(find.text('Saved bookmark'), findsNothing);
    });
  });
}
