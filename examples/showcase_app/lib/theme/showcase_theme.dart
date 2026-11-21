import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'showcase_tokens.dart';

/// Semantic color facade delegating to [ShowcaseTokens] for Light and Dark modes.
abstract final class ShowcaseColors {
  // Light mode
  static const Color lightAccent = ShowcaseTokens.lightPrimary;
  static const Color lightTitle = ShowcaseTokens.lightPrimaryStrong;
  static const Color lightSurface = ShowcaseTokens.lightSurfaceContainerLowest;
  static const Color lightSurfaceSecondary =
      ShowcaseTokens.lightSurfaceContainer;
  static const Color lightCanvas = ShowcaseTokens.lightCanvas;
  static const Color lightOutgoingBubble = ShowcaseTokens.lightOutgoingBubble;
  static const Color lightOutgoingText = ShowcaseTokens.lightOutgoingText;
  static const Color lightOutgoingTimestamp =
      ShowcaseTokens.lightOutgoingTimestamp;
  static const Color lightIncomingBubble = ShowcaseTokens.lightIncomingBubble;
  static const Color lightTextPrimary = ShowcaseTokens.lightTextPrimary;
  static const Color lightTextSecondary = ShowcaseTokens.lightTextSecondary;
  static const Color lightTextTertiary = ShowcaseTokens.lightTextTertiary;
  static const Color lightBorder = ShowcaseTokens.lightBorder;

  // Dark mode
  static const Color darkAccent = ShowcaseTokens.darkPrimary;
  static const Color darkCanvas = ShowcaseTokens.darkCanvas;
  static const Color darkSurface = ShowcaseTokens.darkSurfaceContainerLow;
  static const Color darkSurfaceSecondary =
      ShowcaseTokens.darkSurfaceContainerHigh;
  static const Color darkOutgoingBubble = ShowcaseTokens.darkOutgoingBubble;
  static const Color darkOutgoingText = ShowcaseTokens.darkOutgoingText;
  static const Color darkOutgoingTimestamp =
      ShowcaseTokens.darkOutgoingTimestamp;
  static const Color darkIncomingBubble = ShowcaseTokens.darkIncomingBubble;
  static const Color darkTextPrimary = ShowcaseTokens.darkTextPrimary;
  static const Color darkTextSecondary = ShowcaseTokens.darkTextSecondary;
  static const Color darkTextTertiary = ShowcaseTokens.darkTextTertiary;
  static const Color darkBorder = ShowcaseTokens.darkBorder;

  // Shared semantic tokens
  static const Color readReceiptBlue = ShowcaseTokens.readReceiptBlue;
  static const Color errorRed = ShowcaseTokens.errorRed;
  static const Color warningAmber = ShowcaseTokens.warningAmber;
}

/// Theme factory wiring [ShowcaseTokens] into Flutter [ThemeData], ConvoKit's
/// [ThemeExtension] API ([ConvoKitColorPalette], [ConvoKitTypography],
/// [ConvoKitSpacing], [ConvoKitAvatarStyle], [ConvoKitStatusIndicatorStyle]),
/// and all component style builders for Light and Dark modes.
abstract final class ShowcaseTheme {
  /// Synchronizes ConvoKit's brightness helper with the active [ThemeMode].
  static void syncThemeMode(ThemeMode mode) {
    ConvoKitThemeMode.mode = mode;
  }

