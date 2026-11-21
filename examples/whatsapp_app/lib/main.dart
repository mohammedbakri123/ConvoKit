import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'data/whatsapp_in_memory_backend.dart';
import 'screens/whatsapp_home_screen.dart';
import 'theme/whatsapp_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhatsAppApp());
}

/// Root widget for the offline WhatsApp-style ConvoKit example app.
class WhatsAppApp extends StatefulWidget {
  const WhatsAppApp({super.key, this.kit, this.backend});

  /// Optional pre-built [ConvoKit] instance (useful for tests).
  final ConvoKit? kit;

  /// Optional [WhatsAppInMemoryBackend] instance (useful for tests).
  final WhatsAppInMemoryBackend? backend;

  @override
  State<WhatsAppApp> createState() => _WhatsAppAppState();
}

class _WhatsAppAppState extends State<WhatsAppApp> {
  late final ConvoKit _kit;

  @override
  void initState() {
    super.initState();
    _kit =
        widget.kit ??
        (widget.backend ?? WhatsAppInMemoryBackend()).createConvoKit();
  }

  @override
  Widget build(BuildContext context) {
    return ConvoKitScope(
      kit: _kit,
      child: MaterialApp(
        title: 'WhatsApp (ConvoKit)',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: ConvoKitLocalize.localizationsDelegates,
        supportedLocales: ConvoKitLocalize.supportedLocales,
        theme: buildWhatsAppTheme(),
        home: const WhatsAppHomeScreen(),
      ),
    );
  }
}
