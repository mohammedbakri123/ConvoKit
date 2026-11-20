import 'package:flutter/material.dart';

/// [ConvoKitMessageOptionSheetStyle] is a class that holds the styling of the message options sheet.
/// This class is used to set the styling for the message options sheet in the CometChatMessageActionSheet.
/// Use this class to set the styling of the message options sheet.
/// This class provides the following options to customize the message options sheet:
/// ```dart
///  const ConvoKitMessageOptionSheetStyle({
///  this.backgroundColor,
///  this.border,
///  this.borderRadius,
///  this.titleTextStyle,
///  this.titleColor,
///  this.iconColor,
///  });
///  ```
class ConvoKitMessageOptionSheetStyle
    extends ThemeExtension<ConvoKitMessageOptionSheetStyle> {
  const ConvoKitMessageOptionSheetStyle({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.titleTextStyle,
    this.titleColor,
    this.iconColor,
  });

  ///[backgroundColor] background color of the avatar
  final Color? backgroundColor;

  ///[border] border of the avatar
  final Border? border;

  ///[borderRadius] border radius of the avatar
  final BorderRadiusGeometry? borderRadius;

  ///[titleTextStyle] place holder text style
  final TextStyle? titleTextStyle;

  ///[titleColor] place holder text color
  final Color? titleColor;

  ///[iconColor] icon color
  final Color? iconColor;

  static ConvoKitMessageOptionSheetStyle of(BuildContext context) =>
      const ConvoKitMessageOptionSheetStyle();

  @override
  ConvoKitMessageOptionSheetStyle copyWith({
    Color? backgroundColor,
    Border? border,
    BorderRadiusGeometry? borderRadius,
    TextStyle? titleTextStyle,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ConvoKitMessageOptionSheetStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      titleColor: titleColor ?? this.titleColor,
      borderRadius: borderRadius ?? this.borderRadius,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  ConvoKitMessageOptionSheetStyle merge(
    ConvoKitMessageOptionSheetStyle? style,
  ) {
    if (style == null) return this;
    return copyWith(
      backgroundColor: style.backgroundColor,
      border: style.border,
      titleTextStyle: style.titleTextStyle,
      titleColor: style.titleColor,
      borderRadius: style.borderRadius,
      iconColor: style.iconColor,
    );
  }

  @override
  ConvoKitMessageOptionSheetStyle lerp(
    ThemeExtension<ConvoKitMessageOptionSheetStyle>? other,
    double t,
  ) {
    if (other is! ConvoKitMessageOptionSheetStyle) {
      return this;
    }
    return ConvoKitMessageOptionSheetStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: Border.lerp(border, other.border, t),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      titleColor: Color.lerp(titleColor, other.titleColor, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
    );
  }
}
