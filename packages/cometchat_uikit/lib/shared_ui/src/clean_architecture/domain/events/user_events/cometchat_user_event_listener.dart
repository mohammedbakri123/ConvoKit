import 'package:convokit/src/core/models/models.dart';
import '../../../core/utils/ui_event_handler.dart';

///Events can be triggered by the user action for
///e.g. Clicking on a particular user item. All public-facing components in each module will trigger events.
mixin ConvoKitUserEventListener implements UIEventHandler {
  ///This will get triggered when the logged in user blocks another user
  void ccUserBlocked(ChatUser user) {}

  ///This will get triggered when the logged in user unblocks another user
  void ccUserUnblocked(ChatUser user) {}
}
