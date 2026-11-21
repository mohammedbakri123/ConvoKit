import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/showcase_tokens.dart';

/// iOS 26 Liquid Glass `.regular` surface container for the navigation and
/// control layer.
///
/// **STRICT ARCHITECTURAL RULE (iOS 26 Liquid Glass HIG):**
/// Use [GlassSurface] ONLY for floating navigation bars, collapsing headers,
/// toolbar action capsules, and floating control chrome.
/// NEVER apply [GlassSurface] to content cards, list rows, message bubbles,
/// or media containers, and never stack glass on top of glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurSigma = ShowcaseTokens.glassBlurSigma,
    this.showBorder = true,
    this.showShadow = true,
    this.border,
    this.fillColor,
  });

  /// Content hosted inside the glass control chrome.
  final Widget child;

  /// Corner radius of the glass surface; defaults to
  /// [ShowcaseTokens.radiusNavCapsule].
  final BorderRadius? borderRadius;

  /// Optional inner padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Optional outer margin around the glass container.
  final EdgeInsetsGeometry? margin;

  /// Gaussian blur sigma for [BackdropFilter]; defaults to
  /// [ShowcaseTokens.glassBlurSigma]. When `<= 0`, skips [BackdropFilter].
  final double blurSigma;

  /// Whether to draw the specular hairline border when [border] is omitted.
  final bool showBorder;

  /// Whether to apply the subtle ambient shadow beneath the floating surface.
  final bool showShadow;

  /// Optional explicit border override; takes precedence over [showBorder].
  final BoxBorder? border;

  /// Optional translucent fill override; defaults to
  /// [ShowcaseTokens.glassFillLight] / [ShowcaseTokens.glassFillDark].
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(ShowcaseTokens.radiusNavCapsule);
    final resolvedFill = fillColor ??
        (isDark
            ? ShowcaseTokens.glassFillDark
            : ShowcaseTokens.glassFillLight);
    final resolvedBorder = border ??
        (showBorder
            ? Border.all(
                color: isDark
                    ? ShowcaseTokens.glassBorderDark
                    : ShowcaseTokens.glassBorderLight,
                width: ShowcaseTokens.glassBorderWidth,
              )
            : null);
    final resolvedShadow = showShadow
        ? (isDark
            ? ShowcaseTokens.glassShadowDark
            : ShowcaseTokens.glassShadowLight)
        : null;

    final Widget glassDecoration = DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedFill,
        borderRadius: resolvedRadius,
        border: resolvedBorder,
      ),
      child: const SizedBox.expand(),
    );

    final Widget clippedBackdrop = ClipRRect(
      borderRadius: resolvedRadius,
      child: blurSigma > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: glassDecoration,
            )
          : glassDecoration,
    );

    final Widget content =
        padding != null ? Padding(padding: padding!, child: child) : child;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: resolvedShadow,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(child: clippedBackdrop),
          ),
          content,
        ],
      ),
    );
  }
}
