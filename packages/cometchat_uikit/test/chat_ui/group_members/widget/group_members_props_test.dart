import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitGroupMembers (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 5);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(kit: kit, child: child),
      );
    }

    ConvoKit buildKit({bool groupsEnabled = true}) {
      return ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: groupsEnabled ? fake.groups : null,
        capabilities: ChatCapabilities(groups: groupsEnabled),
      );
    }

    testWidgets(
      'renders empty/disabled state cleanly when capabilities.groups is false and groups is null',
      (tester) async {
        var emptyCalled = false;

        await tester.pumpWidget(
          wrapWithScope(
            buildKit(groupsEnabled: false),
            ConvoKitGroupMembers(
              group: fake.groupsList.first,
              onEmpty: () => emptyCalled = true,
              emptyStateView: (_) => const Text('Members Disabled'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(emptyCalled, isTrue);
        expect(find.text('Members Disabled'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'loads members via GroupRepository.listMembers and invokes callbacks',
      (tester) async {
        List<ChatMember>? loaded;
        ChatMember? tapped;
        final group = fake.groupsList.first;

        await tester.pumpWidget(
          wrapWithScope(
            buildKit(),
            ConvoKitGroupMembers(
              group: group,
              onLoad: (members) => loaded = members,
              onItemTap: (member) => tapped = member,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(loaded, isNotNull);
        expect(loaded, isNotEmpty);

        final nonSelf = loaded!.firstWhere(
          (m) => m.user.id != fake.user1.id,
          orElse: () => loaded!.first,
        );
        expect(find.text(nonSelf.user.name), findsOneWidget);

        await tester.tap(find.text(nonSelf.user.name));
        await tester.pump();
        expect(tapped?.user.id, equals(nonSelf.user.id));
      },
    );

    testWidgets('supports selection mode and invokes onSelection', (
      tester,
    ) async {
      List<ChatMember>? selected;
      final group = fake.groupsList.first;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitGroupMembers(
            group: group,
            selectionMode: SelectionMode.multiple,
            activateSelection: ActivateSelection.onClick,
            onSelection: (members) => selected = members,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectable = (group.members ?? const <ChatMember>[]).firstWhere(
        (m) => m.role != GroupRole.owner && m.user.id != fake.user1.id,
      );

      await tester.tap(find.text(selectable.user.name));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check)));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.map((m) => m.user.id), equals([selectable.user.id]));
    });
  });
}
