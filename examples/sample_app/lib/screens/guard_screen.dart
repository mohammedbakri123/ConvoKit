import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'responsive_home_screen.dart';

/// Guard screen — checks for an active offline ConvoKit session and routes
/// to [HomeScreen]/[ResponsiveHomeScreen] or [LoginScreen].
class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  final ValueNotifier<bool?> _shouldGoHome = ValueNotifier<bool?>(null);
  late ConvoKitColorPalette _colorPalette;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    if (_initialized) return;
    _initialized = true;
    _checkSession();
  }

  Future<void> _checkSession() async {
    await SampleAppBackend.instance.ensureInitialized();
    final ChatUser? user =
        SampleAppBackend.instance.kit.session.currentUser ??
        await ConvoKitUIKit.getLoggedInUser();
    _shouldGoHome.value = user != null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: _shouldGoHome,
      builder: (context, value, _) {
        if (value == null) {
          return Material(
            color: _colorPalette.background1,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ConvoKit',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _colorPalette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: _colorPalette.primary),
                ],
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final Widget home = kIsWeb
              ? const ResponsiveHomeScreen()
              : const HomeScreen();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => value ? home : const LoginScreen(),
            ),
            (route) => false,
          );
        });
        return const SizedBox();
      },
    );
  }
}
