import 'package:flutter/material.dart';

///[ConvoKitActionBubbleStyle] is a data class that has styling-related properties
///to customize the appearance of group action message bubble
///
/// ```dart
/// ConvoKitActionBubbleStyle(
/// textStyle: TextStyle(),
/// backgroundColor: Colors.white,
/// border: Border.all(color: Colors.red),
/// borderRadius: BorderRadius.circular(10),
/// );
/// ```
class ConvoKitActionBubbleStyle
    extends ThemeExtension<ConvoKitActionBubbleStyle> {
  const ConvoKitActionBubbleStyle({
    this.textStyle,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  ///[textStyle] text style of group action message
  final TextStyle? textStyle;

  ///[backgroundColor] background color of group action message
  final Color? backgroundColor;

  ///[border] border of group action message
  final BoxBorder? border;

  ///[borderRadius] border radius of group action message
  final BorderRadiusGeometry? borderRadius;

  @override
  ConvoKitActionBubbleStyle copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
  }) {
    return ConvoKitActionBubbleStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  ConvoKitActionBubbleStyle merge(
    covariant ConvoKitActionBubbleStyle? other,
  ) {
    if (other == null) return this;
    return copyWith(
      textStyle: other.textStyle,
      backgroundColor: other.backgroundColor,
      border: other.border,
      borderRadius: other.borderRadius,
    );
  }

  static ConvoKitActionBubbleStyle of(BuildContext context) =>
      const ConvoKitActionBubbleStyle();

  @override
  ConvoKitActionBubbleStyle lerp(ConvoKitActionBubbleStyle? other, double t) {
    if (other == null) return this;
    return ConvoKitActionBubbleStyle(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: BoxBorder.lerp(border, other.border, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
    );
  }
}
