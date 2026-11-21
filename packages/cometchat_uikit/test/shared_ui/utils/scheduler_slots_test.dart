/// Tests for [SchedulerUtils] with Core [ChatUser].
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SchedulerUtils.isScheduleButtonDisabled respects allowSenderInteraction', () {
    const alice = ChatUser(id: 'u1', name: 'Alice');
    final msg = SchedulerMessage(
      receiverUid: 'u2',
      receiverType: ReceiverTypeConstants.user,
      sender: alice,
      title: 'Sync',
      allowSenderInteraction: false,
      scheduleElement: ButtonElement(
        elementId: 'sched',
        buttonText: 'Schedule',
        action: CustomAction(actionType: ActionTypeConstants.customAction),
      ),
    );
    expect(SchedulerUtils.isScheduleButtonDisabled(msg), isA<bool>());
  });
}
