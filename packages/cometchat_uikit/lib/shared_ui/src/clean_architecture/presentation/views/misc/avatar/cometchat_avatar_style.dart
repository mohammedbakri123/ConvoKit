import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

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
    this.monogramPalette,
    this.backgroundGradient,
    this.boxShadow,
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

  ///[monogramPalette] optional palette used to deterministically assign a
  ///background color from the avatar's name when no image is provided.
  final List<Color>? monogramPalette;

  ///[backgroundGradient] optional gradient painted behind the avatar content.
  final Gradient? backgroundGradient;

  ///[boxShadow] optional elevation shadows around the avatar container.
  final List<BoxShadow>? boxShadow;

  static ConvoKitAvatarStyle of(BuildContext context) =>
      const ConvoKitAvatarStyle();

  @override
  ConvoKitAvatarStyle copyWith({
    Color? backgroundColor,
    Border? border,
    TextStyle? placeHolderTextStyle,
    Color? placeHolderTextColor,
    BorderRadiusGeometry? borderRadius,
    List<Color>? monogramPalette,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadow,
  }) {
    return ConvoKitAvatarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      placeHolderTextStyle: placeHolderTextStyle ?? this.placeHolderTextStyle,
      placeHolderTextColor: placeHolderTextColor ?? this.placeHolderTextColor,
      borderRadius: borderRadius ?? this.borderRadius,
      monogramPalette: monogramPalette ?? this.monogramPalette,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      boxShadow: boxShadow ?? this.boxShadow,
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
      monogramPalette: style.monogramPalette,
      backgroundGradient: style.backgroundGradient,
      boxShadow: style.boxShadow,
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
      monogramPalette: _lerpColorList(
        monogramPalette,
        other.monogramPalette,
        t,
      ),
      backgroundGradient: Gradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      ),
      boxShadow: BoxShadow.lerpList(boxShadow, other.boxShadow, t),
    );
  }

  static List<Color>? _lerpColorList(
    List<Color>? a,
    List<Color>? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return t < 0.5 ? null : b;
    if (b == null) return t < 0.5 ? a : null;
    if (a.length != b.length) return t < 0.5 ? a : b;
    return List<Color>.generate(
      a.length,
      (index) => Color.lerp(a[index], b[index], t) ?? a[index],
    );
  }
}
