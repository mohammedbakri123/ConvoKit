/// Property tests for poll custom message template handling.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageTemplateUtils.getPollMessageTemplate returns custom poll template', () {
    final template = MessageTemplateUtils.getPollMessageTemplate();
    expect(template.type, ExtensionType.extensionPoll);
    expect(template.category, MessageCategoryConstants.custom);
    expect(template.contentView, isNotNull);
  });
}
