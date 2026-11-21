import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../convokit/fake_chat_backend.dart';

void main() {
  group('Directory widgets L5 (listPadding)', () {
    ConvoKit buildKit(FakeChatBackend fake) {
      return ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        groups: fake.groups,
        events: fake.events,
        capabilities: const ChatCapabilities(groups: true, search: true),
      );
    }

    Widget wrap(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(
          kit: kit,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
      'ConvoKitUsers preserves null default and forwards custom listPadding',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 2);
        final kit = buildKit(fake);

        await tester.pumpWidget(wrap(kit, const ConvoKitUsers()));
        await tester.pumpAndSettle();

        final defaultListView = tester.widget<ListView>(find.byType(ListView));
        expect(defaultListView.padding, isNull);

        const customPadding = EdgeInsets.fromLTRB(12, 8, 12, 96);
        await tester.pumpWidget(
          wrap(kit, const ConvoKitUsers(listPadding: customPadding)),
        );
        await tester.pumpAndSettle();

        final paddedListView = tester.widget<ListView>(find.byType(ListView));
        expect(paddedListView.padding, customPadding);
      },
    );

    testWidgets(
      'ConvoKitGroups preserves null default and forwards custom listPadding',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 2);
        final kit = buildKit(fake);

        await tester.pumpWidget(wrap(kit, const ConvoKitGroups()));
        await tester.pumpAndSettle();

        final defaultListView = tester.widget<ListView>(find.byType(ListView));
        expect(defaultListView.padding, isNull);

        const customPadding = EdgeInsets.fromLTRB(12, 8, 12, 96);
        await tester.pumpWidget(
          wrap(kit, const ConvoKitGroups(listPadding: customPadding)),
        );
        await tester.pumpAndSettle();

        final paddedListView = tester.widget<ListView>(find.byType(ListView));
        expect(paddedListView.padding, customPadding);
      },
    );

    testWidgets(
      'ConvoKitGroupMembers preserves default/style listPadding and forwards widget listPadding',
      (tester) async {
        final fake = FakeChatBackend(seededMessageCount: 2);
        final kit = buildKit(fake);
        final group = fake.groupsList.first;

        await tester.pumpWidget(
          wrap(kit, ConvoKitGroupMembers(group: group)),
        );
        await tester.pumpAndSettle();

        final defaultListView = tester.widget<ListView>(find.byType(ListView));
        expect(defaultListView.padding, isNull);

        const stylePadding = EdgeInsets.only(bottom: 32);
        await tester.pumpWidget(
          wrap(
            kit,
            ConvoKitGroupMembers(
              group: group,
              style: const ConvoKitGroupMembersStyle(listPadding: stylePadding),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stylePaddedListView = tester.widget<ListView>(
          find.byType(ListView),
        );
        expect(stylePaddedListView.padding, stylePadding);

        const widgetPadding = EdgeInsets.fromLTRB(16, 8, 16, 96);
        await tester.pumpWidget(
          wrap(
            kit,
            ConvoKitGroupMembers(
              group: group,
              listPadding: widgetPadding,
              style: const ConvoKitGroupMembersStyle(listPadding: stylePadding),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final widgetPaddedListView = tester.widget<ListView>(
          find.byType(ListView),
        );
        expect(widgetPaddedListView.padding, widgetPadding);
      },
    );
  });
}
