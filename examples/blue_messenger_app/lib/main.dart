import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'data/blue_in_memory_backend.dart';
import 'screens/blue_home_screen.dart';
import 'theme/blue_messenger_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlueMessengerApp());
}

/// Root widget for the offline Blue Messenger ConvoKit example app.
class BlueMessengerApp extends StatefulWidget {
  const BlueMessengerApp({super.key, this.kit, this.backend});

  /// Optional pre-built [ConvoKit] instance (useful for tests).
  final ConvoKit? kit;

  /// Optional [BlueInMemoryBackend] instance (useful for tests).
  final BlueInMemoryBackend? backend;

  @override
  State<BlueMessengerApp> createState() => _BlueMessengerAppState();
}

class _BlueMessengerAppState extends State<BlueMessengerApp> {
  late final BlueInMemoryBackend _backend;
  late final ConvoKit _kit;

  @override
  void initState() {
    super.initState();
    _backend = widget.backend ?? BlueInMemoryBackend();
    _kit = widget.kit ?? _backend.createConvoKit();
  }

  @override
  Widget build(BuildContext context) {
    return ConvoKitScope(
      kit: _kit,
      child: MaterialApp(
        title: 'Blue Messenger (ConvoKit)',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: ConvoKitLocalize.localizationsDelegates,
        supportedLocales: ConvoKitLocalize.supportedLocales,
        theme: buildBlueMessengerTheme(),
        home: BlueHomeScreen(backend: _backend),
      ),
    );
  }
}
