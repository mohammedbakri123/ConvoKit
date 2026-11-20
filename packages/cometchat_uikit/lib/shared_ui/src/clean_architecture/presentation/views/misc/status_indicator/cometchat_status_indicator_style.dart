import '../../../../../../cometchat_uikit_shared.dart';
import 'package:flutter/material.dart';

///[ConvoKitStatusIndicatorStyle] is a data class that has styling-related properties
///to customize the appearance of [ConvoKitStatusIndicator]
///``` dart
///ConvoKitStatusIndicatorStyle(
/// backgroundColor: Colors.white,
/// border: Border.all(color: Colors.white, width: 0),
/// );
/// ```
class ConvoKitStatusIndicatorStyle
    extends ThemeExtension<ConvoKitStatusIndicatorStyle> {
  const ConvoKitStatusIndicatorStyle({
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  ///[backgroundColor] background color of the status indicator
  final Color? backgroundColor;

  ///[border] border of the status indicator
  final Border? border;

  ///[borderRadius] border radius of the status indicator
  final BorderRadiusGeometry? borderRadius;

  static ConvoKitStatusIndicatorStyle of(BuildContext context) =>
      const ConvoKitStatusIndicatorStyle();

  @override
  ConvoKitStatusIndicatorStyle copyWith({
    Color? backgroundColor,
    Border? border,
    BorderRadiusGeometry? borderRadius,
  }) {
    return ConvoKitStatusIndicatorStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  ConvoKitStatusIndicatorStyle merge(ConvoKitStatusIndicatorStyle? style) {
    if (style == null) return this;
    return copyWith(
      backgroundColor: style.backgroundColor,
      border: style.border,
      borderRadius: style.borderRadius,
    );
  }

  @override
  ConvoKitStatusIndicatorStyle lerp(
    ThemeExtension<ConvoKitStatusIndicatorStyle>? other,
    double t,
  ) {
    if (other is! ConvoKitStatusIndicatorStyle) {
      return this;
    }
    return ConvoKitStatusIndicatorStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: Border.lerp(border, other.border, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
    );
  }
}
