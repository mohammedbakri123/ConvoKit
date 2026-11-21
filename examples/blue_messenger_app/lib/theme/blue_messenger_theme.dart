import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// Coherent Ocean / Cobalt Blue palette used across Blue Messenger.
/// Strictly zero green tones anywhere in the app.
abstract final class BlueMessengerColors {
  /// Deep cobalt blue primary (app bar brand title, primary CTA, active icons, avatars).
  static const Color deepBlue = Color(0xFF0D47A1);

  /// Royal blue accent (FAB, send button, badges, active indicators, online dot).
  static const Color royalBlue = Color(0xFF1976D2);

  /// Bright sky blue accent (read ticks, subtle highlights, selected accents).
  static const Color skyBlue = Color(0xFF29B6F6);

  /// Light blue fill for outgoing message bubbles.
  static const Color outgoingBubble = Color(0xFFD6EAFF);

  /// Crisp white fill for incoming message bubbles & floating islands.
  static const Color incomingBubble = Color(0xFFFFFFFF);

  /// Soft ice-blue canvas behind floating islands and chat messages.
  static const Color canvasBackground = Color(0xFFEEF4FB);

  /// Elevated floating island surface.
  static const Color islandSurface = Color(0xFFFFFFFF);

  /// Inactive pill/chip surface.
  static const Color chipFill = Color(0xFFE3EFFC);

  /// Active pill/chip/nav-indicator fill.
  static const Color activeChipFill = Color(0xFFBBDEFB);

  /// Soft blue hairline border for floating islands and cards.
  static const Color islandBorder = Color(0xFFCFE2F7);

  /// Deep navy ink for primary typography.
  static const Color textPrimary = Color(0xFF0F1E36);

  /// Slate blue for secondary subtitles, timestamps, and muted icons.
  static const Color textSecondary = Color(0xFF4A6282);

  /// Soft steel blue for placeholders and tertiary metadata.
  static const Color textTertiary = Color(0xFF7B93B2);

  /// Subtle deep-blue tinted shadow for floating-island elevation.
  static const Color islandShadow = Color(0x1A0D47A1);

  /// Stronger shadow for detached navigation pill and FAB.
  static const Color navShadow = Color(0x260D47A1);

  /// Soft error red for destructive actions.
  static const Color errorRed = Color(0xFFD32F2F);
}

/// Shared floating-island decoration tokens for consistent modern elevation.
abstract final class BlueIslandDecorations {
  static BoxDecoration island({
    Color color = BlueMessengerColors.islandSurface,
    double radius = 24,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: BlueMessengerColors.islandBorder, width: 1),
      boxShadow: elevated
          ? const [
              BoxShadow(
                color: BlueMessengerColors.islandShadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration floatingPill({
    Color color = BlueMessengerColors.islandSurface,
    double radius = 32,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: BlueMessengerColors.islandBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: BlueMessengerColors.navShadow,
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    );
  }
}

/// Builds the Blue Messenger [ThemeData] with a coherent Ocean/Cobalt Blue
/// [ColorScheme] and [ConvoKitColorPalette] extension so every ConvoKit
/// component inherits the blue palette natively.
ThemeData buildBlueMessengerTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: BlueMessengerColors.deepBlue,
      primary: BlueMessengerColors.deepBlue,
      secondary: BlueMessengerColors.royalBlue,
      tertiary: BlueMessengerColors.skyBlue,
      surface: BlueMessengerColors.islandSurface,
    ),
    scaffoldBackgroundColor: BlueMessengerColors.canvasBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: BlueMessengerColors.canvasBackground,
      foregroundColor: BlueMessengerColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: BlueMessengerColors.deepBlue),
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: BlueMessengerColors.deepBlue,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BlueMessengerColors.deepBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      disabledElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: BlueMessengerColors.islandSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: BlueMessengerColors.islandBorder),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      ConvoKitColorPalette(
        primary: BlueMessengerColors.royalBlue,
        success: BlueMessengerColors.royalBlue,
        background1: BlueMessengerColors.islandSurface,
        background2: BlueMessengerColors.canvasBackground,
        background3: BlueMessengerColors.chipFill,
        textPrimary: BlueMessengerColors.textPrimary,
        textSecondary: BlueMessengerColors.textSecondary,
        textTertiary: BlueMessengerColors.textTertiary,
        iconPrimary: BlueMessengerColors.deepBlue,
        iconSecondary: BlueMessengerColors.textSecondary,
        iconWhite: Colors.white,
        buttonBackground: BlueMessengerColors.deepBlue,
        buttonIconColor: Colors.white,
        messageSeen: BlueMessengerColors.skyBlue,
      ),
    ],
  );
}
