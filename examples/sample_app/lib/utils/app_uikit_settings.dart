import 'package:convokit/convokit_uikit.dart';

/// Offline [UIKitSettings] for the ConvoKit sample app.
UIKitSettings buildAppUIKitSettings() {
  final settingsBuilder = UIKitSettingsBuilder()
    ..subscriptionType = 'allUsers'
    ..region = 'offline'
    ..autoEstablishSocketConnection = true
    ..appId = 'convokit-offline-demo'
    ..authKey = 'offline';

  settingsBuilder.enableThreadSubscription = true;

  return settingsBuilder.build();
}
