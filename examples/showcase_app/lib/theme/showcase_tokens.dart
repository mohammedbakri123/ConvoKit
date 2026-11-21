import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Master semantic design tokens for the ConvoKit Showcase 2026 Redesign.
///
/// Combines:
/// - iOS 26 Liquid Glass (`.regular` nav/control layer only, concentric radii)
/// - Material 3 Expressive (`surfaceContainer` depth ladder, saturated greens,
///   full-pill buttons, emphasized typography, 150–300ms spring motion)
/// - UI/UX Pro Max accessibility & touch guardrails (>=4.5:1 contrast,
///   >=44x44 touch targets, >=8px spacing, reduced-motion support).
abstract final class ShowcaseTokens {
  // ---------------------------------------------------------------------------
  // Light Mode — Saturated Brand Greens & M3 Expressive surfaceContainer Ladder
  // ---------------------------------------------------------------------------
  static const Color lightPrimary = Color(0xFF16A34A);
  static const Color lightPrimaryStrong = Color(0xFF0F7A5A);
  static const Color lightPrimaryContainer = Color(0xFFD8F5E3);
  static const Color lightOnPrimaryContainer = Color(0xFF0A3826);

  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF7F9F8);
  static const Color lightSurfaceContainer = Color(0xFFF1F5F3);
  static const Color lightSurfaceContainerHigh = Color(0xFFE7EEEA);
  static const Color lightSurfaceContainerHighest = Color(0xFFDCE5E0);

  static const Color lightCanvas = Color(0xFFEFEAE2);
  static const Color lightOutgoingBubble = Color(0xFFDCF8C6);
  static const Color lightOutgoingText = Color(0xFF0F1F18);
  static const Color lightOutgoingTimestamp = Color(0xFF3B5248);
  static const Color lightIncomingBubble = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111B21);
  static const Color lightTextSecondary = Color(0xFF4E6069);
  static const Color lightTextTertiary = Color(0xFF5C6E77);
  static const Color lightBorder = Color(0xFFE3EAE6);
  static const Color lightBorderStrong = Color(0xFFC8D4CE);

  // ---------------------------------------------------------------------------
  // Dark Mode — OLED Canvas & M3 Expressive surfaceContainer Ladder
  // ---------------------------------------------------------------------------
  static const Color darkPrimary = Color(0xFF1DD18B);
  static const Color darkPrimaryStrong = Color(0xFF00A884);
  static const Color darkPrimaryContainer = Color(0xFF0C3B2E);
  static const Color darkOnPrimaryContainer = Color(0xFFD6F7E8);

  static const Color darkCanvas = Color(0xFF0B141A);
  static const Color darkSurfaceContainerLowest = Color(0xFF0D151B);
  static const Color darkSurfaceContainerLow = Color(0xFF121C23);
  static const Color darkSurfaceContainer = Color(0xFF17232B);
  static const Color darkSurfaceContainerHigh = Color(0xFF1F2D36);
  static const Color darkSurfaceContainerHighest = Color(0xFF283944);

  static const Color darkOutgoingBubble = Color(0xFF005C4B);
  static const Color darkOutgoingText = Color(0xFFF2F7F5);
  static const Color darkOutgoingTimestamp = Color(0xFFCCE3DD);
  static const Color darkIncomingBubble = Color(0xFF1F2D36);
  static const Color darkTextPrimary = Color(0xFFF2F5F7);
  static const Color darkTextSecondary = Color(0xFFA5B4BE);
  static const Color darkTextTertiary = Color(0xFF8B9DA8);
  static const Color darkBorder = Color(0xFF23323C);
  static const Color darkBorderStrong = Color(0xFF314452);

  // ---------------------------------------------------------------------------
  // Shared Semantic Accents
  // ---------------------------------------------------------------------------
  static const Color readReceiptBlue = Color(0xFF53BDEB);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ---------------------------------------------------------------------------
  // 8-Hue WCAG-Safe Studio Avatar Monogram Palette (>=4.5:1 with white text)
  // ---------------------------------------------------------------------------
  static const Color avatarMonogramTextColor = Color(0xFFFFFFFF);
  static const List<Color> avatarMonogramPalette = <Color>[
    Color(0xFF1B5E43), // Deep forest
    Color(0xFF166169), // Pine teal
    Color(0xFF394B7A), // Slate indigo
    Color(0xFF9A3E2A), // Burnt terracotta
    Color(0xFF7D5311), // Warm ochre
    Color(0xFF6B3B6E), // Muted plum
    Color(0xFF24577A), // Ocean slate
    Color(0xFF4B6127), // Olive moss
  ];

  // ---------------------------------------------------------------------------
  // iOS 26 Liquid Glass Tokens (.regular default — nav/control layer ONLY)
  // ---------------------------------------------------------------------------
  static const Color glassFillLight = Color(0xC7FFFFFF); // rgba(255,255,255,.78)
  static const Color glassFillDark = Color(0xC7162129); // rgba(22,33,41,.78)
  static const Color glassBorderLight = Color(0x8CFFFFFF); // rgba(255,255,255,.55)
  static const Color glassBorderDark = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const double glassBlurSigma = 24.0;
  static const double glassBorderWidth = 0.8;

  static const List<BoxShadow> glassShadowLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x140F1F18),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> glassShadowDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Concentric Radii & Full-Pill Shape Scale
  // ---------------------------------------------------------------------------
  static const double radiusNavCapsule = 30.0;
  static const double radiusNavActivePill = 22.0;
  static const double radiusHeroCard = 24.0;
  static const double radiusNestedCard = 16.0;
  static const double radiusBubble = 20.0;
  static const double radiusBubbleTailCorner = 6.0;
  static const double radiusCard = 20.0;
  static const double radiusSearchPill = 24.0;
  static const double radiusSheet = 28.0;
  static const double radiusFullPill = 999.0;

  // ---------------------------------------------------------------------------
  // Touch Target & Spacing Constants (UI/UX Pro Max Priority 2 & 5)
  // ---------------------------------------------------------------------------
  static const double minTouchTarget = 44.0;
  static const Size minTouchTargetSize = Size(minTouchTarget, minTouchTarget);
  static const double minControlGap = 8.0;

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2Xl = 24.0;
  static const double space3Xl = 32.0;

  /// Computes WCAG 2.1 contrast ratio between two opaque [Color] values.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Emphasized 2026 typography scale (34pt w800 -> 17pt w600, 16px body / 1.5
/// line-height, >=12px tabular timestamps).
abstract final class ShowcaseTypography {
  static const TextStyle displayTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const TextStyle compactTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static const TextStyle heroHeadline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1.3,
  );

  static const TextStyle bodyBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle rowTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static const TextStyle rowSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

/// Purposeful 150–300ms spring motion tokens (exit faster than enter) with
/// reduced-motion support via [MediaQuery.disableAnimationsOf].
abstract final class ShowcaseMotion {
  static const Duration enterDuration = Duration(milliseconds: 240);
  static const Duration exitDuration = Duration(milliseconds: 160);
  static const Duration tapDuration = Duration(milliseconds: 180);

  static const SpringDescription expressiveSpring = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 24.0,
  );

  static const SpringDescription crispSpring = SpringDescription(
    mass: 1.0,
    stiffness: 420.0,
    damping: 32.0,
  );

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Returns [Duration.zero] when the platform or user requests reduced motion;
  /// otherwise returns [base].
  static Duration effectiveDuration(BuildContext context, Duration base) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
  }
}
