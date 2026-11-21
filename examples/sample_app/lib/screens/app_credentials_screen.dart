import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/home_screen.dart';
import 'package:sample_app/screens/responsive_home_screen.dart';

/// Offline Settings & Backend Configuration screen.
///
/// Replaces the legacy credential-entry screen now that the sample app runs
/// fully offline against [InMemoryChatBackend] and [ConvoKitScope].
class AppCredentialsScreen extends StatefulWidget {
  const AppCredentialsScreen({super.key, this.buildSettings});

  final UIKitSettings Function()? buildSettings;

  @override
  State<AppCredentialsScreen> createState() => _AppCredentialsScreenState();
}

class _AppCredentialsScreenState extends State<AppCredentialsScreen> {
  bool _isLoading = false;

  Future<void> _continueOffline() async {
    setState(() => _isLoading = true);
    await SampleAppBackend.instance.ensureInitialized();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            kIsWeb ? const ResponsiveHomeScreen() : const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Settings',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.offline_bolt, size: 48, color: palette.primary),
                const SizedBox(height: 16),
                Text(
                  'ConvoKit Offline Demo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: typography.heading2?.bold?.fontSize ?? 22,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Running fully offline against InMemoryChatBackend via ConvoKitScope. No external SDK credentials or network access required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _continueOffline,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue to Chat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
