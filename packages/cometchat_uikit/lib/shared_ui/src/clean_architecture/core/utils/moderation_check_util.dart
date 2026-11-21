import 'package:convokit/src/core/models/models.dart';

class ModerationCheckUtil {
  ModerationCheckUtil._();

  static final ModerationCheckUtil instance = ModerationCheckUtil._();

  bool hideModerationStatus = false;

  bool isMessageDisapprovedFromModeration(ChatMessage message) {
    if (hideModerationStatus) return false;
    return switch (message) {
      CustomMessage c => c.data['moderationStatus'] == 'disapproved',
      TextMessage _ => false,
      MediaMessage _ => false,
    };
  }
}
