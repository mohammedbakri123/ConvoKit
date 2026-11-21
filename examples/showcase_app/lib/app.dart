import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'backend/studio_backend.dart';
import 'screens/calls/calls_tab.dart';
import 'screens/chats/chats_tab.dart';
import 'screens/settings/settings_tab.dart';
import 'screens/updates/updates_tab.dart';
import 'theme/showcase_theme.dart';
import 'widgets/collapsing_glass_header.dart';
import 'widgets/floating_glass_tab_bar.dart';

/// Root widget for the ConvoKit Showcase application.
///
/// Wires [ConvoKitScope] at the application root with an offline
/// [StudioBackend], manages Light/Dark [ThemeMode] switching via a
/// [ValueNotifier], and injects [ShowcaseTheme.lightTheme] and
/// [ShowcaseTheme.darkTheme] (carrying [ConvoKitColorPalette],
/// [ConvoKitTypography], and [ConvoKitSpacing] extensions) into [MaterialApp].
class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({
    super.key,
    this.initialThemeMode = ThemeMode.light,
    this.backend,
  });

  /// Initial theme mode for the app; defaults to [ThemeMode.light].
  final ThemeMode initialThemeMode;

  /// Optional injected [StudioBackend] for tests or custom demo wiring.
  /// When omitted, [ShowcaseApp] creates and disposes its own instance.
  final StudioBackend? backend;

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  late final ValueNotifier<ThemeMode> _themeModeNotifier;
  late final StudioBackend _backend;
  late final bool _ownsBackend;

  @override
  void initState() {
    super.initState();
    _ownsBackend = widget.backend == null;
    _backend = widget.backend ?? StudioBackend.create();
    _themeModeNotifier = ValueNotifier<ThemeMode>(widget.initialThemeMode);
    ShowcaseTheme.syncThemeMode(widget.initialThemeMode);
  }

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    if (_ownsBackend) {
      unawaited(_backend.dispose());
    }
    super.dispose();
  }

  void _setThemeMode(ThemeMode mode) {
    ShowcaseTheme.syncThemeMode(mode);
    _themeModeNotifier.value = mode;
  }

  void _resetDemoData() {
    _backend.reset();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConvoKitScope(
      kit: _backend.kit,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeModeNotifier,
        builder: (context, themeMode, _) {
          ShowcaseTheme.syncThemeMode(themeMode);
          return MaterialApp(
            title: 'ConvoKit Showcase',
            debugShowCheckedModeBanner: false,
            theme: ShowcaseTheme.lightTheme(),
            darkTheme: ShowcaseTheme.darkTheme(),
            themeMode: themeMode,
            home: ShowcaseShell(
              themeMode: themeMode,
              onThemeModeChanged: _setThemeMode,
              backend: _backend,
              onResetDemoData: _resetDemoData,
            ),
          );
        },
      ),
    );
  }
}

/// Four-tab 2026 Liquid Glass navigation shell (`Chats`, `Updates`, `Calls`,
/// `Settings`) mounting [IndexedStack] full-bleed behind [FloatingGlassTabBar].
class ShowcaseShell extends StatefulWidget {
  const ShowcaseShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.backend,
    this.onResetDemoData,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final StudioBackend? backend;
  final VoidCallback? onResetDemoData;

  @override
  State<ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<ShowcaseShell> {
  int _currentIndex = 0;

  static const List<FloatingGlassTabItem> _tabs = <FloatingGlassTabItem>[
    FloatingGlassTabItem(
      label: 'Chats',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    FloatingGlassTabItem(
      label: 'Updates',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
    ),
    FloatingGlassTabItem(
      label: 'Calls',
      icon: Icons.call_outlined,
      activeIcon: Icons.call_rounded,
    ),
    FloatingGlassTabItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  bool get _isDark => widget.themeMode == ThemeMode.dark;

  String get _themeToggleTooltip =>
      _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode';

  IconData get _themeToggleIcon =>
      _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

  void _toggleTheme() {
    widget.onThemeModeChanged(_isDark ? ThemeMode.light : ThemeMode.dark);
  }

  GlassHeaderAction _buildThemeToggleAction({required bool includeTestKey}) {
    return GlassHeaderAction(
      key: includeTestKey ? const Key('showcase_theme_toggle') : null,
      icon: _themeToggleIcon,
      tooltip: _themeToggleTooltip,
      onPressed: _toggleTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: palette.background1,
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          ChatsTab(
            headerActions: <GlassHeaderAction>[
              _buildThemeToggleAction(includeTestKey: _currentIndex == 0),
            ],
          ),
          UpdatesTab(
            backend: widget.backend,
            headerActions: <GlassHeaderAction>[
              _buildThemeToggleAction(includeTestKey: _currentIndex == 1),
            ],
          ),
          CallsTab(
            headerActions: <GlassHeaderAction>[
              _buildThemeToggleAction(includeTestKey: _currentIndex == 2),
            ],
          ),
          SettingsTab(
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            backend: widget.backend,
            onResetDemoData: widget.onResetDemoData,
            headerActions: <GlassHeaderAction>[
              _buildThemeToggleAction(includeTestKey: _currentIndex == 3),
            ],
          ),
        ],
      ),
      bottomNavigationBar: FloatingGlassTabBar(
        items: _tabs,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
