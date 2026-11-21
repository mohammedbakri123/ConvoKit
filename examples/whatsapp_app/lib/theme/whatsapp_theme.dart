import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// Modern 2024+ Android WhatsApp color tokens used across the example app.
abstract final class WhatsAppColors {
  static const Color brandGreen = Color(0xFF1DAB61);
  static const Color darkGreen = Color(0xFF008069);
  static const Color activeChipFill = Color(0xFFD8FDD2);
  static const Color chipFill = Color(0xFFF0F2F5);
  static const Color outgoingBubble = Color(0xFFD9FDD3);
  static const Color incomingBubble = Color(0xFFFFFFFF);
  static const Color chatBackground = Color(0xFFEFEAE2);
  static const Color readTickBlue = Color(0xFF53BDEB);
  static const Color textPrimary = Color(0xFF111B21);
  static const Color mutedIcon = Color(0xFF54656F);
  static const Color subtitleGrey = Color(0xFF667781);
}

/// Builds a modern 2024+ Android WhatsApp [ThemeData] with explicit Roboto
/// typography and a matching [ConvoKitColorPalette] extension so ConvoKit
/// components inherit the palette without custom rendering.
ThemeData buildWhatsAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: WhatsAppColors.brandGreen,
      primary: WhatsAppColors.brandGreen,
      secondary: WhatsAppColors.darkGreen,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: WhatsAppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: WhatsAppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: WhatsAppColors.darkGreen,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: WhatsAppColors.activeChipFill,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: WhatsAppColors.textPrimary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? WhatsAppColors.darkGreen
              : WhatsAppColors.textPrimary,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: WhatsAppColors.brandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      disabledElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide.none,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      ConvoKitColorPalette(
        primary: WhatsAppColors.brandGreen,
        success: WhatsAppColors.brandGreen,
        background1: Colors.white,
        background2: WhatsAppColors.chipFill,
        background3: WhatsAppColors.incomingBubble,
        textPrimary: WhatsAppColors.textPrimary,
        textSecondary: WhatsAppColors.subtitleGrey,
        textTertiary: const Color(0xFF8696A0),
        iconPrimary: WhatsAppColors.textPrimary,
        iconSecondary: WhatsAppColors.mutedIcon,
        iconWhite: Colors.white,
        buttonBackground: WhatsAppColors.brandGreen,
        buttonIconColor: Colors.white,
        messageSeen: WhatsAppColors.readTickBlue,
      ),
    ],
  );
}
