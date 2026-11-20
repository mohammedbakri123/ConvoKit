import "package:cometchat_sdk/cometchat_sdk.dart" hide CardMessage;
import 'cometchat_user_event_listener.dart';

class ConvoKitUserEvents {
  static Map<String, ConvoKitUserEventListener> usersListener = {};

  static void addUsersListener(
    String listenerId,
    ConvoKitUserEventListener listenerClass,
  ) {
    usersListener[listenerId] = listenerClass;
  }

  static void removeUsersListener(String listenerId) {
    usersListener.remove(listenerId);
  }

  static void ccUserBlocked(User user) {
    usersListener.forEach((key, value) {
      value.ccUserBlocked(user);
    });
  }

  static void ccUserUnblocked(User user) {
    usersListener.forEach((key, value) {
      value.ccUserUnblocked(user);
    });
  }
}
