import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/app.dart';
import 'package:showcase_app/backend/studio_backend.dart';
import 'package:showcase_app/backend/studio_seed_data.dart';
import 'package:showcase_app/screens/chat/chat_screen.dart';
import 'package:showcase_app/screens/chat/create_poll_sheet.dart';
import 'package:showcase_app/screens/chat/message_info_sheet.dart';
import 'package:showcase_app/screens/chat/pinned_messages_sheet.dart';
import 'package:showcase_app/screens/chat/thread_screen.dart';
import 'package:showcase_app/screens/chats/chats_tab.dart';
import 'package:showcase_app/screens/directory/group_members_screen.dart';
import 'package:showcase_app/screens/directory/people_groups_screen.dart';
import 'package:showcase_app/screens/search/search_screen.dart';
import 'package:showcase_app/theme/showcase_theme.dart';
import 'package:showcase_app/theme/showcase_tokens.dart';
import 'package:showcase_app/widgets/floating_glass_tab_bar.dart';

import 'helpers/showcase_test_helpers.dart';

void main() {
  setUp(() {
    installFakeVideoPlayerPlatform();
  });

  group('Phase R6 End-to-End Smoke Test (Light & Dark)', () {
    for (final themeMode in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final isDark = themeMode == ThemeMode.dark;
      final modeLabel = isDark ? 'Dark' : 'Light';

      testWidgets(
        'Chats -> Chat -> send message -> directional tail & >=4.5:1 readable text/timestamp -> Back ($modeLabel mode)',
        (tester) async {
          final backend = StudioBackend.create();
          addTearDown(backend.dispose);

          await tester.pumpWidget(
            ShowcaseApp(initialThemeMode: themeMode, backend: backend),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(FloatingGlassTabBar), findsOneWidget);
          expect(find.byType(ConvoKitConversations), findsOneWidget);
          expect(find.text('Priya Nair'), findsOneWidget);
          expect(find.text('Design Systems'), findsOneWidget);

          // 1. Tap a seeded direct chat to push ChatScreen.
          await tester.tap(find.text('Priya Nair'));
          await pumpShowcaseFrames(tester);

          expect(find.byType(ChatScreen), findsOneWidget);
          expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
          expect(find.byType(ConvoKitMessageList), findsOneWidget);
          expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(ConvoKitMessageList),
              matching: find.text(
                'Can we review the color balance together before lunch?',
              ),
            ),
            findsOneWidget,
          );

          // 2. Enter text into ConvoKitMessageComposer and tap Send.
          final outgoingText = 'Looking great in $modeLabel mode — 11:30 works!';
          final composerInput = find.descendant(
            of: find.byType(ConvoKitMessageComposer),
            matching: find.byType(TextField),
          );
          expect(composerInput, findsOneWidget);

          await tester.enterText(composerInput, outgoingText);
          await tester.pump();

          final sendButton = find.descendant(
            of: find.byType(ConvoKitMessageComposer),
            matching: find.byTooltip('Send Message'),
          );
          expect(sendButton, findsOneWidget);

          await tester.tap(sendButton);
          await tester.pump(const Duration(milliseconds: 400));
          await pumpShowcaseFrames(tester);

          // 3. Verify the sent message renders inside ConvoKitMessageList
          //    with a directional outgoing tail.
          final sentTextFinder = find.descendant(
            of: find.byType(ConvoKitMessageList),
            matching: find.text(outgoingText),
          );
          expect(sentTextFinder, findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(ConvoKitMessageList),
              matching: find.byKey(const Key('outgoing_bubble_tail')),
            ),
            findsWidgets,
          );

          // 4. Verify rendered outgoing bubble color, text contrast (>=4.5:1),
          //    and timestamp contrast (>=4.5:1) in the active mode.
          final expectedBubbleBg = isDark
              ? ShowcaseTokens.darkOutgoingBubble
              : ShowcaseTokens.lightOutgoingBubble;
          final expectedTextColor = isDark
              ? ShowcaseTokens.darkOutgoingText
              : ShowcaseTokens.lightOutgoingText;
          final expectedTimestampColor = isDark
              ? ShowcaseTokens.darkOutgoingTimestamp
              : ShowcaseTokens.lightOutgoingTimestamp;

          final bubbleContainerFinder = find.ancestor(
            of: sentTextFinder,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Container) return false;
              final decoration = widget.decoration;
              return decoration is BoxDecoration &&
                  decoration.color == expectedBubbleBg;
            }),
          );
          expect(bubbleContainerFinder, findsWidgets);

          final sentTextWidget = tester.widget<Text>(sentTextFinder);
          final renderedTextColor = sentTextWidget.style?.color;
          expect(renderedTextColor, expectedTextColor);
          expect(
            ShowcaseTokens.contrastRatio(renderedTextColor!, expectedBubbleBg),
            greaterThanOrEqualTo(4.5),
          );

          final timestampPattern = RegExp(r'^\d{2}:\d{2}$');
          final bubbleTimestampFinder = find.descendant(
            of: bubbleContainerFinder.first,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data != null &&
                  timestampPattern.hasMatch(widget.data!),
            ),
          );
          expect(bubbleTimestampFinder, findsOneWidget);

          final timestampWidget = tester.widget<Text>(bubbleTimestampFinder);
          final renderedTimestampColor = timestampWidget.style?.color;
          expect(renderedTimestampColor, expectedTimestampColor);
          expect(
            ShowcaseTokens.contrastRatio(
              renderedTimestampColor!,
              expectedBubbleBg,
            ),
            greaterThanOrEqualTo(4.5),
          );

          // 5. Predictable back navigation returns cleanly to ChatsTab.
          final chatBackButton = find.descendant(
            of: find.byType(ConvoKitMessageHeader),
            matching: find.bySemanticsLabel('Back'),
          );
          expect(chatBackButton, findsOneWidget);
          await tester.tap(chatBackButton);
          await pumpShowcaseFrames(tester, frames: 15);

          expect(find.byType(ChatScreen), findsNothing);
          expect(find.byType(ChatsTab), findsOneWidget);
          expect(find.byType(FloatingGlassTabBar), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'predictable back navigation across pushed routes (PeopleGroups, GroupMembers, Search)',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(ShowcaseApp(backend: backend));
        await pumpShowcaseFrames(tester);

        // Route 1: ChatsTab -> PeopleGroupsScreen -> GroupMembersScreen -> Back -> Back
        await tester.tap(find.byKey(const Key('chats_compose_button')));
        await pumpShowcaseFrames(tester);
        expect(find.byType(PeopleGroupsScreen), findsOneWidget);

        await tester.tap(find.text('Groups'));
        await pumpShowcaseFrames(tester);
        expect(find.byType(ConvoKitGroups), findsOneWidget);

        await tester.tap(
          find.byKey(
            const Key(
              'group_members_action_${StudioSeedData.designSystemsGroupId}',
            ),
          ),
        );
        await pumpShowcaseFrames(tester);
        expect(find.byType(GroupMembersScreen), findsOneWidget);

        // Back from GroupMembersScreen -> PeopleGroupsScreen
        await tester.tap(
          find
              .descendant(
                of: find.byType(GroupMembersScreen),
                matching: find.byTooltip('Back'),
              )
              .last,
        );
        await pumpShowcaseFrames(tester, frames: 15);
        expect(find.byType(GroupMembersScreen), findsNothing);
        expect(find.byType(PeopleGroupsScreen), findsOneWidget);

        // Back from PeopleGroupsScreen -> ChatsTab
        await tester.tap(
          find
              .descendant(
                of: find.byType(PeopleGroupsScreen),
                matching: find.byTooltip('Back'),
              )
              .first,
        );
        await pumpShowcaseFrames(tester, frames: 15);
        expect(find.byType(PeopleGroupsScreen), findsNothing);
        expect(find.byType(ChatsTab), findsOneWidget);

        // Route 2: ChatsTab -> SearchScreen -> Back
        final chatsSearchField = find.descendant(
          of: find.byType(ConvoKitConversations),
          matching: find.byType(TextField),
        );
        expect(chatsSearchField, findsOneWidget);
        await tester.tap(chatsSearchField);
        await pumpShowcaseFrames(tester);
        expect(find.byType(SearchScreen), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(SearchScreen),
            matching: find.byIcon(Icons.arrow_back_rounded),
          ),
        );
        await pumpShowcaseFrames(tester, frames: 15);
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byType(ChatsTab), findsOneWidget);
        expect(find.byType(FloatingGlassTabBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'mounts ThreadScreen and chat modal sheets using library widgets',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        final designSystemsMessages =
            backend.seedSnapshot.messagesByConversation[
                StudioSeedData.designSystemsConvId]!;
        final parentMessage = designSystemsMessages.first;
        final designSystemsGroup = backend.seedSnapshot.groups.first;
        final pinnedMessages = backend.messages.getPinnedMessages(
          StudioSeedData.designSystemsConvId,
        );

        // 1. ThreadScreen
        await tester.pumpWidget(
          ConvoKitScope(
            kit: backend.kit,
            child: MaterialApp(
              theme: ShowcaseTheme.lightTheme(),
              home: ThreadScreen(
                conversationId: StudioSeedData.designSystemsConvId,
                parentMessage: parentMessage,
                group: designSystemsGroup,
                initialReplyCount: 2,
              ),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitThreadedHeader), findsOneWidget);
        expect(find.byType(ConvoKitMessageList), findsOneWidget);
        expect(find.byType(ConvoKitMessageComposer), findsOneWidget);

        // 2. PinnedMessagesSheet
        await tester.pumpWidget(
          ConvoKitScope(
            kit: backend.kit,
            child: MaterialApp(
              theme: ShowcaseTheme.lightTheme(),
              home: Scaffold(
                body: PinnedMessagesSheet(
                  conversationId: StudioSeedData.designSystemsConvId,
                  group: designSystemsGroup,
                  initialMessages: pinnedMessages,
                ),
              ),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConvoKitPinnedMessages), findsOneWidget);

        // 3. MessageInfoSheet
        await tester.pumpWidget(
          ConvoKitScope(
            kit: backend.kit,
            child: MaterialApp(
              theme: ShowcaseTheme.lightTheme(),
              home: Scaffold(
                body: MessageInfoSheet(message: parentMessage),
              ),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(CometChatMessageInformation), findsOneWidget);

        // 4. CreatePollSheet
        await tester.pumpWidget(
          ConvoKitScope(
            kit: backend.kit,
            child: MaterialApp(
              theme: ShowcaseTheme.lightTheme(),
              home: Scaffold(
                body: CreatePollSheet(
                  conversationId: StudioSeedData.designSystemsConvId,
                  group: designSystemsGroup,
                ),
              ),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(CometChatCreatePoll), findsOneWidget);
      },
    );
  });
}
