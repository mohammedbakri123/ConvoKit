import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: Translations.localizationsDelegates,
      supportedLocales: Translations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('CometChatGroupListItem (ChatGroup)', () {
    testWidgets('renders group name, member count, and tap/long-press', (
      tester,
    ) async {
      const group = ChatGroup(
        id: 'g1',
        name: 'Engineering',
        type: GroupType.public,
        memberCount: 5,
      );
      ChatGroup? clicked;
      ChatGroup? longClicked;

      await tester.pumpWidget(
        wrap(
          CometChatGroupListItem(
            group: group,
            onItemClick: (g) => clicked = g,
            onItemLongClick: (g) => longClicked = g,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);

      await tester.tap(find.text('Engineering'));
      await tester.pump();
      expect(clicked?.id, equals('g1'));

      await tester.longPress(find.text('Engineering'));
      await tester.pump();
      expect(longClicked?.id, equals('g1'));
    });

    testWidgets('shows private and passwordProtected type indicators', (
      tester,
    ) async {
      const privateGroup = ChatGroup(
        id: 'g_priv',
        name: 'Private Team',
        type: GroupType.private,
        memberCount: 2,
      );
      const protectedGroup = ChatGroup(
        id: 'g_pass',
        name: 'Secret Team',
        type: GroupType.passwordProtected,
        memberCount: 3,
      );

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              CometChatGroupListItem(
                group: privateGroup,
                onItemClick: (_) {},
              ),
              CometChatGroupListItem(
                group: protectedGroup,
                onItemClick: (_) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('renders selection checkbox and fires onSelectionToggle', (
      tester,
    ) async {
      var toggled = false;
      const group = ChatGroup(
        id: 'g_sel',
        name: 'Design',
        type: GroupType.public,
        memberCount: 1,
      );

      await tester.pumpWidget(
        wrap(
          CometChatGroupListItem(
            group: group,
            onItemClick: (_) {},
            selectionMode: SelectionMode.multiple,
            isSelected: true,
            onSelectionToggle: () => toggled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(toggled, isTrue);
    });
  });
}
