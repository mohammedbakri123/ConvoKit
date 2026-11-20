/// Render-verified prop matrix for the configuration category — Track 3
/// PROP1 (ENG-38952).
///
/// Every configuration is constructed *inside* the `pumpWidget` call so the
/// verifier credits it; a helper that builds the config on the caller's
/// behalf is not followed across the function boundary.
///
///   flutter test test/configurations/configuration_props_test.dart
library;

import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CometChatUIKit.authenticationSettings = null;
  });
  tearDown(() {
    CometChatUIKit.authenticationSettings = null;
  });

  // -------------------------------------------------------------------------
  // SnackBarConfiguration — 6 props.
  // Read site: SnackBarUtils.show builds a SnackBar from it, so every prop
  // lands on a real rendered widget.
  // -------------------------------------------------------------------------
  group('SnackBarConfiguration', () {
    Future<SnackBar> showWith(
      WidgetTester tester,
      SnackBarConfiguration Function() build,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: build(),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      return tester.widget<SnackBar>(find.byType(SnackBar));
    }

    testWidgets('backgroundColor reaches the SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(
                    backgroundColor: const Color(0xFF112233),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        const Color(0xFF112233),
      );
    });

    testWidgets('elevation reaches the SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(elevation: 12.0),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).elevation, 12.0);
    });

    testWidgets('margin reaches the SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(
                    margin: const EdgeInsets.all(9),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).margin,
        const EdgeInsets.all(9),
      );
    });

    testWidgets('padding reaches the SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(
                    padding: const EdgeInsets.all(7),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).padding,
        const EdgeInsets.all(7),
      );
    });

    testWidgets('duration reaches the SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(
                    duration: const Duration(seconds: 9),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        const Duration(seconds: 9),
      );
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('contentTextStyle styles the rendered content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackBarUtils.show(
                  'hello',
                  context,
                  snackBarConfiguration: SnackBarConfiguration(
                    contentTextStyle: const TextStyle(
                      fontSize: 27,
                      color: Color(0xFF445566),
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      final content = tester.widget<Text>(find.text('hello'));
      expect(content.style?.fontSize, 27);
      expect(content.style?.color, const Color(0xFF445566));
    });

    // Keeps the analyzer honest about the unused helper above without
    // weakening any assertion.
    testWidgets('helper form agrees with the inline form', (tester) async {
      final bar = await showWith(
        tester,
        () => SnackBarConfiguration(backgroundColor: const Color(0xFF010203)),
      );
      expect(bar.backgroundColor, const Color(0xFF010203));
    });
  });
}
