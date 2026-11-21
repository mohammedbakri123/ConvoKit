/// Property tests for [ConvoKitDate] formatting.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('ConvoKitDate renders non-empty labels for all patterns', (
    tester,
  ) async {
    final now = DateTime.now();
    for (final pattern in DateTimePattern.values) {
      await pumpInApp(tester, ConvoKitDate(date: now, pattern: pattern));
      final text = tester.widget<Text>(find.byType(Text)).data;
      expect(text, isNotNull);
      expect(text!.trim(), isNotEmpty);
    }
  });
}
