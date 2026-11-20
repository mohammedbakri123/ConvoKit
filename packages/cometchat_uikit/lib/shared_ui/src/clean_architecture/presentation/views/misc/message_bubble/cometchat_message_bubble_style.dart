import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

///[ConvoKitMessageBubbleStyle] is a data class that has styling-related properties
///to customize the appearance of [ConvoKitMessageBubble]
///
/// ```dart
/// ConvoKitMessageBubbleStyle(
/// backgroundImage: DecorationImage(),
/// backgroundColor: Colors.white,
/// border: Border.all(color: Colors.red),
/// borderRadius: BorderRadius.circular(10),
/// )
/// ```
class ConvoKitMessageBubbleStyle
    extends ThemeExtension<ConvoKitMessageBubbleStyle> {
  ///[ConvoKitMessageBubbleStyle] constructor requires `width`, `height`, `background`, [border], [borderRadius], `gradient` and `padding` while initializing.
  const ConvoKitMessageBubbleStyle({
    this.backgroundImage,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  ///[backgroundImage] provides background image to the message bubble
  final DecorationImage? backgroundImage;

  ///[backgroundColor] provides background color to the message bubble
  final Color? backgroundColor;

  ///[border] provides border to the message bubble
  final BoxBorder? border;

  ///[borderRadius] provides border radius to the message bubble
  final BorderRadiusGeometry? borderRadius;

  @override
  ConvoKitMessageBubbleStyle copyWith({
    DecorationImage? messageBubbleBackgroundImage,
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    double? widthFlex,
    EdgeInsets? contentPadding,
  }) {
    return ConvoKitMessageBubbleStyle(
      backgroundImage: messageBubbleBackgroundImage ?? backgroundImage,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  ConvoKitMessageBubbleStyle lerp(
    ConvoKitMessageBubbleStyle? other,
    double t,
  ) {
    if (other == null) return this;
    return ConvoKitMessageBubbleStyle(
      backgroundImage: other.backgroundImage ?? backgroundImage,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: BoxBorder.lerp(border, other.border, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
    );
  }

  static ConvoKitMessageBubbleStyle of(BuildContext context) =>
      const ConvoKitMessageBubbleStyle();

  ConvoKitMessageBubbleStyle merge(ConvoKitMessageBubbleStyle? style) {
    if (style == null) return this;
    return copyWith(
      messageBubbleBackgroundImage: style.backgroundImage,
      backgroundColor: style.backgroundColor,
      border: style.border,
      borderRadius: style.borderRadius,
    );
  }
}
