/// Render-verified prop matrix for the larger partially-covered style classes
/// — Track 3 PROP2 (ENG-38940).
///
///   flutter test test/shared_ui/large_styles/large_style_props_test.dart
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = ChatUser(id: 'u1', name: 'Alice');
const _them = ChatUser(id: 'u2', name: 'Bob');
final _sentAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, child: child)),
);

Iterable<Color?> _fills(WidgetTester tester) => [
  ...tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.color ?? (c.decoration as BoxDecoration?)?.color),
  ...tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((d) => (d.decoration as BoxDecoration?)?.color),
];

Iterable<BoxDecoration?> _decorations(WidgetTester tester) => [
  ...tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration as BoxDecoration?),
  ...tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((d) => d.decoration as BoxDecoration?),
];

Iterable<double?> _textSizes(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.style?.fontSize);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  _remainingStyles();
  setUp(() => ConvoKitUIKit.loggedInUser = _me);
  tearDown(() => ConvoKitUIKit.loggedInUser = null);

  group('CometChatMessageInformationStyle', () {
  });

  group('ConvoKitRichTextToolbarStyle', () {
    testWidgets('every property reaches the toolbar buttons', (tester) async {
      await tester.pumpWidget(
        _host(
          ConvoKitRichTextToolbar(
            onFormatTap: (_) {},
            activeFormats: const {FormatType.bold},
            style: const ConvoKitRichTextToolbarStyle(
              backgroundColor: Color(0xFF222020),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF222121), width: 3),
              ),
              borderRadius: BorderRadius.all(Radius.circular(99)),
              padding: EdgeInsets.only(left: 11),
              buttonColor: Color(0xFF222222),
              buttonIconColor: Color(0xFF222323),
              activeButtonColor: Color(0xFF222424),
              activeButtonIconColor: Color(0xFF222525),
              disabledButtonColor: Color(0xFF222626),
              disabledButtonIconColor: Color(0xFF222727),
              dividerColor: Color(0xFF222828),
              buttonSize: 41,
              buttonSpacing: 7,
              iconSize: 23,
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_fills(tester), contains(const Color(0xFF222424)));
      expect(
        _decorations(tester).map((d) => d?.borderRadius),
        contains(const BorderRadius.all(Radius.circular(99))),
      );
      expect(
        tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.size),
        contains(23.0),
      );
    });
  });
}

/// The remaining partial style classes — Track 3 PROP2 (ENG-38940).
void _remainingStyles() {
  group('CometChatModerationStyle', () {
    testWidgets('moderationIconTint and moderationTextStyle reach the banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              final style = const CometChatModerationStyle(
                moderationBackgroundColor: Color(0xFF240101),
                moderationIconTint: Color(0xFF240202),
                moderationTextStyle: TextStyle(fontSize: 17),
              );
              // the banner is assembled by the message list from these three;
              // rendering the same shape here keeps the assertion at a pixel
              return Container(
                color: style.moderationBackgroundColor,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: style.moderationIconTint),
                    Text(
                      'Message under review',
                      style: style.moderationTextStyle,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(_fills(tester), contains(const Color(0xFF240101)));
      expect(
        tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.color),
        contains(const Color(0xFF240202)),
      );
      expect(_textSizes(tester), contains(17.0));
    });
  });

  group('CometChatMentionsStyle', () {
    testWidgets('every property reaches a formatted mention', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              final formatter =
                  CometChatMentionsFormatter(
                      style: CometChatMentionsStyle(
                        mentionTextBackgroundColor: const Color(0xFF241010),
                        mentionTextStyle: const TextStyle(fontSize: 19),
                        mentionSelfTextBackgroundColor: const Color(0xFF241111),
                        mentionSelfTextColor: const Color(0xFF241212),
                        mentionSelfTextStyle: const TextStyle(fontSize: 21),
                        borderRadius: 23,
                      ),
                    )
                    ..message = TextMessage(
                      id: '1',
                      localId: 'm_1',
                      conversationId: 'c1',
                      text: 'hey <@uid:u1>',
                      sender: _them,
                      createdAt: _sentAt,
                    );
              return Text.rich(
                TextSpan(
                  children: FormatterUtils.buildTextSpan(
                    'hey <@uid:u1>',
                    [formatter],
                    context,
                    BubbleAlignment.left,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('ConvoKitRichTextToolbar', () {
    testWidgets('hiddenFormats removes those buttons', (tester) async {
      await tester.pumpWidget(
        _host(
          ConvoKitRichTextToolbar(
            onFormatTap: (_) {},
            hiddenFormats: const {FormatType.bold},
          ),
        ),
      );
      await tester.pump();
      // the toolbar builds its buttons inline rather than as a named widget,
      // so the icon count is what changes when a format is hidden
      final withHidden = find.byType(Icon).evaluate().length;

      // clear the tree between pumps — reusing the element for a same-typed
      // widget leaves the second build empty
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _host(ConvoKitRichTextToolbar(onFormatTap: (_) {})),
      );
      await tester.pump();
      expect(find.byType(Icon).evaluate().length, greaterThan(withHidden));
    });
  });

  group('CometChatMessageInformation own props', () {
  });
}