  /// Emphasized [ConvoKitTypography] extension aligned to [ShowcaseTypography].
  static ConvoKitTypography typography() {
    return const ConvoKitTypography(
      title: CometChatTextStyleTitle(
        bold: ShowcaseTypography.displayTitle,
        medium: ShowcaseTypography.heroHeadline,
        regular: ShowcaseTypography.compactTitle,
      ),
      heading1: CometChatTextStyleHeading1(
        bold: ShowcaseTypography.heroHeadline,
        medium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        regular: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      heading2: CometChatTextStyleHeading2(
        bold: ShowcaseTypography.compactTitle,
        medium: ShowcaseTypography.rowTitle,
        regular: ShowcaseTypography.bodyBase,
      ),
      heading3: CometChatTextStyleHeading3(
        bold: ShowcaseTypography.rowTitle,
        medium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        regular: ShowcaseTypography.rowSubtitle,
      ),
      heading4: CometChatTextStyleHeading4(
        bold: ShowcaseTypography.sectionLabel,
        medium: ShowcaseTypography.rowSubtitle,
        regular: ShowcaseTypography.rowSubtitle,
      ),
      body: CometChatTextStyleBody(
        bold: ShowcaseTypography.rowTitle,
        medium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        regular: ShowcaseTypography.bodyBase,
      ),
      caption1: CometChatTextStyleCaption1(
        bold: ShowcaseTypography.sectionLabel,
        medium: ShowcaseTypography.timestamp,
        regular: ShowcaseTypography.timestamp,
      ),
      caption2: CometChatTextStyleCaption2(
        bold: ShowcaseTypography.sectionLabel,
        medium: ShowcaseTypography.timestamp,
        regular: ShowcaseTypography.timestamp,
      ),
      button: CometChatTextStyleButton(
        bold: ShowcaseTypography.buttonLabel,
        medium: ShowcaseTypography.buttonLabel,
        regular: ShowcaseTypography.buttonLabel,
      ),
      link: CometChatTextStyleLink(regular: ShowcaseTypography.bodyBase),
    );
  }

  /// [ConvoKitSpacing] extension aligned to [ShowcaseTokens] radii & spacing.
  static ConvoKitSpacing spacing() {
    return ConvoKitSpacing(
      spacing: 2,
      spacing1: ShowcaseTokens.spaceXs,
      spacing2: ShowcaseTokens.spaceSm,
      spacing3: ShowcaseTokens.spaceMd,
      spacing4: ShowcaseTokens.spaceLg,
      spacing5: ShowcaseTokens.spaceXl,
      spacing6: ShowcaseTokens.space2Xl,
      spacing8: ShowcaseTokens.space3Xl,
      radius1: ShowcaseTokens.spaceXs,
      radius2: ShowcaseTokens.spaceSm,
      radius3: ShowcaseTokens.spaceMd,
      radius4: ShowcaseTokens.radiusNestedCard,
      radius5: ShowcaseTokens.radiusCard,
      radius6: ShowcaseTokens.radiusHeroCard,
      radiusMax: ShowcaseTokens.radiusFullPill,
    );
  }

  /// Shared studio avatar style carrying the 8-hue WCAG-safe [monogramPalette].
  static ConvoKitAvatarStyle avatarStyle(BuildContext context) {
    return _baseAvatarStyle();
  }

  static ConvoKitAvatarStyle _baseAvatarStyle() {
    return const ConvoKitAvatarStyle(
      monogramPalette: ShowcaseTokens.avatarMonogramPalette,
      placeHolderTextColor: ShowcaseTokens.avatarMonogramTextColor,
      placeHolderTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Surface-ringed presence indicator style so online dots separate cleanly
  /// from avatars on both Light and Dark surfaces.
  static ConvoKitStatusIndicatorStyle statusIndicatorStyle(
    BuildContext context, {
    Color? ringColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _statusIndicatorStyleForBrightness(
      isDark: isDark,
      ringColor: ringColor,
    );
  }

  static ConvoKitStatusIndicatorStyle _statusIndicatorStyleForBrightness({
    required bool isDark,
    Color? ringColor,
  }) {
    final surfaceRing = ringColor ??
        (isDark
            ? ShowcaseTokens.darkSurfaceContainerLow
            : ShowcaseTokens.lightSurfaceContainerLowest);
    final activeDot =
        isDark ? ShowcaseTokens.darkPrimary : ShowcaseTokens.lightPrimary;
    return ConvoKitStatusIndicatorStyle(
      backgroundColor: activeDot,
      border: Border.all(color: surfaceRing, width: 2),
      borderRadius: BorderRadius.circular(ShowcaseTokens.radiusFullPill),
    );
  }

  /// Light [ConvoKitColorPalette] extension.
  static ConvoKitColorPalette lightPalette() {
    return ConvoKitColorPalette(
      primary: ShowcaseTokens.lightPrimary,
      background1: ShowcaseTokens.lightSurfaceContainerLowest,
      background2: ShowcaseTokens.lightSurfaceContainer,
      background3: ShowcaseTokens.lightCanvas,
      background4: ShowcaseTokens.lightSurfaceContainerHigh,
      textPrimary: ShowcaseTokens.lightTextPrimary,
      textSecondary: ShowcaseTokens.lightTextSecondary,
      textTertiary: ShowcaseTokens.lightTextTertiary,
      textWhite: ShowcaseTokens.lightSurfaceContainerLowest,
      textHighlight: ShowcaseTokens.lightPrimaryStrong,
      borderLight: ShowcaseTokens.lightBorder,
      borderDefault: ShowcaseTokens.lightBorder,
      borderDark: ShowcaseTokens.lightBorderStrong,
      borderHighlight: ShowcaseTokens.lightPrimary,
      iconPrimary: ShowcaseTokens.lightTextPrimary,
      iconSecondary: ShowcaseTokens.lightTextSecondary,
      iconTertiary: ShowcaseTokens.lightTextTertiary,
      iconWhite: ShowcaseTokens.lightSurfaceContainerLowest,
      iconHighlight: ShowcaseTokens.lightPrimaryStrong,
      buttonBackground: ShowcaseTokens.lightPrimary,
      buttonIconColor: ShowcaseTokens.lightSurfaceContainerLowest,
      buttonText: ShowcaseTokens.lightSurfaceContainerLowest,
      success: ShowcaseTokens.lightPrimary,
      info: ShowcaseTokens.readReceiptBlue,
      warning: ShowcaseTokens.warningAmber,
      error: ShowcaseTokens.errorRed,
      messageSeen: ShowcaseTokens.readReceiptBlue,
      white: ShowcaseTokens.lightSurfaceContainerLowest,
      black: ShowcaseTokens.lightTextPrimary,
    );
  }

  /// Dark [ConvoKitColorPalette] extension.
  static ConvoKitColorPalette darkPalette() {
    return ConvoKitColorPalette(
      primary: ShowcaseTokens.darkPrimary,
      background1: ShowcaseTokens.darkSurfaceContainerLow,
      background2: ShowcaseTokens.darkSurfaceContainerHigh,
      background3: ShowcaseTokens.darkCanvas,
      background4: ShowcaseTokens.darkSurfaceContainerHighest,
      textPrimary: ShowcaseTokens.darkTextPrimary,
      textSecondary: ShowcaseTokens.darkTextSecondary,
      textTertiary: ShowcaseTokens.darkTextTertiary,
      textWhite: ShowcaseTokens.darkTextPrimary,
      textHighlight: ShowcaseTokens.darkPrimary,
      borderLight: ShowcaseTokens.darkBorder,
      borderDefault: ShowcaseTokens.darkBorder,
      borderDark: ShowcaseTokens.darkBorderStrong,
      borderHighlight: ShowcaseTokens.darkPrimary,
      iconPrimary: ShowcaseTokens.darkTextPrimary,
      iconSecondary: ShowcaseTokens.darkTextSecondary,
      iconTertiary: ShowcaseTokens.darkTextTertiary,
      iconWhite: ShowcaseTokens.darkTextPrimary,
      iconHighlight: ShowcaseTokens.darkPrimary,
      buttonBackground: ShowcaseTokens.darkPrimary,
      buttonIconColor: ShowcaseTokens.darkCanvas,
      buttonText: ShowcaseTokens.darkCanvas,
      success: ShowcaseTokens.darkPrimary,
      info: ShowcaseTokens.readReceiptBlue,
      warning: ShowcaseTokens.warningAmber,
      error: ShowcaseTokens.errorRed,
      messageSeen: ShowcaseTokens.readReceiptBlue,
      white: ShowcaseTokens.lightSurfaceContainerLowest,
      black: ShowcaseTokens.darkCanvas,
    );
  }

  static TextTheme _buildTextTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      displaySmall: ShowcaseTypography.displayTitle.copyWith(
        color: primaryText,
      ),
      headlineMedium: ShowcaseTypography.heroHeadline.copyWith(
        color: primaryText,
      ),
      titleLarge: ShowcaseTypography.heroHeadline.copyWith(color: primaryText),
      titleMedium: ShowcaseTypography.compactTitle.copyWith(color: primaryText),
      titleSmall: ShowcaseTypography.rowTitle.copyWith(color: primaryText),
      bodyLarge: ShowcaseTypography.bodyBase.copyWith(color: primaryText),
      bodyMedium: ShowcaseTypography.rowSubtitle.copyWith(color: primaryText),
      bodySmall: ShowcaseTypography.timestamp.copyWith(color: secondaryText),
      labelLarge: ShowcaseTypography.buttonLabel.copyWith(color: primaryText),
      labelMedium: ShowcaseTypography.sectionLabel.copyWith(
        color: secondaryText,
      ),
      labelSmall: ShowcaseTypography.timestamp.copyWith(color: secondaryText),
    );
  }

  /// Light [ThemeData] carrying M3 Expressive `surfaceContainer` depth ladder,
  /// full-pill button themes (>=44x44 touch targets), and ConvoKit extensions.
  static ThemeData lightTheme() {
    final palette = lightPalette();
    const colorScheme = ColorScheme.light(
      primary: ShowcaseTokens.lightPrimary,
      onPrimary: ShowcaseTokens.lightSurfaceContainerLowest,
      primaryContainer: ShowcaseTokens.lightPrimaryContainer,
      onPrimaryContainer: ShowcaseTokens.lightOnPrimaryContainer,
      secondary: ShowcaseTokens.lightPrimaryStrong,
      onSecondary: ShowcaseTokens.lightSurfaceContainerLowest,
      surface: ShowcaseTokens.lightSurfaceContainerLowest,
      onSurface: ShowcaseTokens.lightTextPrimary,
      onSurfaceVariant: ShowcaseTokens.lightTextSecondary,
      surfaceContainerLowest: ShowcaseTokens.lightSurfaceContainerLowest,
      surfaceContainerLow: ShowcaseTokens.lightSurfaceContainerLow,
      surfaceContainer: ShowcaseTokens.lightSurfaceContainer,
      surfaceContainerHigh: ShowcaseTokens.lightSurfaceContainerHigh,
      surfaceContainerHighest: ShowcaseTokens.lightSurfaceContainerHighest,
      outline: ShowcaseTokens.lightBorderStrong,
      outlineVariant: ShowcaseTokens.lightBorder,
      error: ShowcaseTokens.errorRed,
      onError: ShowcaseTokens.lightSurfaceContainerLowest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ShowcaseTokens.lightSurfaceContainerLowest,
      dividerColor: ShowcaseTokens.lightBorder,
      textTheme: _buildTextTheme(
        primaryText: ShowcaseTokens.lightTextPrimary,
        secondaryText: ShowcaseTokens.lightTextSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: ShowcaseTokens.spaceXl,
            vertical: ShowcaseTokens.spaceMd,
          ),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          side: const BorderSide(color: ShowcaseTokens.lightBorderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: ShowcaseTokens.spaceXl,
            vertical: ShowcaseTokens.spaceMd,
          ),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const StadiumBorder(),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ShowcaseTokens.lightSurfaceContainerLowest,
        foregroundColor: ShowcaseTokens.lightPrimaryStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: ShowcaseTypography.heroHeadline.copyWith(
          color: ShowcaseTokens.lightPrimaryStrong,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShowcaseTokens.lightSurfaceContainerLowest,
        selectedItemColor: ShowcaseTokens.lightPrimary,
        unselectedItemColor: ShowcaseTokens.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        palette,
        typography(),
        spacing(),
        _baseAvatarStyle(),
        _statusIndicatorStyleForBrightness(isDark: false),
      ],
    );
  }

  /// Dark [ThemeData] carrying OLED-friendly `surfaceContainer` depth ladder,
  /// full-pill button themes (>=44x44 touch targets), and ConvoKit extensions.
  static ThemeData darkTheme() {
    final palette = darkPalette();
    const colorScheme = ColorScheme.dark(
      primary: ShowcaseTokens.darkPrimary,
      onPrimary: ShowcaseTokens.darkCanvas,
      primaryContainer: ShowcaseTokens.darkPrimaryContainer,
      onPrimaryContainer: ShowcaseTokens.darkOnPrimaryContainer,
      secondary: ShowcaseTokens.darkPrimaryStrong,
      onSecondary: ShowcaseTokens.darkCanvas,
      surface: ShowcaseTokens.darkSurfaceContainerLow,
      onSurface: ShowcaseTokens.darkTextPrimary,
      onSurfaceVariant: ShowcaseTokens.darkTextSecondary,
      surfaceContainerLowest: ShowcaseTokens.darkSurfaceContainerLowest,
      surfaceContainerLow: ShowcaseTokens.darkSurfaceContainerLow,
      surfaceContainer: ShowcaseTokens.darkSurfaceContainer,
      surfaceContainerHigh: ShowcaseTokens.darkSurfaceContainerHigh,
      surfaceContainerHighest: ShowcaseTokens.darkSurfaceContainerHighest,
      outline: ShowcaseTokens.darkBorderStrong,
      outlineVariant: ShowcaseTokens.darkBorder,
      error: ShowcaseTokens.errorRed,
      onError: ShowcaseTokens.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ShowcaseTokens.darkCanvas,
      dividerColor: ShowcaseTokens.darkBorder,
      textTheme: _buildTextTheme(
        primaryText: ShowcaseTokens.darkTextPrimary,
        secondaryText: ShowcaseTokens.darkTextSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: ShowcaseTokens.spaceXl,
            vertical: ShowcaseTokens.spaceMd,
          ),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          side: const BorderSide(color: ShowcaseTokens.darkBorderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: ShowcaseTokens.spaceXl,
            vertical: ShowcaseTokens.spaceMd,
          ),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          shape: const StadiumBorder(),
          textStyle: ShowcaseTypography.buttonLabel,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const StadiumBorder(),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ShowcaseTokens.darkSurfaceContainerLow,
        foregroundColor: ShowcaseTokens.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: ShowcaseTypography.heroHeadline.copyWith(
          color: ShowcaseTokens.darkTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShowcaseTokens.darkSurfaceContainerLow,
        selectedItemColor: ShowcaseTokens.darkPrimary,
        unselectedItemColor: ShowcaseTokens.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        palette,
        typography(),
        spacing(),
        _baseAvatarStyle(),
        _statusIndicatorStyleForBrightness(isDark: true),
      ],
    );
  }

  /// Style builder for [ConvoKitConversations].
  static ConvoKitConversationsStyle conversationsStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConvoKitConversationsStyle(
      backgroundColor: palette.background1,
      titleTextColor: isDark
          ? ShowcaseTokens.darkTextPrimary
          : ShowcaseTokens.lightPrimaryStrong,
      titleTextStyle: ShowcaseTypography.displayTitle.copyWith(
        color: isDark
            ? ShowcaseTokens.darkTextPrimary
            : ShowcaseTokens.lightPrimaryStrong,
      ),
      itemTitleTextColor: palette.textPrimary,
      itemTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
        color: palette.textPrimary,
      ),
      itemSubtitleTextColor: palette.textSecondary,
      itemSubtitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
        color: palette.textSecondary,
      ),
      separatorColor: palette.borderLight,
      separatorHeight: 0.6,
      searchBackgroundColor: palette.background2,
      searchBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusSearchPill,
      ),
      searchIconColor: palette.iconSecondary,
      searchPlaceHolderTextColor: palette.textSecondary,
      avatarStyle: avatarStyle(context),
      dateStyle: ConvoKitDateStyle(
        textColor: palette.textSecondary,
        textStyle: ShowcaseTypography.timestamp.copyWith(
          color: palette.textSecondary,
        ),
      ),
      badgeStyle: ConvoKitBadgeStyle(
        backgroundColor: palette.primary,
        textColor: isDark
            ? ShowcaseTokens.darkCanvas
            : ShowcaseTokens.lightSurfaceContainerLowest,
      ),
      receiptStyle: CometChatMessageReceiptStyle(
        sentIconColor: palette.iconSecondary,
        deliveredIconColor: palette.iconSecondary,
        readIconColor: ShowcaseTokens.readReceiptBlue,
      ),
      statusIndicatorStyle: statusIndicatorStyle(context),
    );
  }

  /// Style builder for [ConvoKitMessageHeader] with iOS 26 Liquid Glass
  /// frosting (`blurSigma: 24`) spanning status bar + header.
  static ConvoKitMessageHeaderStyle messageHeaderStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTitleColor = isDark
        ? ShowcaseTokens.darkTextPrimary
        : ShowcaseTokens.lightPrimaryStrong;
    final glassFill =
        isDark ? ShowcaseTokens.glassFillDark : ShowcaseTokens.glassFillLight;
    final glassBorder = isDark
        ? ShowcaseTokens.glassBorderDark
        : ShowcaseTokens.glassBorderLight;
    final glassShadow = isDark
        ? ShowcaseTokens.glassShadowDark
        : ShowcaseTokens.glassShadowLight;
    return ConvoKitMessageHeaderStyle(
      backgroundColor: glassFill,
      blurSigma: ShowcaseTokens.glassBlurSigma,
      border: Border(
        bottom: BorderSide(
          color: glassBorder,
          width: ShowcaseTokens.glassBorderWidth,
        ),
      ),
      boxShadow: glassShadow,
      titleTextColor: headerTitleColor,
      titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
        color: headerTitleColor,
      ),
      subtitleTextColor: palette.textSecondary,
      subtitleTextStyle: ShowcaseTypography.timestamp.copyWith(
        color: palette.textSecondary,
      ),
      backIconColor: isDark
          ? ShowcaseTokens.darkPrimary
          : ShowcaseTokens.lightPrimaryStrong,
      menuIconColor: isDark
          ? ShowcaseTokens.darkPrimary
          : ShowcaseTokens.lightPrimaryStrong,
      onlineStatusColor: palette.primary,
      avatarStyle: avatarStyle(context),
      statusIndicatorStyle: statusIndicatorStyle(context),
    );
  }

  /// Style builder for [ConvoKitMessageList], preserving `#DCF8C6` (Light) and
  /// `#005C4B` (Dark) outgoing bubbles with >=4.5:1 readable text & timestamps.
  static ConvoKitMessageListStyle messageListStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outgoingBubbleColor = isDark
        ? ShowcaseTokens.darkOutgoingBubble
        : ShowcaseTokens.lightOutgoingBubble;
    final outgoingText = isDark
        ? ShowcaseTokens.darkOutgoingText
        : ShowcaseTokens.lightOutgoingText;
    final outgoingTimestampColor = isDark
        ? ShowcaseTokens.darkOutgoingTimestamp
        : ShowcaseTokens.lightOutgoingTimestamp;
    final incomingTimestampColor = palette.textSecondary;
    final incomingBubbleColor = isDark
        ? ShowcaseTokens.darkIncomingBubble
        : ShowcaseTokens.lightIncomingBubble;
    final canvasColor =
        isDark ? ShowcaseTokens.darkCanvas : ShowcaseTokens.lightCanvas;
    final bubbleRadius = BorderRadius.circular(ShowcaseTokens.radiusBubble);
    final receiptStyle = CometChatMessageReceiptStyle(
      sentIconColor: outgoingTimestampColor,
      deliveredIconColor: outgoingTimestampColor,
      readIconColor: ShowcaseTokens.readReceiptBlue,
    );

    final subtleBorderColor = (palette.borderLight ?? Colors.transparent)
        .withValues(alpha: isDark ? 0.45 : 0.7);
    final bubbleShadow = <BoxShadow>[
      BoxShadow(
        color: (palette.black ?? ShowcaseTokens.lightTextPrimary)
            .withValues(alpha: isDark ? 0.22 : 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    return ConvoKitMessageListStyle(
      backgroundColor: canvasColor,
      outgoingTextColor: outgoingText,
      avatarStyle: avatarStyle(context),
      showBubbleTail: true,
      bubbleShadow: bubbleShadow,
      messageEntryCurve: Curves.easeOutBack,
      messageEntryDuration: ShowcaseMotion.enterDuration,
      emptyStateTextColor: palette.textPrimary,
      emptyStateSubtitleColor: palette.textSecondary,
      errorStateTextColor: palette.textPrimary,
      errorStateSubtitleColor: palette.textSecondary,
      outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
        backgroundColor: outgoingBubbleColor,
        border: Border.all(color: subtleBorderColor, width: 0.5),
        borderRadius: bubbleRadius,
        textBubbleStyle: CometChatTextBubbleStyle(
          backgroundColor: outgoingBubbleColor,
          textColor: outgoingText,
          textStyle: ShowcaseTypography.bodyBase.copyWith(color: outgoingText),
          borderRadius: bubbleRadius,
        ),
        messageReceiptStyle: receiptStyle,
        messageBubbleDateStyle: ConvoKitDateStyle(
          textColor: outgoingTimestampColor,
          textStyle: ShowcaseTypography.timestamp.copyWith(
            color: outgoingTimestampColor,
          ),
        ),
      ),
      incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
        backgroundColor: incomingBubbleColor,
        border: Border.all(color: subtleBorderColor, width: 0.6),
        borderRadius: bubbleRadius,
        textBubbleStyle: CometChatTextBubbleStyle(
          backgroundColor: incomingBubbleColor,
          textColor: palette.textPrimary,
          textStyle: ShowcaseTypography.bodyBase.copyWith(
            color: palette.textPrimary,
          ),
          borderRadius: bubbleRadius,
        ),
        messageBubbleDateStyle: ConvoKitDateStyle(
          textColor: incomingTimestampColor,
          textStyle: ShowcaseTypography.timestamp.copyWith(
            color: incomingTimestampColor,
          ),
        ),
      ),
    );
  }

  /// Style builder for [ConvoKitMessageComposer] as a floating Liquid Glass
  /// pill (`blurSigma: 24`, radius `28`, outerMargin `EdgeInsets.fromLTRB(12, 0, 12, 10)`).
  static ConvoKitMessageComposerStyle messageComposerStyle(
    BuildContext context,
  ) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill =
        isDark ? ShowcaseTokens.glassFillDark : ShowcaseTokens.glassFillLight;
    final glassBorder = isDark
        ? ShowcaseTokens.glassBorderDark
        : ShowcaseTokens.glassBorderLight;
    final glassShadow = isDark
        ? ShowcaseTokens.glassShadowDark
        : ShowcaseTokens.glassShadowLight;
    return ConvoKitMessageComposerStyle(
      backgroundColor: glassFill,
      filledColor: Colors.transparent,
      blurSigma: ShowcaseTokens.glassBlurSigma,
      borderRadius: BorderRadius.circular(ShowcaseTokens.radiusSheet),
      outerMargin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      border: Border.all(
        color: glassBorder,
        width: ShowcaseTokens.glassBorderWidth,
      ),
      boxShadow: glassShadow,
      textColor: palette.textPrimary,
      textStyle: ShowcaseTypography.bodyBase.copyWith(
        color: palette.textPrimary,
      ),
      placeHolderTextColor: palette.textSecondary,
      placeHolderTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: palette.textSecondary,
      ),
      dividerColor: palette.borderLight,
      sendButtonIconColor: isDark
          ? ShowcaseTokens.darkCanvas
          : ShowcaseTokens.lightSurfaceContainerLowest,
      sendButtonIconBackgroundColor: palette.primary,
      sendButtonBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusFullPill,
      ),
      auxiliaryButtonIconColor: palette.iconSecondary,
      secondaryButtonIconColor: palette.iconSecondary,
      stickerIconColor: palette.iconSecondary,
      stickerActiveIconColor: palette.primary,
    );
  }

  /// Style builder for [ConvoKitUsers].
  static ConvoKitUsersStyle usersStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    return ConvoKitUsersStyle(
      backgroundColor: palette.background1,
      backIconColor: colorScheme.primary,
      submitIconColor: colorScheme.primary,
      titleTextColor: colorScheme.onSurface,
      titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      itemTitleTextColor: colorScheme.onSurface,
      itemTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      stickyTitleColor: colorScheme.primary,
      stickyTitleTextStyle: ShowcaseTypography.sectionLabel.copyWith(
        color: colorScheme.primary,
      ),
      separatorColor: colorScheme.outlineVariant,
      separatorHeight: 0.6,
      searchBackgroundColor: colorScheme.surfaceContainerHigh,
      searchBorder: BorderSide(color: colorScheme.outlineVariant),
      searchBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusSearchPill,
      ),
      searchIconColor: colorScheme.onSurfaceVariant,
      searchInputTextColor: colorScheme.onSurface,
      searchInputTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurface,
      ),
      searchPlaceHolderTextColor: colorScheme.onSurfaceVariant,
      searchPlaceHolderTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      listItemSelectedBackgroundColor: colorScheme.primaryContainer.withValues(
        alpha: 0.35,
      ),
      checkBoxCheckedBackgroundColor: colorScheme.primary,
      checkboxSelectedIconColor: colorScheme.onPrimary,
      checkBoxBorder: BorderSide(color: colorScheme.outline, width: 1.5),
      checkBoxBorderRadius: BorderRadius.circular(ShowcaseTokens.spaceXs),
      avatarStyle: avatarStyle(context),
      statusIndicatorStyle: statusIndicatorStyle(context),
    );
  }

  /// Style builder for [ConvoKitGroups].
  static ConvoKitGroupsStyle groupsStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    return ConvoKitGroupsStyle(
      backgroundColor: palette.background1,
      backIconColor: colorScheme.primary,
      submitIconColor: colorScheme.primary,
      titleTextColor: colorScheme.onSurface,
      titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      itemTitleTextColor: colorScheme.onSurface,
      itemTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      itemSubtitleTextColor: colorScheme.onSurfaceVariant,
      itemSubtitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      separatorColor: colorScheme.outlineVariant,
      separatorHeight: 0.6,
      searchBackgroundColor: colorScheme.surfaceContainerHigh,
      searchBorder: BorderSide(color: colorScheme.outlineVariant),
      searchBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusSearchPill,
      ),
      searchIconColor: colorScheme.onSurfaceVariant,
      searchInputTextColor: colorScheme.onSurface,
      searchInputTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurface,
      ),
      searchPlaceHolderTextColor: colorScheme.onSurfaceVariant,
      searchPlaceHolderTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      listItemSelectedBackgroundColor: colorScheme.primaryContainer.withValues(
        alpha: 0.35,
      ),
      checkBoxCheckedBackgroundColor: colorScheme.primary,
      checkboxSelectedIconColor: colorScheme.onPrimary,
      checkBoxBorder: BorderSide(color: colorScheme.outline, width: 1.5),
      checkBoxBorderRadius: BorderRadius.circular(ShowcaseTokens.spaceXs),
      privateGroupIconBackground: colorScheme.primaryContainer,
      protectedGroupIconBackground: colorScheme.surfaceContainerHighest,
      avatarStyle: avatarStyle(context),
      statusIndicatorStyle: statusIndicatorStyle(context),
    );
  }

  /// Style builder for [ConvoKitGroupMembers].
  static ConvoKitGroupMembersStyle groupMembersStyle(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    return ConvoKitGroupMembersStyle(
      backgroundColor: palette.background1,
      titleStyle: ShowcaseTypography.compactTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      backIconColor: colorScheme.primary,
      searchBackground: colorScheme.surfaceContainerHigh,
      searchBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusSearchPill,
      ),
      searchIconColor: colorScheme.onSurfaceVariant,
      searchTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurface,
      ),
      searchPlaceholderStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      onlineStatusColor: colorScheme.primary,
      separatorColor: colorScheme.outlineVariant,
      separatorHeight: 0.6,
      avatarStyle: avatarStyle(context),
      statusIndicatorStyle: statusIndicatorStyle(context),
      listItemStyle: ListItemStyle(
        titleStyle: ShowcaseTypography.rowTitle.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      ownerMemberScopeBackgroundColor: colorScheme.primary,
      ownerMemberScopeTextColor: colorScheme.onPrimary,
      ownerMemberScopeTextStyle: ShowcaseTypography.sectionLabel.copyWith(
        color: colorScheme.onPrimary,
      ),
      adminMemberScopeBackgroundColor: colorScheme.primaryContainer,
      adminMemberScopeTextColor: colorScheme.onPrimaryContainer,
      adminMemberScopeBorder: Border.all(
        color: colorScheme.primary.withValues(alpha: 0.28),
      ),
      adminMemberScopeTextStyle: ShowcaseTypography.sectionLabel.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
      moderatorMemberScopeBackgroundColor: colorScheme.surfaceContainerHigh,
      moderatorMemberScopeTextColor: colorScheme.onSurfaceVariant,
      moderatorMemberScopeTextStyle: ShowcaseTypography.sectionLabel.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      optionsBackgroundColor: colorScheme.surfaceContainerLow,
      optionsIconColor: colorScheme.primary,
      optionsTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
        color: colorScheme.onSurface,
      ),
      changeScopeStyle: changeScopeStyle(context),
    );
  }

  /// Style builder for [ConvoKitChangeScope] with extra-large top sheet
  /// rounding (radius 28) and M3 Expressive full-pill Save/Cancel buttons.
  static ConvoKitChangeScopeStyle changeScopeStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConvoKitChangeScopeStyle(
      backgroundColor: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(ShowcaseTokens.radiusSheet),
      ),
      titleTextStyle: ShowcaseTypography.heroHeadline.copyWith(
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      scopeTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurface,
      ),
      selectedScopeTextStyle: ShowcaseTypography.rowTitle.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
      scopeSectionBorder: Border.all(color: colorScheme.outlineVariant),
      tileColor: colorScheme.surfaceContainerLow,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.45),
      iconColor: colorScheme.primary,
      iconBackgroundColor: colorScheme.primaryContainer,
      radioButtonColor: colorScheme.outline,
      radioButtonSelectedColor: colorScheme.primary,
      saveButtonBackgroundColor: colorScheme.primary,
      saveButtonBorder: BorderSide.none,
      saveButtonBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusFullPill,
      ),
      saveButtonTextStyle: ShowcaseTypography.buttonLabel.copyWith(
        color: colorScheme.onPrimary,
      ),
      cancelButtonBackgroundColor: colorScheme.surfaceContainerHigh,
      cancelButtonBorder: BorderSide(color: colorScheme.outlineVariant),
      cancelButtonBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusFullPill,
      ),
      cancelButtonTextStyle: ShowcaseTypography.buttonLabel.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// Style builder for [CometChatSearch] with full-pill search field (radius 24)
  /// on `surfaceContainerHigh` and emphasized section headers.
  static CometChatSearchStyle searchStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CometChatSearchStyle(
      backgroundColor: colorScheme.surface,
      searchBackgroundColor: colorScheme.surfaceContainerHigh,
      searchTextColor: colorScheme.onSurface,
      searchTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurface,
      ),
      searchPlaceHolderTextColor: colorScheme.onSurfaceVariant,
      searchPlaceHolderTextStyle: ShowcaseTypography.bodyBase.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      searchBorder: BorderSide(color: colorScheme.outlineVariant),
      searchBorderRadius: BorderRadius.circular(
        ShowcaseTokens.radiusSearchPill,
      ),
      searchBackIconColor: colorScheme.primary,
      searchClearIconColor: colorScheme.onSurfaceVariant,
      sectionHeaderTextColor: colorScheme.onSurfaceVariant,
      sectionHeaderTextStyle: ShowcaseTypography.sectionLabel.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      searchConversationTitleTextColor: colorScheme.onSurface,
      searchConversationTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      searchConversationSubtitleTextColor: colorScheme.onSurfaceVariant,
      searchConversationSubtitleTextStyle: ShowcaseTypography.rowSubtitle
          .copyWith(color: colorScheme.onSurfaceVariant),
      emptyStateTextColor: colorScheme.onSurface,
      emptyStateTextStyle: ShowcaseTypography.compactTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      emptyStateSubTitleTextColor: colorScheme.onSurfaceVariant,
      emptyStateSubTitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStateTextColor: colorScheme.onSurface,
      errorStateTextStyle: ShowcaseTypography.compactTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      seeMoreTextColor: colorScheme.primary,
      seeMoreTextStyle: ShowcaseTypography.buttonLabel.copyWith(
        color: colorScheme.primary,
      ),
      avatarStyle: avatarStyle(context),
      statusIndicatorStyle: statusIndicatorStyle(context),
      dateStyle: ConvoKitDateStyle(
        textColor: colorScheme.onSurfaceVariant,
        textStyle: ShowcaseTypography.timestamp.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
