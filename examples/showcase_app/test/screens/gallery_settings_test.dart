import 'package:convokit/convokit.dart'
    show ConversationsView, ConvoKitScope, MessageListView;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/app.dart';
import 'package:showcase_app/backend/studio_backend.dart';
import 'package:showcase_app/screens/calls/calls_tab.dart';
import 'package:showcase_app/screens/settings/settings_tab.dart';
import 'package:showcase_app/screens/updates/core_views_demo_screen.dart';
import 'package:showcase_app/screens/updates/saved_messages_screen.dart';
import 'package:showcase_app/screens/updates/updates_tab.dart';
import 'package:showcase_app/theme/showcase_theme.dart';
import 'package:showcase_app/widgets/collapsing_glass_header.dart';
import 'package:showcase_app/widgets/floating_glass_tab_bar.dart';

import '../helpers/showcase_test_helpers.dart';

void main() {
  setUp(() {
    installFakeVideoPlayerPlatform();
  });

  group('Phase R5 — Updates Gallery, Calls Tab, Settings & Core Views', () {
    testWidgets('UpdatesTab mounts hero card, extensions, bubbles, and primitives', (
      tester,
    ) async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      await tester.pumpWidget(
        ConvoKitScope(
          kit: backend.kit,
          child: MaterialApp(
            theme: ShowcaseTheme.lightTheme(),
            home: Scaffold(body: UpdatesTab(backend: backend)),
          ),
        ),
      );
      await pumpShowcaseFrames(tester);

      // Glass header & Atelier Studio Showcase Hero Card
      expect(find.byType(CollapsingGlassHeader), findsOneWidget);
      expect(find.byKey(const Key('updates_hero_card')), findsOneWidget);

      // Extensions gallery
      expect(find.byType(CometChatPollsBubble), findsOneWidget);
      expect(find.byType(CometChatStickerBubble), findsOneWidget);
      expect(find.byType(CometChatStickerKeyboard), findsOneWidget);
      expect(find.byType(StickerAuxiliaryButton), findsOneWidget);
      expect(find.byType(MessageTranslationBubble), findsOneWidget);
      expect(find.byType(CometChatLinkPreviewBubble), findsOneWidget);
      expect(find.byType(ImageModerationFilter), findsOneWidget);
      expect(find.byType(CometChatCollaborativeBubble), findsOneWidget);
      expect(find.byType(ConvoKitCardView), findsOneWidget);
      expect(find.byType(CometChatCard), findsOneWidget);

      // Bubbles & media viewers gallery
      expect(find.byType(CometChatTextBubble), findsWidgets);
      expect(find.byType(CometChatVoiceNoteBubble), findsOneWidget);
      expect(find.byType(CometChatAudioPlayer), findsOneWidget);
      // ignore: deprecated_member_use
      expect(find.byType(CometChatImageBubble), findsOneWidget);
      expect(find.byType(CometChatImagesBubble), findsOneWidget);
      // ignore: deprecated_member_use
      expect(find.byType(CometChatVideoBubble), findsOneWidget);
      expect(find.byType(CometChatVideosBubble), findsOneWidget);
      expect(find.byType(CometChatAudiosBubble), findsOneWidget);
      // ignore: deprecated_member_use
      expect(find.byType(CometChatFileBubble), findsOneWidget);
      expect(find.byType(CometChatFilesBubble), findsOneWidget);
      expect(find.byType(CometChatMediaGrid), findsWidgets);
      expect(find.byType(CometChatMediaCaption), findsWidgets);
      expect(find.byType(CometChatMediaPlaceholder), findsWidgets);
      expect(find.byType(CometChatVideoFirstFrame), findsWidgets);
      expect(find.byType(ConvoKitDeletedBubble), findsOneWidget);
      expect(find.byType(ConvoKitActionBubble), findsWidgets);

      // Reactions, composer & interactive primitives
      expect(find.byType(CometChatReactions), findsOneWidget);
      expect(find.byType(CometChatReactionList), findsOneWidget);
      expect(find.byType(ConvoKitMessagePreview), findsOneWidget);
      expect(find.byType(ConvoKitEmojiKeyboard), findsOneWidget);
      expect(find.byType(CometChatMediaRecorder), findsOneWidget);
      expect(find.byType(CometChatQuickView), findsOneWidget);
      expect(find.byType(CometChatSingleSelect), findsOneWidget);
      expect(find.byType(CometChatTimeSlotSelector), findsOneWidget);
      expect(find.byType(CometChatDecoratedContainer), findsOneWidget);
      expect(find.byType(DottedBorder), findsOneWidget);
      expect(find.byType(CometChatMarquee), findsOneWidget);
      expect(find.byType(SectionSeparator), findsWidgets);
      expect(find.byType(GetMenuView), findsOneWidget);
      expect(find.byType(SearchFilterChip), findsWidgets);
      expect(find.byType(CometChatAttachmentOptionSheet), findsOneWidget);
      expect(find.byType(CometchatMessageOptionSheet), findsOneWidget);
    });

    testWidgets(
      'CallsTab mounts CollapsingGlassHeader, CometChatCard, and ConvoKitActionBubble',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ShowcaseTheme.lightTheme(),
            home: const Scaffold(body: CallsTab()),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(CollapsingGlassHeader), findsOneWidget);
        expect(find.byKey(const Key('calls_status_hero_card')), findsOneWidget);
        expect(find.byType(CometChatCard), findsOneWidget);
        expect(find.byType(ConvoKitActionBubble), findsNWidgets(2));
        expect(find.textContaining('cometchat_calls_sdk'), findsWidgets);
      },
    );

    testWidgets(
      'SettingsTab toggles Light/Dark theme, shimmer preview, and ConvoKitConfirmDialog',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(ShowcaseApp(backend: backend));
        await pumpShowcaseFrames(tester);

        // Switch to Settings tab via FloatingGlassTabBar
        final navBar = find.byType(FloatingGlassTabBar);
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Settings')),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(SettingsTab), findsOneWidget);
        expect(
          find.byKey(const Key('settings_profile_hero_card')),
          findsOneWidget,
        );
        expect(find.byType(ConvoKitListItem), findsWidgets);
        expect(find.byType(ConvoKitAvatar), findsWidgets);
        expect(find.byType(ConvoKitStatusIndicator), findsWidgets);
        expect(find.byType(ConvoKitBadge), findsWidgets);
        expect(find.byType(ConvoKitDate), findsWidgets);
        expect(find.byType(ConvoKitReceipt), findsWidgets);
        expect(find.byType(SwipeTile), findsOneWidget);

        // Toggle Dark Mode via Settings switch
        final themeSwitch = find.byKey(const Key('settings_theme_switch'));
        await tester.ensureVisible(themeSwitch);
        await tester.tap(themeSwitch);
        await pumpShowcaseFrames(tester);

        final darkContext = tester.element(find.byType(ShowcaseShell));
        final darkPalette = ConvoKitThemeHelper.getColorPalette(darkContext);
        expect(darkPalette.primary, ShowcaseColors.darkAccent);
        expect(darkPalette.background1, ShowcaseColors.darkSurface);

        // Toggle ConvoKitShimmerEffect on and back off
        final shimmerToggle = find.byKey(const Key('settings_shimmer_toggle'));
        await tester.ensureVisible(shimmerToggle);
        await tester.tap(shimmerToggle);
        await tester.pump();
        expect(find.byType(ConvoKitShimmerEffect), findsOneWidget);

        await tester.tap(shimmerToggle);
        await pumpShowcaseFrames(tester);
        expect(find.byType(ConvoKitShimmerEffect), findsNothing);

        // Open Reset Demo Data ConvoKitConfirmDialog and confirm
        final resetButton = find.byKey(
          const Key('settings_reset_demo_button'),
        );
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton);
        await pumpShowcaseFrames(tester);

        expect(find.text('Reset Demo Data?'), findsOneWidget);
        await tester.tap(find.text('Reset'));
        await pumpShowcaseFrames(tester);

        expect(
          find.text('Atelier Studio demo data restored.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('SavedMessagesScreen mounts ConvoKitSavedMessages', (
      tester,
    ) async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      await tester.pumpWidget(
        ConvoKitScope(
          kit: backend.kit,
          child: MaterialApp(
            theme: ShowcaseTheme.lightTheme(),
            home: SavedMessagesScreen(backend: backend),
          ),
        ),
      );
      await pumpShowcaseFrames(tester);

      expect(find.byType(ConvoKitSavedMessages), findsOneWidget);
      expect(find.text('Saved Messages'), findsOneWidget);
    });

    testWidgets(
      'CoreViewsDemoScreen mounts ConversationsView and MessageListView from convokit.dart',
      (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(
          ConvoKitScope(
            kit: backend.kit,
            child: MaterialApp(
              theme: ShowcaseTheme.lightTheme(),
              home: const CoreViewsDemoScreen(),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ConversationsView), findsOneWidget);
        expect(find.byType(MessageListView), findsOneWidget);
        expect(find.text('Design Systems'), findsWidgets);
      },
    );
  });
}
