import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/home_screen.dart';
import 'package:sample_app/screens/login_screen.dart';
import 'package:sample_app/screens/responsive_home_screen.dart';

/// Entry point for the offline ConvoKit sample app.
///
/// Boots directly against [InMemoryChatBackend] wrapped in [ConvoKitScope]
/// with zero CometChat SDK dependencies and zero credential prompts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SampleAppBackend.instance.ensureInitialized();
  runApp(const BlocSampleApp());
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class BlocSampleApp extends StatefulWidget {
  const BlocSampleApp({super.key});

  @override
  State<BlocSampleApp> createState() => _BlocSampleAppState();
}

class _BlocSampleAppState extends State<BlocSampleApp> {
  StreamSubscription<ChatUser?>? _sessionSub;
  ChatUser? _currentUser;

  @override
  void initState() {
    super.initState();
    final backend = SampleAppBackend.instance;
    _currentUser = backend.kit.session.currentUser;
    _sessionSub = backend.kit.session.currentUserStream.listen((user) {
      if (mounted) {
        setState(() => _currentUser = user);
      }
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = SampleAppBackend.instance.kit;
    return ConvoKitScope(
      kit: kit,
      signedOutBuilder: (_) => _buildMaterialApp(const LoginScreen()),
      child: _buildMaterialApp(
        _currentUser == null
            ? const LoginScreen()
            : (kIsWeb ? const ResponsiveHomeScreen() : const HomeScreen()),
      ),
    );
  }

  Widget _buildMaterialApp(Widget home) {
    return MaterialApp(
      title: 'ConvoKit Sample App',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      localizationsDelegates: Translations.localizationsDelegates,
      supportedLocales: Translations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
