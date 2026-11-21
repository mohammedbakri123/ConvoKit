import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/models/user_model.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/app_credentials_screen.dart';
import 'package:sample_app/screens/home_screen.dart';
import 'package:sample_app/screens/responsive_home_screen.dart';
import 'package:sample_app/services/api_services.dart';

/// Offline login screen allowing users to pick a superhero demo persona or
/// enter any custom UID against [InMemoryChatBackend].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _uidController = TextEditingController();
  List<SampleUserModel> _sampleUsers = [];
  int? _selectedIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSampleUsers();
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _loadSampleUsers() async {
    final users = await ApiServices.getDefaultUsers();
    if (!mounted) return;
    setState(() {
      _sampleUsers = users;
      if (_sampleUsers.isNotEmpty) {
        _selectedIndex = 0;
      }
    });
  }

  Future<void> _login(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user or enter a UID')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SampleAppBackend.instance.loginAs(trimmed);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              kIsWeb ? const ResponsiveHomeScreen() : const HomeScreen(),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings_outlined, color: palette.iconPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppCredentialsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in to ConvoKit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose an offline demo user or enter a custom UID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_sampleUsers.length, (index) {
                      final user = _sampleUsers[index];
                      final selected = _selectedIndex == index;
                      return ChoiceChip(
                        label: Text(user.username),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedIndex = index;
                            _uidController.clear();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _uidController,
                    onChanged: (_) {
                      if (_selectedIndex != null) {
                        setState(() => _selectedIndex = null);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Or enter custom UID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final uid = _uidController.text.trim().isNotEmpty
                                ? _uidController.text.trim()
                                : (_selectedIndex != null &&
                                          _selectedIndex! < _sampleUsers.length
                                      ? _sampleUsers[_selectedIndex!].userId
                                      : 'superhero1');
                            _login(uid);
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
