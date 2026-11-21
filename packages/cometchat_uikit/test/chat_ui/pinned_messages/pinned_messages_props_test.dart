import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConvoKitPinnedMessages (Core models)', () {
    final user = const ChatUser(id: 'u1', name: 'Alice');
    final msg = TextMessage(
      id: 'm1',
      localId: 'l1',
      conversationId: 'c1',
      sender: user,
      createdAt: DateTime(2026, 1, 1),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Pinned hello',
    );

    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: Translations.localizationsDelegates,
      supportedLocales: Translations.supportedLocales,
      home: Scaffold(body: child),
    );

    testWidgets('renders empty state when no initialMessages are supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ConvoKitPinnedMessages(
            user: user,
            emptyStateView: (_) => const Text('Nothing pinned'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing pinned'), findsOneWidget);
    });

    testWidgets('renders pinned ChatMessages and handles tap & unpin', (
      tester,
    ) async {
      ChatMessage? tapped;
      ChatMessage? unpinned;

      await tester.pumpWidget(
        wrap(
          ConvoKitPinnedMessages(
            user: user,
            initialMessages: [msg],
            onItemTap: (m) => tapped = m,
            onUnpin: (m) async => unpinned = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pinned hello', findRichText: true), findsOneWidget);
      await tester.tap(find.text('Pinned hello', findRichText: true));
      await tester.pump();
      expect(tapped, msg);

      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();
      expect(unpinned, msg);
      expect(find.text('Pinned hello', findRichText: true), findsNothing);
    });
  });
}
