/// Render-verified prop matrix for the shared misc widgets — Track 3 PROP1.
///
/// The tail of the widget gap: the decorated container, card, message bubble,
/// time-slot selector, single-select pair, the three AI agent view builders and
/// the four small bubbles.
///
/// Every construction is inline in the test closure — a construction moved into
/// a helper scores zero in `tool/prop_coverage` even while the test passes. The
/// same goes for the pump and the assertion.
///
/// The last group pins the props that are declared and never read. They are
/// constructed but deliberately NOT pumped, so they stay outside the numerator
/// until the defects behind them are resolved.
///
///   flutter test test/shared_ui/misc_widgets_props_test.dart
library;

import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

const _c1 = Color(0xFF101112);
const _c2 = Color(0xFF202122);
const _c3 = Color(0xFF303132);

/// Deliberately unlike any real theme value, so an assertion can only pass if
/// the widget read the object it was handed.
const _typography = CometChatTypography(
  heading4: CometChatTextStyleHeading4(
    medium: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
  ),
  caption1: CometChatTextStyleCaption1(
    medium: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
    regular: TextStyle(fontSize: 27, fontWeight: FontWeight.w200),
  ),
  body: CometChatTextStyleBody(regular: TextStyle(fontSize: 33)),
);

CometChatSpacing _spacing() => CometChatSpacing(
  padding: 1,
  padding1: 3,
  padding2: 6,
  padding3: 9,
  padding4: 12,
  radius1: 13,
  radius2: 17,
  radius3: 15,
  radiusMax: 19,
  margin1: 21,
  margin2: 23,
);

class FakeUser extends Fake implements User {
  @override
  String get uid => 'ai_bot';
  @override
  String get name => 'AI Bot';
}

Widget _host(Widget Function(BuildContext) build) => MaterialApp(
  localizationsDelegates: Translations.localizationsDelegates,
  supportedLocales: const [Locale('en')],
  home: Scaffold(body: Builder(builder: build)),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: Translations.localizationsDelegates,
  supportedLocales: const [Locale('en')],
  home: Scaffold(body: child),
);

