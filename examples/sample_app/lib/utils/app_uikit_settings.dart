import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:sample_app/app_credentials.dart';

/// The [UIKitSettings] for every `ConvoKitUIKit.init` in this app, built
/// from the current [AppCredentials].
///
/// main.dart inits the UI Kit at launch and AppCredentialsScreen inits it
/// again after new credentials are saved. Both use this (the screen gets it
/// as its `buildSettings`), so hosts and thread subscription are the same
/// whichever screen ran the init.
UIKitSettings buildAppUIKitSettings() {
  final settingsBuilder = UIKitSettingsBuilder()
    ..subscriptionType = CometChatSubscriptionType.allUsers
    ..region = AppCredentials.region
    ..autoEstablishSocketConnection = true
    ..appId = AppCredentials.appId
    ..authKey = AppCredentials.authKey
    ..adminHost = AppCredentials.adminHost
    ..clientHost = AppCredentials.clientHost;

  // Thread subscription (ENG-37601): the feature gate defaults to OFF in
  // the kit; the master app opts in so both follow/unfollow surfaces
  // (message action sheet + threaded header) are exercisable.
  settingsBuilder.enableThreadSubscription = true;

  return settingsBuilder.build();
}
