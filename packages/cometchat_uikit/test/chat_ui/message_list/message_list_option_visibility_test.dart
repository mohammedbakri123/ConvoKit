/// Message option visibility tests using Core models.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageTemplateUtils.getTextMessageOptions respects all hide flags', () {
    final all = MessageTemplateUtils.getTextMessageOptions();
    expect(all.length, 4);

    final none = MessageTemplateUtils.getTextMessageOptions(
      hideCopyMessageOption: true,
      hideDeleteMessageOption: true,
      hideReplyOption: true,
      hideMessageInfoOption: true,
    );
    expect(none, isEmpty);
  });
}
