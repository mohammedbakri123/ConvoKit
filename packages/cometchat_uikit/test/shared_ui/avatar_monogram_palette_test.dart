import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const studioPalette = <Color>[
    Color(0xFF1B5E43),
    Color(0xFF166169),
    Color(0xFF394B7A),
    Color(0xFF9A3E2A),
    Color(0xFF7D5311),
    Color(0xFF6B3B6E),
    Color(0xFF24577A),
    Color(0xFF4B6127),
  ];

  Widget host(
    Widget child, {
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: Scaffold(body: Center(child: child)),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester, Finder avatarFinder) {
    final container = tester.widget<Container>(
      find.descendant(of: avatarFinder, matching: find.byType(Container)).first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('ConvoKitAvatar L1 monogramPalette, gradient, shadow & asset:', () {
    testWidgets('preserves default background behavior when unset', (
      tester,
    ) async {
      const explicitBg = Color(0xFF123456);
      await tester.pumpWidget(
        host(
          const ConvoKitAvatar(
            name: 'Nadia Haddad',
            width: 48,
            height: 48,
            style: ConvoKitAvatarStyle(backgroundColor: explicitBg),
          ),
        ),
      );

      final decoration = decorationOf(tester, find.byType(ConvoKitAvatar));
      expect(decoration.color, explicitBg);
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      expect(find.text('NH'), findsOneWidget);
    });

    testWidgets(
      'selects deterministic monogramPalette color from name when no image',
      (tester) async {
        await tester.pumpWidget(
          host(
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConvoKitAvatar(
                  key: Key('a1'),
                  name: 'Tariq Mansour',
                  width: 44,
                  height: 44,
                  style: ConvoKitAvatarStyle(monogramPalette: studioPalette),
                ),
                ConvoKitAvatar(
                  key: Key('a2'),
                  name: '  tariq mansour  ',
                  width: 44,
                  height: 44,
                  style: ConvoKitAvatarStyle(monogramPalette: studioPalette),
                ),
                ConvoKitAvatar(
                  key: Key('b1'),
                  name: 'Claire Laurent',
                  width: 44,
                  height: 44,
                  style: ConvoKitAvatarStyle(monogramPalette: studioPalette),
                ),
                ConvoKitAvatar(
                  key: Key('c1'),
                  name: 'Design Systems',
                  width: 44,
                  height: 44,
                  style: ConvoKitAvatarStyle(monogramPalette: studioPalette),
                ),
              ],
            ),
          ),
        );

        final colorA1 = decorationOf(tester, find.byKey(const Key('a1'))).color;
        final colorA2 = decorationOf(tester, find.byKey(const Key('a2'))).color;
        final colorB1 = decorationOf(tester, find.byKey(const Key('b1'))).color;
        final colorC1 = decorationOf(tester, find.byKey(const Key('c1'))).color;

        expect(colorA1, isNotNull);
        expect(studioPalette, contains(colorA1));
        expect(studioPalette, contains(colorB1));
        expect(studioPalette, contains(colorC1));
        expect(colorA1, equals(colorA2));
        expect(<Color?>{colorA1, colorB1, colorC1}.length, greaterThan(1));
      },
    );

    testWidgets('applies backgroundGradient and boxShadow from style', (
      tester,
    ) async {
      const gradient = LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF0F7A5A)],
      );
      const shadows = <BoxShadow>[
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ];

      await tester.pumpWidget(
        host(
          const ConvoKitAvatar(
            name: 'Brand Refresh',
            width: 48,
            height: 48,
            style: ConvoKitAvatarStyle(
              backgroundGradient: gradient,
              boxShadow: shadows,
            ),
          ),
        ),
      );

      final decoration = decorationOf(tester, find.byType(ConvoKitAvatar));
      expect(decoration.gradient, equals(gradient));
      expect(decoration.boxShadow, equals(shadows));
      expect(decoration.color, isNull);
    });

    testWidgets('renders Image.asset when image starts with asset:', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ConvoKitAvatar(
            name: 'Nadia Haddad',
            image: 'asset:assets/avatars/nadia.png',
            width: 48,
            height: 48,
          ),
        ),
      );

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/avatars/nadia.png');
    });

    test('ConvoKitAvatarStyle copyWith, merge, and lerp handle L1 fields', () {
      const gradientA = LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF222222)],
      );
      const gradientB = LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFDDDDDD)],
      );
      const shadowA = <BoxShadow>[
        BoxShadow(color: Color(0x11000000), blurRadius: 4),
      ];
      const shadowB = <BoxShadow>[
        BoxShadow(color: Color(0x33000000), blurRadius: 12),
      ];

      const base = ConvoKitAvatarStyle(
        monogramPalette: <Color>[Color(0xFF1B5E43), Color(0xFF166169)],
        backgroundGradient: gradientA,
        boxShadow: shadowA,
      );
      const override = ConvoKitAvatarStyle(
        monogramPalette: <Color>[Color(0xFF394B7A), Color(0xFF9A3E2A)],
        backgroundGradient: gradientB,
        boxShadow: shadowB,
      );

      final copied = base.copyWith(boxShadow: shadowB);
      expect(copied.monogramPalette, equals(base.monogramPalette));
      expect(copied.backgroundGradient, equals(gradientA));
      expect(copied.boxShadow, equals(shadowB));

      final merged = base.merge(override);
      expect(merged.monogramPalette, equals(override.monogramPalette));
      expect(merged.backgroundGradient, equals(gradientB));
      expect(merged.boxShadow, equals(shadowB));

      final lerped = base.lerp(override, 0.5);
      expect(lerped.monogramPalette, isNotNull);
      expect(lerped.monogramPalette!.length, 2);
      expect(lerped.backgroundGradient, isNotNull);
      expect(lerped.boxShadow, isNotNull);
      expect(lerped.boxShadow!.first.blurRadius, closeTo(8.0, 0.01));
    });
  });
}
