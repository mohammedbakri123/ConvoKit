import 'package:flutter/material.dart';
import '../../../../../../cometchat_uikit_shared.dart';

///[ConvoKitAvatarStyle] is a data class that has styling-related properties
///to customize the appearance of [ConvoKitAvatar]
///``` dart
///ConvoKitAvatarStyle(
/// backgroundColor: Colors.white,
/// border: Border.all(color: Colors.white, width: 0),
/// placeHolderTextStyle: TextStyle(
/// color: Colors.white,
/// fontSize: 20,
/// fontWeight: FontWeight.bold,
/// ),
/// );
/// ```
class ConvoKitAvatarStyle extends ThemeExtension<ConvoKitAvatarStyle> {
  const ConvoKitAvatarStyle({
    this.backgroundColor,
    this.border,
    this.placeHolderTextStyle,
    this.placeHolderTextColor,
    this.borderRadius,
  });

  ///[backgroundColor] background color of the avatar
  final Color? backgroundColor;

  ///[border] border of the avatar
  final Border? border;

  ///[placeHolderTextStyle] place holder text style
  final TextStyle? placeHolderTextStyle;

  ///[placeHolderTextColor] place holder text color
  final Color? placeHolderTextColor;

  ///[borderRadius] border radius of the avatar
  final BorderRadiusGeometry? borderRadius;

  static ConvoKitAvatarStyle of(BuildContext context) =>
      const ConvoKitAvatarStyle();

  @override
  ConvoKitAvatarStyle copyWith({
    Color? backgroundColor,
    Border? border,
    TextStyle? placeHolderTextStyle,
    Color? placeHolderTextColor,
    BorderRadiusGeometry? borderRadius,
  }) {
    return ConvoKitAvatarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      placeHolderTextStyle: placeHolderTextStyle ?? this.placeHolderTextStyle,
      placeHolderTextColor: placeHolderTextColor ?? this.placeHolderTextColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  ConvoKitAvatarStyle merge(ConvoKitAvatarStyle? style) {
    if (style == null) return this;
    return copyWith(
      backgroundColor: style.backgroundColor,
      border: style.border,
      placeHolderTextStyle: style.placeHolderTextStyle,
      placeHolderTextColor: style.placeHolderTextColor,
      borderRadius: style.borderRadius,
    );
  }

  @override
  ConvoKitAvatarStyle lerp(
    ThemeExtension<ConvoKitAvatarStyle>? other,
    double t,
  ) {
    if (other is! ConvoKitAvatarStyle) {
      return this;
    }
    return ConvoKitAvatarStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: Border.lerp(border, other.border, t),
      placeHolderTextStyle: TextStyle.lerp(
        placeHolderTextStyle,
        other.placeHolderTextStyle,
        t,
      ),
      placeHolderTextColor: Color.lerp(
        placeHolderTextColor,
        other.placeHolderTextColor,
        t,
      ),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
    );
  }
}
