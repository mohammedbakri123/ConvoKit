import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/app.dart';
import 'package:showcase_app/backend/studio_backend.dart';
import 'package:showcase_app/backend/studio_seed_data.dart';
import 'package:showcase_app/screens/chat/chat_screen.dart';
import 'package:showcase_app/screens/directory/group_members_screen.dart';
import 'package:showcase_app/screens/directory/people_groups_screen.dart';
import 'package:showcase_app/screens/search/search_screen.dart';
import 'package:showcase_app/theme/showcase_theme.dart';
import 'package:showcase_app/widgets/collapsing_glass_header.dart';

import '../helpers/showcase_test_helpers.dart';

void main() {
  setUp(() {
    installFakeVideoPlayerPlatform();
  });

  Widget wrapWithScope(StudioBackend backend, Widget home) {
    return ConvoKitScope(
      kit: backend.kit,
      child: MaterialApp(
        theme: ShowcaseTheme.lightTheme(),
        home: home,
      ),
    );
  }

  group('Phase R4 Directory, Group Members & Search', () {
    testWidgets(
      'PeopleGroupsScreen switches between ConvoKitUsers and ConvoKitGroups and opens ChatScreen & GroupMembersScreen',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(
          wrapWithScope(backend, const PeopleGroupsScreen()),
        );
        await pumpShowcaseFrames(tester);

        // Frosted glass header with predictable Back button & pill switcher.
        expect(find.byType(CollapsingGlassHeader), findsOneWidget);
        expect(find.byKey(const Key('people_groups_switcher')), findsOneWidget);

        // People segment mounts ConvoKitUsers with studio teammates & listPadding.
        expect(find.byType(ConvoKitUsers), findsOneWidget);
        final usersWidget = tester.widget<ConvoKitUsers>(
          find.byType(ConvoKitUsers),
        );
        expect(usersWidget.listPadding, isNotNull);
        expect(find.text('Tariq Mansour'), findsOneWidget);

        // Switch to Groups segment.
        await tester.tap(find.text('Groups'));
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitGroups), findsOneWidget);
        final groupsWidget = tester.widget<ConvoKitGroups>(
          find.byType(ConvoKitGroups),
        );
        expect(groupsWidget.listPadding, isNotNull);
        expect(find.text('Design Systems'), findsOneWidget);

        // Trailing action on a group opens GroupMembersScreen.
        await tester.tap(
          find.byKey(
            const Key(
              'group_members_action_${StudioSeedData.designSystemsGroupId}',
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(GroupMembersScreen), findsOneWidget);
        expect(find.byType(ConvoKitGroupMembers), findsOneWidget);
        expect(find.text('Owner'), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.text('Member'), findsWidgets);

        // Pop back to Groups and tap a group row to open group ChatScreen.
        await tester.tap(
          find
              .descendant(
                of: find.byType(GroupMembersScreen),
                matching: find.byTooltip('Back'),
              )
              .last,
        );
        await pumpShowcaseFrames(tester);

        await tester.tap(find.text('Design Systems'));
        await pumpShowcaseFrames(tester);

        expect(find.byType(ChatScreen), findsOneWidget);
        expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
      },
    );

    testWidgets(
      'GroupMembersScreen opens ConvoKitChangeScope modal and adds members via ConvoKitUsers SelectionMode.multiple',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        final brandRefreshGroup = backend.seedSnapshot.groups.firstWhere(
          (g) => g.id == StudioSeedData.brandRefreshGroupId,
        );

        await tester.pumpWidget(
          wrapWithScope(backend, GroupMembersScreen(group: brandRefreshGroup)),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitGroupMembers), findsOneWidget);
        final membersWidget = tester.widget<ConvoKitGroupMembers>(
          find.byType(ConvoKitGroupMembers),
        );
        expect(membersWidget.listPadding, isNotNull);
        expect(find.text('Claire Laurent'), findsOneWidget);

        // Tap a non-owner member to open ConvoKitChangeScope modal.
        await tester.tap(find.text('Claire Laurent'));
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitChangeScope), findsOneWidget);

        // Dismiss modal cleanly.
        await tester.tap(find.text('Cancel'));
        await pumpShowcaseFrames(tester);
        expect(find.byType(ConvoKitChangeScope), findsNothing);

        // Tap Add Members to open ConvoKitUsers in SelectionMode.multiple.
        await tester.tap(find.byKey(const Key('group_members_add_button')));
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitUsers), findsOneWidget);
        final usersWidget = tester.widget<ConvoKitUsers>(
          find.byType(ConvoKitUsers),
        );
        expect(usersWidget.selectionMode, SelectionMode.multiple);

        // Scroll Mateo Silva (index 5 in StudioSeedData.users) into view before
        // tapping, since R1 typography/spacing pushes lower rows past 600px.
        final usersListScrollable = find.descendant(
          of: find.descendant(
            of: find.byType(ConvoKitUsers),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        );
        final mateoFinder = find.text('Mateo Silva');
        await tester.scrollUntilVisible(
          mateoFinder,
          160,
          scrollable: usersListScrollable,
        );
        await tester.ensureVisible(mateoFinder);
        await pumpShowcaseFrames(tester);

        // Select a teammate not yet in Brand Refresh 2026 (Mateo Silva) and confirm.
        await tester.tap(mateoFinder);
        await pumpShowcaseFrames(tester);

        await tester.tap(find.byTooltip('Done'));
        await pumpShowcaseFrames(tester);

        // Returned to GroupMembersScreen and Mateo Silva is now in the roster.
        expect(find.byType(ConvoKitGroupMembers), findsOneWidget);
        final membersResult = await backend.groups.listMembers(
          StudioSeedData.brandRefreshGroupId,
        );
        final memberIds = membersResult.fold<List<String>>(
          onSuccess: (page) => page.items.map((m) => m.user.id).toList(),
          onFailure: (_) => const <String>[],
        );
        expect(memberIds, contains(StudioSeedData.mateoId));
      },
    );

    testWidgets(
      'SearchScreen mounts CometChatSearch, shows inline helper state, filters users, and opens direct ChatScreen on tap',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(
          wrapWithScope(backend, const SearchScreen()),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(CometChatSearch), findsOneWidget);
        expect(
          find.byKey(const Key('search_initial_helper_state')),
          findsOneWidget,
        );

        final searchField = find.descendant(
          of: find.byType(CometChatSearch),
          matching: find.byType(TextField),
        );
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Priya');
        await tester.pump(const Duration(milliseconds: 400));
        await pumpShowcaseFrames(tester);

        expect(find.text('Priya Nair'), findsOneWidget);

        await tester.tap(find.text('Priya Nair'));
        await pumpShowcaseFrames(tester);

        expect(find.byType(ChatScreen), findsOneWidget);
      },
    );

    testWidgets(
      'ChatsTab compose button opens PeopleGroupsScreen and Chat header info opens GroupMembersScreen',
      (tester) async {
        await tester.pumpWidget(const ShowcaseApp());
        await pumpShowcaseFrames(tester);

        // Tap Chats header compose button -> PeopleGroupsScreen.
        await tester.tap(find.byKey(const Key('chats_compose_button')));
        await pumpShowcaseFrames(tester);
        expect(find.byType(PeopleGroupsScreen), findsOneWidget);

        // Return to Chats tab.
        await tester.tap(
          find.descendant(
            of: find.byType(PeopleGroupsScreen),
            matching: find.byTooltip('Back'),
          ),
        );
        await pumpShowcaseFrames(tester);

        // Open Design Systems group chat and tap header to open GroupMembersScreen.
        await tester.tap(find.text('Design Systems'));
        await pumpShowcaseFrames(tester);
        expect(find.byType(ChatScreen), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(ConvoKitMessageHeader),
            matching: find.text('Design Systems'),
          ),
        );
        await pumpShowcaseFrames(tester);
        expect(find.byType(GroupMembersScreen), findsOneWidget);
      },
    );
  });
}
