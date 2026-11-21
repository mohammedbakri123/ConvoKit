import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/app.dart';
import 'package:showcase_app/theme/showcase_theme.dart';
import 'package:showcase_app/theme/showcase_tokens.dart';
import 'package:showcase_app/widgets/collapsing_glass_header.dart';
import 'package:showcase_app/widgets/floating_glass_tab_bar.dart';
import 'package:showcase_app/widgets/glass_surface.dart';

import 'helpers/showcase_test_helpers.dart';

void main() {
  setUp(() {
    installFakeVideoPlayerPlatform();
  });

  group('ShowcaseApp Liquid Glass shell & theme', () {
    testWidgets(
      'renders 4-tab FloatingGlassTabBar in Light mode with extendBody and accessible labels',
      (tester) async {
        await tester.pumpWidget(const ShowcaseApp());

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.byType(FloatingGlassTabBar), findsOneWidget);

        final shellScaffold = tester.widget<Scaffold>(
          find
              .descendant(
                of: find.byType(ShowcaseShell),
                matching: find.byType(Scaffold),
              )
              .first,
        );
        expect(shellScaffold.extendBody, isTrue);
        expect(shellScaffold.appBar, isNull);

        final navBar = find.byType(FloatingGlassTabBar);
        for (final label in const <String>[
          'Chats',
          'Updates',
          'Calls',
          'Settings',
        ]) {
          final tabFinder = find.descendant(
            of: navBar,
            matching: find.text(label),
          );
          expect(tabFinder, findsOneWidget);
          expect(
            find.descendant(
              of: navBar,
              matching: find.bySemanticsLabel(label),
            ),
            findsOneWidget,
          );
          final tabSize = tester.getSize(
            find.byKey(Key('floating_glass_tab_${label.toLowerCase()}')),
          );
          expect(
            tabSize.height,
            greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
          );
          expect(
            tabSize.width,
            greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
          );
        }

        final context = tester.element(find.byType(ShowcaseShell));
        final palette = ConvoKitThemeHelper.getColorPalette(context);
        expect(palette.primary, ShowcaseColors.lightAccent);
        expect(palette.background1, ShowcaseColors.lightSurface);
        expect(palette.textHighlight, ShowcaseColors.lightTitle);

        final listStyle = ShowcaseTheme.messageListStyle(context);
        expect(listStyle.backgroundColor, ShowcaseColors.lightCanvas);
        expect(listStyle.outgoingTextColor, ShowcaseColors.lightOutgoingText);
        expect(
          listStyle.outgoingMessageBubbleStyle?.backgroundColor,
          ShowcaseColors.lightOutgoingBubble,
        );
        expect(
          listStyle.incomingMessageBubbleStyle?.backgroundColor,
          ShowcaseColors.lightIncomingBubble,
        );
        expect(
          listStyle.outgoingMessageBubbleStyle?.messageBubbleDateStyle?.textColor,
          ShowcaseColors.lightOutgoingTimestamp,
        );
        expect(
          listStyle
              .outgoingMessageBubbleStyle
              ?.messageBubbleDateStyle
              ?.textStyle
              ?.color,
          ShowcaseColors.lightOutgoingTimestamp,
        );
      },
    );

    testWidgets('switches between all 4 tabs cleanly in Light mode', (
      tester,
    ) async {
      await tester.pumpWidget(const ShowcaseApp());

      final navBar = find.byType(FloatingGlassTabBar);
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Updates')),
      );
      await pumpShowcaseFrames(tester);
      expect(
        tester.widget<FloatingGlassTabBar>(navBar).currentIndex,
        1,
      );
      expect(
        find.descendant(
          of: find.byType(CollapsingGlassHeader),
          matching: find.text('Updates'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Calls')),
      );
      await pumpShowcaseFrames(tester);
      expect(
        tester.widget<FloatingGlassTabBar>(navBar).currentIndex,
        2,
      );
      expect(
        find.descendant(
          of: find.byType(CollapsingGlassHeader),
          matching: find.text('Calls'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Settings')),
      );
      await pumpShowcaseFrames(tester);
      expect(
        tester.widget<FloatingGlassTabBar>(navBar).currentIndex,
        3,
      );
      expect(
        find.descendant(
          of: find.byType(CollapsingGlassHeader),
          matching: find.text('Settings'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Chats')),
      );
      await pumpShowcaseFrames(tester);
      expect(
        tester.widget<FloatingGlassTabBar>(navBar).currentIndex,
        0,
      );
      expect(find.byKey(const Key('showcase_theme_toggle')), findsOneWidget);
    });

    testWidgets(
      'renders Dark mode palette, switches tabs, and toggles live',
      (tester) async {
        await tester.pumpWidget(
          const ShowcaseApp(initialThemeMode: ThemeMode.dark),
        );

        final navBar = find.byType(FloatingGlassTabBar);
        expect(navBar, findsOneWidget);

        final darkContext = tester.element(find.byType(ShowcaseShell));
        final darkPalette = ConvoKitThemeHelper.getColorPalette(darkContext);
        expect(darkPalette.primary, ShowcaseColors.darkAccent);
        expect(darkPalette.background1, ShowcaseColors.darkSurface);
        expect(darkPalette.background3, ShowcaseColors.darkCanvas);

        final darkListStyle = ShowcaseTheme.messageListStyle(darkContext);
        expect(darkListStyle.backgroundColor, ShowcaseColors.darkCanvas);
        expect(darkListStyle.outgoingTextColor, ShowcaseColors.darkOutgoingText);
        expect(
          darkListStyle.outgoingMessageBubbleStyle?.backgroundColor,
          ShowcaseColors.darkOutgoingBubble,
        );
        expect(
          darkListStyle.incomingMessageBubbleStyle?.backgroundColor,
          ShowcaseColors.darkIncomingBubble,
        );
        expect(
          darkListStyle
              .outgoingMessageBubbleStyle
              ?.messageBubbleDateStyle
              ?.textColor,
          ShowcaseColors.darkOutgoingTimestamp,
        );
        expect(
          darkListStyle
              .outgoingMessageBubbleStyle
              ?.messageBubbleDateStyle
              ?.textStyle
              ?.color,
          ShowcaseColors.darkOutgoingTimestamp,
        );

        // Switch to Settings tab in Dark mode and verify live theme toggle.
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Settings')),
        );
        await pumpShowcaseFrames(tester);
        expect(tester.widget<FloatingGlassTabBar>(navBar).currentIndex, 3);

        await tester.tap(find.byKey(const Key('showcase_theme_toggle')));
        await pumpShowcaseFrames(tester);

        final lightContext = tester.element(find.byType(ShowcaseShell));
        final lightPalette = ConvoKitThemeHelper.getColorPalette(lightContext);
        expect(lightPalette.primary, ShowcaseColors.lightAccent);
        expect(lightPalette.background1, ShowcaseColors.lightSurface);
      },
    );
  });

  group('Phase R2 Liquid Glass chrome & reduced-motion behavior', () {
    testWidgets(
      'FloatingGlassTabBar honors reduced motion by snapping active pill duration to zero',
      (tester) async {
        const items = <FloatingGlassTabItem>[
          FloatingGlassTabItem(
            label: 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
          ),
          FloatingGlassTabItem(
            label: 'Updates',
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
          ),
          FloatingGlassTabItem(
            label: 'Calls',
            icon: Icons.call_outlined,
            activeIcon: Icons.call_rounded,
          ),
          FloatingGlassTabItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
          ),
        ];

        Widget buildBar({required bool disableAnimations, required int index}) {
          return MaterialApp(
            theme: ShowcaseTheme.lightTheme(),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Scaffold(
                bottomNavigationBar: FloatingGlassTabBar(
                  items: items,
                  currentIndex: index,
                  onTap: (_) {},
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(
          buildBar(disableAnimations: false, index: 0),
        );
        final normalPill = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('floating_glass_tab_active_pill')),
        );
        expect(normalPill.duration, ShowcaseMotion.enterDuration);

        await tester.pumpWidget(
          buildBar(disableAnimations: true, index: 2),
        );
        final reducedPill = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('floating_glass_tab_active_pill')),
        );
        expect(reducedPill.duration, Duration.zero);
      },
    );

    testWidgets(
      'CollapsingGlassHeader transitions from displayTitle to compactTitle inside GlassSurface past 44px',
      (tester) async {
        Widget buildHeader({required double offset}) {
          return MaterialApp(
            theme: ShowcaseTheme.lightTheme(),
            home: Scaffold(
              body: CollapsingGlassHeader(
                title: 'Chats',
                scrollOffset: offset,
                actions: <GlassHeaderAction>[
                  GlassHeaderAction(
                    key: const Key('header_compose_action'),
                    icon: Icons.edit_square,
                    tooltip: 'New chat',
                    onPressed: () {},
                  ),
                  GlassHeaderAction(
                    key: const Key('header_theme_action'),
                    icon: Icons.dark_mode_outlined,
                    tooltip: 'Switch to Dark Mode',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }

        await tester.pumpWidget(buildHeader(offset: 0));
        final expandedText = tester.widget<Text>(find.text('Chats'));
        expect(
          expandedText.style?.fontSize,
          ShowcaseTypography.displayTitle.fontSize,
        );
        expect(
          expandedText.style?.fontWeight,
          ShowcaseTypography.displayTitle.fontWeight,
        );
        // Only the trailing action capsule uses GlassSurface at offset 0.
        expect(find.byType(GlassSurface), findsOneWidget);
        expect(
          find.byKey(const Key('collapsing_header_action_capsule')),
          findsOneWidget,
        );

        final composeSize = tester.getSize(
          find.byKey(const Key('header_compose_action')),
        );
        final themeSize = tester.getSize(
          find.byKey(const Key('header_theme_action')),
        );
        expect(
          composeSize.width,
          greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
        );
        expect(
          composeSize.height,
          greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
        );
        expect(
          themeSize.width,
          greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
        );
        expect(
          themeSize.height,
          greaterThanOrEqualTo(ShowcaseTokens.minTouchTarget),
        );

        await tester.pumpWidget(buildHeader(offset: 60));
        final compactText = tester.widget<Text>(find.text('Chats'));
        expect(
          compactText.style?.fontSize,
          ShowcaseTypography.compactTitle.fontSize,
        );
        expect(
          compactText.style?.fontWeight,
          ShowcaseTypography.compactTitle.fontWeight,
        );
        // Collapsed bar mounts the frosted GlassSurface behind the header.
        expect(find.byType(GlassSurface), findsNWidgets(2));
        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );
  });

  group('Phase R1 design tokens, WCAG >=4.5:1 contrast & avatar palette', () {
    test('WCAG >=4.5:1 contrast holds across Light, Dark, and avatar hues', () {
      // Light outgoing (#DCF8C6) & incoming (#FFFFFF)
      expect(
        ShowcaseTokens.lightOutgoingBubble,
        const Color(0xFFDCF8C6),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.lightOutgoingText,
          ShowcaseTokens.lightOutgoingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.lightOutgoingTimestamp,
          ShowcaseTokens.lightOutgoingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.lightTextPrimary,
          ShowcaseTokens.lightIncomingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.lightTextSecondary,
          ShowcaseTokens.lightIncomingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.lightPrimaryStrong,
          ShowcaseTokens.lightSurfaceContainerLowest,
        ),
        greaterThanOrEqualTo(4.5),
      );

      // Dark outgoing (#005C4B) & incoming (#1F2D36)
      expect(
        ShowcaseTokens.darkOutgoingBubble,
        const Color(0xFF005C4B),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.darkOutgoingText,
          ShowcaseTokens.darkOutgoingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.darkOutgoingTimestamp,
          ShowcaseTokens.darkOutgoingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.darkTextPrimary,
          ShowcaseTokens.darkIncomingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ShowcaseTokens.contrastRatio(
          ShowcaseTokens.darkTextSecondary,
          ShowcaseTokens.darkIncomingBubble,
        ),
        greaterThanOrEqualTo(4.5),
      );

      // 8-hue studio avatar monogram palette against white monogram text
      expect(ShowcaseTokens.avatarMonogramPalette, hasLength(8));
      for (final hue in ShowcaseTokens.avatarMonogramPalette) {
        expect(
          ShowcaseTokens.contrastRatio(
            ShowcaseTokens.avatarMonogramTextColor,
            hue,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('tokens enforce Liquid Glass, M3 Expressive, touch & motion rules', () {
      expect(ShowcaseTokens.glassBlurSigma, 24.0);
      expect(ShowcaseTokens.radiusNavCapsule, 30.0);
      expect(ShowcaseTokens.radiusNavActivePill, 22.0);
      expect(ShowcaseTokens.radiusHeroCard, 24.0);
      expect(ShowcaseTokens.radiusNestedCard, 16.0);
      expect(ShowcaseTokens.radiusBubble, 20.0);
      expect(ShowcaseTokens.minTouchTarget, greaterThanOrEqualTo(44.0));
      expect(ShowcaseTokens.minControlGap, greaterThanOrEqualTo(8.0));

      expect(ShowcaseTypography.displayTitle.fontSize, 34);
      expect(ShowcaseTypography.displayTitle.fontWeight, FontWeight.w800);
      expect(ShowcaseTypography.compactTitle.fontSize, 17);
      expect(ShowcaseTypography.compactTitle.fontWeight, FontWeight.w600);
      expect(ShowcaseTypography.bodyBase.fontSize, 16);
      expect(ShowcaseTypography.bodyBase.height, 1.5);
      expect(ShowcaseTypography.timestamp.fontSize, greaterThanOrEqualTo(12));

      expect(
        ShowcaseMotion.enterDuration.inMilliseconds,
        inInclusiveRange(150, 300),
      );
      expect(
        ShowcaseMotion.exitDuration.inMilliseconds,
        inInclusiveRange(150, 300),
      );
      expect(
        ShowcaseMotion.exitDuration,
        lessThan(ShowcaseMotion.enterDuration),
      );
    });

    testWidgets('effectiveDuration honors MediaQuery.disableAnimationsOf', (
      tester,
    ) async {
      late Duration normalDuration;
      late Duration reducedDuration;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              normalDuration = ShowcaseMotion.effectiveDuration(
                context,
                ShowcaseMotion.enterDuration,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(normalDuration, ShowcaseMotion.enterDuration);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reducedDuration = ShowcaseMotion.effectiveDuration(
                context,
                ShowcaseMotion.enterDuration,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(reducedDuration, Duration.zero);
    });

    testWidgets(
      'ThemeData exposes surfaceContainer ladder, pill buttons, and monogramPalette',
      (tester) async {
        await tester.pumpWidget(const ShowcaseApp());
        final context = tester.element(find.byType(ShowcaseShell));
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        expect(
          scheme.surfaceContainerLowest,
          ShowcaseTokens.lightSurfaceContainerLowest,
        );
        expect(
          scheme.surfaceContainerLow,
          ShowcaseTokens.lightSurfaceContainerLow,
        );
        expect(
          scheme.surfaceContainer,
          ShowcaseTokens.lightSurfaceContainer,
        );
        expect(
          scheme.surfaceContainerHigh,
          ShowcaseTokens.lightSurfaceContainerHigh,
        );
        expect(
          scheme.surfaceContainerHighest,
          ShowcaseTokens.lightSurfaceContainerHighest,
        );

        final filledStyle = theme.filledButtonTheme.style;
        expect(
          filledStyle?.minimumSize?.resolve(<WidgetState>{}),
          ShowcaseTokens.minTouchTargetSize,
        );
        expect(
          filledStyle?.shape?.resolve(<WidgetState>{}),
          isA<StadiumBorder>(),
        );

        final outlinedStyle = theme.outlinedButtonTheme.style;
        expect(
          outlinedStyle?.minimumSize?.resolve(<WidgetState>{}),
          ShowcaseTokens.minTouchTargetSize,
        );
        expect(
          outlinedStyle?.shape?.resolve(<WidgetState>{}),
          isA<StadiumBorder>(),
        );

        final iconStyle = theme.iconButtonTheme.style;
        expect(
          iconStyle?.minimumSize?.resolve(<WidgetState>{}),
          ShowcaseTokens.minTouchTargetSize,
        );

        // monogramPalette & ringed status indicator wired across style builders
        final convStyle = ShowcaseTheme.conversationsStyle(context);
        expect(
          convStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );
        expect(convStyle.statusIndicatorStyle?.border, isNotNull);

        final headerStyle = ShowcaseTheme.messageHeaderStyle(context);
        expect(
          headerStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );
        expect(headerStyle.statusIndicatorStyle?.border, isNotNull);

        final listStyle = ShowcaseTheme.messageListStyle(context);
        expect(
          listStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );

        final usersStyle = ShowcaseTheme.usersStyle(context);
        expect(
          usersStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );
        expect(usersStyle.statusIndicatorStyle?.border, isNotNull);

        final groupsStyle = ShowcaseTheme.groupsStyle(context);
        expect(
          groupsStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );

        final membersStyle = ShowcaseTheme.groupMembersStyle(context);
        expect(
          membersStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );

        final searchStyle = ShowcaseTheme.searchStyle(context);
        expect(
          searchStyle.avatarStyle?.monogramPalette,
          equals(ShowcaseTokens.avatarMonogramPalette),
        );
      },
    );
  });
}