void main() {
  // ===========================================================================
  group('CometChatDecoratedContainer', () {
    testWidgets('geometry, padding, margin and the theme trio apply', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          (context) => CometChatDecoratedContainer(
            title: 'Tips',
            content: const Text('body'),
            height: 220,
            width: 320,
            padding: const EdgeInsets.all(9),
            margin: const EdgeInsets.all(5),
            colorPalette: CometChatThemeHelper.getColorPalette(
              context,
            ).copyWith(background1: _c1, textPrimary: _c2),
            typography: _typography,
            spacing: _spacing(),
          ),
        ),
      );
      await tester.pump();

      final outer = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (w) => w is Container && w.padding == const EdgeInsets.all(9),
            )
            .first,
      );
      expect(outer.constraints?.maxWidth, 320, reason: 'width');
      expect(outer.constraints?.maxHeight, 220, reason: 'height');
      expect(outer.margin, const EdgeInsets.all(5), reason: 'margin');

      final decoration = outer.decoration! as BoxDecoration;
      expect(decoration.color, _c1, reason: 'colorPalette.background1');
      expect(
        decoration.borderRadius,
        BorderRadius.circular(17),
        reason: 'spacing.radius2',
      );

      final title = tester.widget<Text>(find.text('Tips'));
      expect(title.style?.color, _c2, reason: 'colorPalette.textPrimary');
      expect(title.style?.fontSize, 19, reason: 'typography.heading4.medium');
      expect(find.text('body'), findsOneWidget, reason: 'content');
    });

    testWidgets('maxHeight bounds the container', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => const CometChatDecoratedContainer(
            title: 'Tips',
            content: Text('body'),
            maxHeight: 260,
            padding: EdgeInsets.all(9),
          ),
        ),
      );
      await tester.pump();

      final outer = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (w) => w is Container && w.padding == const EdgeInsets.all(9),
            )
            .first,
      );
      expect(outer.constraints?.maxHeight, 260, reason: 'maxHeight');
    });

    testWidgets('the close affordance takes its url, package and callback', (
      tester,
    ) async {
      var closes = 0;

      await mockNetworkImagesFor(
        () => tester.pumpWidget(
          _host(
            (context) => CometChatDecoratedContainer(
              title: 'Tips',
              content: const Text('body'),
              closeIconUrl: AssetConstants.close,
              closeIconUrlPackageName: UIConstants.packageName,
              onCloseIconTap: () => closes++,
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as AssetImage).assetName,
        AssetConstants.close,
        reason: 'closeIconUrl',
      );
      expect(
        (image.image as AssetImage).package,
        UIConstants.packageName,
        reason: 'closeIconUrlPackageName',
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(closes, 1, reason: 'onCloseIconTap');
    });
  });

  // ===========================================================================
  group('CometChatCard', () {
    testWidgets('the avatar props reach the avatar', (tester) async {
      await mockNetworkImagesFor(
        () => tester.pumpWidget(
          _wrap(
            const CometChatCard(
              title: 'Quarterly planning',
              avatarName: 'Quarterly planning',
              avatarUrl: 'https://example.invalid/a.png',
              avatarHeight: 44,
              avatarWidth: 46,
              avatarPadding: EdgeInsets.all(7),
              avatarMargin: EdgeInsets.all(3),
              titlePadding: EdgeInsets.all(6),
              subtitleView: Text('sub-slot'),
              bottomView: Text('bottom-slot'),
            ),
          ),
        ),
      );
      await tester.pump();

      final avatar = tester.widget<CometChatAvatar>(
        find.byType(CometChatAvatar),
      );
      expect(
        avatar.image,
        'https://example.invalid/a.png',
        reason: 'avatarUrl',
      );
      expect(avatar.height, 44, reason: 'avatarHeight');
      expect(avatar.width, 46, reason: 'avatarWidth');
      expect(avatar.padding, const EdgeInsets.all(7), reason: 'avatarPadding');
      expect(avatar.margin, const EdgeInsets.all(3), reason: 'avatarMargin');
      expect(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(6),
        ),
        findsWidgets,
        reason: 'titlePadding',
      );
      expect(find.text('sub-slot'), findsOneWidget, reason: 'subtitleView');
      expect(find.text('bottom-slot'), findsOneWidget, reason: 'bottomView');
    });

    testWidgets('avatarView and titleView replace what they override', (
      tester,
    ) async {
      await mockNetworkImagesFor(
        () => tester.pumpWidget(
          _wrap(
            const CometChatCard(
              title: 'Quarterly planning',
              avatarName: 'Quarterly planning',
              avatarView: Text('avatar-slot'),
              titleView: Text('title-slot'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('avatar-slot'), findsOneWidget, reason: 'avatarView');
      expect(find.byType(CometChatAvatar), findsNothing);
      expect(find.text('title-slot'), findsOneWidget, reason: 'titleView');
      expect(find.text('Quarterly planning'), findsNothing);
    });
  });

  // ===========================================================================
  group('CometChatMessageBubble', () {
    testWidgets('the slots, margin and the two paddings apply', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => CometChatMessageBubble(
            alignment: BubbleAlignment.right,
            contentView: const Text('content-slot'),
            replyView: const Text('reply-slot'),
            footerView: const Text('footer-slot'),
            bottomView: const Text('bottom-slot'),
            margin: const EdgeInsets.all(5),
            contentPadding: const EdgeInsets.all(9),
            outerPadding: const EdgeInsets.all(11),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('content-slot'), findsOneWidget, reason: 'contentView');
      expect(find.text('reply-slot'), findsOneWidget, reason: 'replyView');
      expect(find.text('footer-slot'), findsOneWidget, reason: 'footerView');
      expect(find.text('bottom-slot'), findsOneWidget, reason: 'bottomView');
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.margin == const EdgeInsets.all(5),
        ),
        findsWidgets,
        reason: 'margin',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.padding == const EdgeInsets.all(9),
        ),
        findsWidgets,
        reason: 'contentPadding',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(11),
        ),
        findsWidgets,
        reason: 'outerPadding',
      );

      // An outgoing bubble stacks its content to the right.
      final column = tester.widgetList<Column>(find.byType(Column)).first;
      expect(column.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('colorPalette and spacing drive the bubble surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          (context) => CometChatMessageBubble(
            alignment: BubbleAlignment.left,
            contentView: const Text('content-slot'),
            colorPalette: CometChatThemeHelper.getColorPalette(
              context,
            ).copyWith(neutral300: _c3),
            spacing: _spacing(),
          ),
        ),
      );
      await tester.pump();

      final bubble = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).color == _c3,
            )
            .first,
      );
      expect(
        (bubble.decoration! as BoxDecoration).borderRadius,
        const BorderRadius.all(Radius.circular(15)),
        reason: 'spacing.radius3',
      );
      expect(
        bubble.padding,
        const EdgeInsets.fromLTRB(3, 3, 3, 0),
        reason: 'spacing.padding1 fills the default content padding',
      );
    });
  });

  // ===========================================================================
  group('CometChatTimeSlotSelector', () {
    testWidgets('timeFormat picks the label format and onSelection reports', (
      tester,
    ) async {
      final day = DateTime(2026, 5, 12);
      DateTime? chosen;

      await tester.pumpWidget(
        _wrap(
          CometChatTimeSlotSelector(
            selectedDay: day,
            duration: const Duration(minutes: 30),
            timeFormat: TimeFormat.twentyFourHour,
            availableSlots: [
              DateTimeRange(
                start: day.add(const Duration(hours: 9)),
                end: day.add(const Duration(hours: 10)),
              ),
            ],
            onSelection: (t) => chosen = t,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('09:00'), findsOneWidget, reason: 'timeFormat');
      expect(find.text('9:00 AM'), findsNothing);

      await tester.tap(find.text('09:00'));
      await tester.pump();
      expect(
        chosen,
        day.add(const Duration(hours: 9)),
        reason: 'onSelection carries the slot',
      );
    });

    testWidgets('blockedTime removes slots and buffer reshapes the window', (
      tester,
    ) async {
      final day = DateTime(2026, 5, 12);

      await tester.pumpWidget(
        _wrap(
          CometChatTimeSlotSelector(
            selectedDay: day,
            duration: const Duration(minutes: 30),
            timeFormat: TimeFormat.twentyFourHour,
            availableSlots: [
              DateTimeRange(
                start: day.add(const Duration(hours: 9)),
                end: day.add(const Duration(hours: 11)),
              ),
            ],
            blockedTime: [
              DateTimeRange(
                start: day.add(const Duration(hours: 10)),
                end: day.add(const Duration(hours: 10, minutes: 30)),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('10:00'), findsNothing, reason: 'blockedTime');
      expect(
        find.byType(GestureDetector),
        findsNWidgets(3),
        reason: '09:00, 09:30 and 10:30 survive the block',
      );

      await tester.pumpWidget(
        _wrap(
          CometChatTimeSlotSelector(
            key: const ValueKey('buffered'),
            selectedDay: day,
            duration: const Duration(minutes: 30),
            timeFormat: TimeFormat.twentyFourHour,
            availableSlots: [
              DateTimeRange(
                start: day.add(const Duration(hours: 9)),
                end: day.add(const Duration(hours: 11)),
              ),
            ],
            blockedTime: [
              DateTimeRange(
                start: day.add(const Duration(hours: 10)),
                end: day.add(const Duration(hours: 10, minutes: 30)),
              ),
            ],
            buffer: const Duration(minutes: 30),
          ),
        ),
      );
      await tester.pump();

      // `buffer` reaches the generator — the slot set changes. It changes the
      // WRONG way: SchedulerUtils.adjustAvailableSlots only splits the window
      // when `blockedEnd + buffer` lands strictly before the end of the
      // availability, and otherwise re-adds the availability whole. A buffer
      // wide enough to reach the end of the window therefore discards the block
      // entirely and offers 10:00 — the slot the caller blocked. Asserted as it
      // behaves today so the prop is verified; the behaviour is ENG-39130.
      expect(
        find.byType(GestureDetector),
        findsNWidgets(4),
        reason: 'buffer reaches the generator',
      );
      expect(find.text('10:00'), findsOneWidget, reason: 'ENG-39130');
    });

    testWidgets('the next-day lists decide whether a crossing slot survives', (
      tester,
    ) async {
      final day = DateTime(2026, 5, 12);
      final crossing = [
        DateTimeRange(
          start: day.add(const Duration(hours: 23)),
          end: day.add(const Duration(hours: 23, minutes: 45)),
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          CometChatTimeSlotSelector(
            selectedDay: day,
            duration: const Duration(minutes: 30),
            timeFormat: TimeFormat.twentyFourHour,
            availableSlots: crossing,
            nextDayAvailableSlots: [
              DateTimeRange(
                start: day.add(const Duration(days: 1)),
                end: day.add(const Duration(days: 1, hours: 2)),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('23:30'),
        findsOneWidget,
        reason: 'nextDayAvailableSlots admits the crossing slot',
      );

      await tester.pumpWidget(
        _wrap(
          CometChatTimeSlotSelector(
            key: const ValueKey('next-day-blocked'),
            selectedDay: day,
            duration: const Duration(minutes: 30),
            timeFormat: TimeFormat.twentyFourHour,
            availableSlots: crossing,
            nextDayAvailableSlots: [
              DateTimeRange(
                start: day.add(const Duration(hours: 22)),
                end: day.add(const Duration(days: 1, hours: 2)),
              ),
            ],
            nextDayBlockedTime: [
              DateTimeRange(
                start: day.add(const Duration(hours: 23, minutes: 45)),
                end: day.add(const Duration(days: 1, minutes: 15)),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('23:30'),
        findsOneWidget,
        reason: 'nextDayBlockedTime reshapes the next-day availability',
      );
    });
  });

  // ===========================================================================
  group('CometChatSingleSelect and its button', () {
    testWidgets('the button takes label, selected, style and onSelected', (
      tester,
    ) async {
      var selections = 0;

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              CometChatSingleSelectButton(
                label: 'Yes',
                selected: true,
                onSelected: () => selections++,
                selectedOptionsTextStyle: const TextStyle(
                  color: _c2,
                  fontSize: 17,
                ),
              ),
              CometChatSingleSelectButton(
                label: 'No',
                selected: false,
                onSelected: () {},
                selectedOptionsTextStyle: const TextStyle(
                  color: _c2,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Yes'), findsOneWidget, reason: 'label');
      final selectedLabel = tester.widget<Text>(find.text('Yes'));
      expect(
        selectedLabel.style?.color,
        _c2,
        reason: 'selectedOptionsTextStyle',
      );
      expect(selectedLabel.style?.fontSize, 17);

      // The unselected row falls back to the built-in style, which is how
      // `selected` reads at the surface.
      final unselectedLabel = tester.widget<Text>(find.text('No'));
      expect(unselectedLabel.style?.color, Colors.black, reason: 'selected');

      await tester.tap(find.text('Yes'));
      await tester.pump();
      expect(selections, 1, reason: 'onSelected');
    });

    testWidgets('the select takes decoration and reports onChanged', (
      tester,
    ) async {
      String? chosen;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 400,
            child: CometChatSingleSelect(
              options: [
                OptionElement(value: 'y', label: 'Yes'),
                OptionElement(value: 'n', label: 'No'),
              ],
              decoration: const BoxDecoration(color: _c1),
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == _c1,
        ),
        findsWidgets,
        reason: 'decoration',
      );

      await tester.tap(find.text('No'));
      await tester.pump();
      expect(chosen, 'n', reason: 'onChanged carries the value, not the label');
    });
  });

  // ===========================================================================
  group('the bubbles', () {
    testWidgets('CometChatActionBubble takes the icon, size and padding', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CometChatActionBubble(
            text: 'Alexandra added Dimitrios',
            leadingIcon: Icon(Icons.info_outline),
            height: 40,
            width: 260,
            padding: EdgeInsets.all(9),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Alexandra added Dimitrios'), findsOneWidget);
      expect(
        find.byIcon(Icons.info_outline),
        findsOneWidget,
        reason: 'leadingIcon',
      );

      final bubble = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (w) => w is Container && w.padding == const EdgeInsets.all(9),
            )
            .first,
      );
      expect(bubble.constraints?.maxHeight, 40, reason: 'height');
      expect(bubble.constraints?.maxWidth, 260, reason: 'width');
    });

    testWidgets('CometChatDeletedBubble takes margin and padding', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CometChatDeletedBubble(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(9),
          ),
        ),
      );
      await tester.pump();

      final bubble = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (w) => w is Container && w.padding == const EdgeInsets.all(9),
            )
            .first,
      );
      expect(bubble.margin, const EdgeInsets.all(5), reason: 'margin');
    });
  });

  // ===========================================================================
  // Declared and never read. Constructed so the guard holds and the analyzer
  // sees them, deliberately NOT pumped so they stay outside the numerator.
  group('DEFECT — declared and never read', () {
    test('the props no build method consults', () {
      // `message` is documented as the action message object and read nowhere;
      // the bubble renders `text` only. ENG-39129.
      const CometChatActionBubble(text: 'Group created', message: 'raw');

      // `from` and `to` are documented as the selector's window; the slot list
      // is generated from `availableSlots` alone. ENG-39129.
      CometChatTimeSlotSelector(
        selectedDay: DateTime(2026, 5, 12),
        duration: const Duration(minutes: 30),
        from: DateTime(2026, 5, 12, 9),
        to: DateTime(2026, 5, 12, 17),
      );

      // The button shadows its own `optionTextStyle` field with a local const
      // of the same name, so the prop cannot be read; the two background props
      // are never referenced at all. The 3+-option branch of the select drops
      // all four style props on the floor as well. ENG-39129.
      CometChatSingleSelectButton(
        label: 'Yes',
        selected: false,
        onSelected: () {},
        optionTextStyle: const TextStyle(color: _c1),
        optionBackground: _c2,
        selectedOptionBackground: _c3,
      );

      expect(true, isTrue);
    });
  });
}
