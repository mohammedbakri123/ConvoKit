import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

///[ConvoKitBadgeStyle] is a data class that has styling-related properties
///to customize the appearance of [ConvoKitBadge]
///``` dart
///ConvoKitBadgeStyle(
/// textStyle: TextStyle(
/// color: Colors.white,
/// fontSize: 12,
/// fontWeight: FontWeight.bold,
/// ),
/// textColor: Colors.white,
/// backgroundColor: Colors.red,
/// border: Border.all(color: Colors.white, width: 0),
/// );
///```
class ConvoKitBadgeStyle extends ThemeExtension<ConvoKitBadgeStyle> {
  const ConvoKitBadgeStyle({
    this.textStyle,
    this.textColor,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShape,
  });

  ///[textStyle] gives style to count
  final TextStyle? textStyle;

  ///[textColor] text Color of the count
  final Color? textColor;

  ///[backgroundColor] background color of the badge
  final Color? backgroundColor;

  ///[border] border of the badge
  final Border? border;

  ///[borderRadius] border radius of the badge
  final BorderRadiusGeometry? borderRadius;

  ///[boxShape] shape of the badge
  final BoxShape? boxShape;

  static ConvoKitBadgeStyle of(BuildContext context) =>
      const ConvoKitBadgeStyle();

  @override
  ConvoKitBadgeStyle copyWith({
    Color? backgroundColor,
    Border? border,
    TextStyle? textStyle,
    Color? textColor,
    BorderRadiusGeometry? borderRadius,
    BoxShape? boxShape,
  }) {
    return ConvoKitBadgeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      textStyle: textStyle ?? this.textStyle,
      textColor: textColor ?? this.textColor,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShape: boxShape ?? this.boxShape,
    );
  }

  ConvoKitBadgeStyle merge(ConvoKitBadgeStyle? style) {
    if (style == null) return this;
    return copyWith(
      backgroundColor: style.backgroundColor,
      border: style.border,
      textStyle: style.textStyle,
      textColor: style.textColor,
      borderRadius: style.borderRadius,
      boxShape: style.boxShape,
    );
  }

  @override
  ConvoKitBadgeStyle lerp(
    ThemeExtension<ConvoKitBadgeStyle>? other,
    double t,
  ) {
    if (other is! ConvoKitBadgeStyle) {
      return this;
    }
    return ConvoKitBadgeStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: Border.lerp(border, other.border, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      boxShape: t < 0.5 ? boxShape : other.boxShape,
    );
  }
}
