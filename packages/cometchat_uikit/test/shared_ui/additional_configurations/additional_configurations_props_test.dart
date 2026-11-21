/// Prop verification for [AdditionalConfigurations] without legacy BLoCs.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdditionalConfigurations', () {
    test('stores bubble styles, formatters, and option flags', () {
      const textStyle = CometChatTextBubbleStyle(
        backgroundColor: Color(0xFF130303),
      );
      final config = AdditionalConfigurations(
        textBubbleStyle: textStyle,
        textFormatters: const [],
        hideCopyMessageOption: true,
        hideDeleteMessageOption: true,
      );

      expect(config.textBubbleStyle?.backgroundColor, const Color(0xFF130303));
      expect(config.textFormatters, isEmpty);
      expect(config.hideCopyMessageOption, isTrue);
      expect(config.hideDeleteMessageOption, isTrue);
    });

    test('MessageTemplateUtils.getTextMessageOptions respects hide flags', () {
      final all = MessageTemplateUtils.getTextMessageOptions();
      expect(all.map((o) => o.id), contains(MessageOptionConstants.copyMessage));
      expect(all.map((o) => o.id), contains(MessageOptionConstants.deleteMessage));

      final filtered = MessageTemplateUtils.getTextMessageOptions(
        hideCopyMessageOption: true,
        hideDeleteMessageOption: true,
      );
      expect(filtered.map((o) => o.id), isNot(contains(MessageOptionConstants.copyMessage)));
      expect(filtered.map((o) => o.id), isNot(contains(MessageOptionConstants.deleteMessage)));
    });
  });
}
