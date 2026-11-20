import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

class ConvoKitSuggestionListStyle
    extends ThemeExtension<ConvoKitSuggestionListStyle> {
  const ConvoKitSuggestionListStyle({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.textStyle,
    this.textColor,
    this.avatarStyle,
  });

  ///[backgroundColor] sets the background color of the message composer
  final Color? backgroundColor;

  ///[border] sets the border of the message composer
  final BoxBorder? border;

  ///[borderRadius] sets the border radius of the message composer
  final BorderRadius? borderRadius;

  ///[textStyle] sets the text style of the suggestion list
  final TextStyle? textStyle;

  ///[textColor] sets the text color of the suggestion list
  final Color? textColor;

  ///[avatarStyle] sets the avatar style of the suggestion list
  final ConvoKitAvatarStyle? avatarStyle;

  ConvoKitSuggestionListStyle merge(ConvoKitSuggestionListStyle? style) {
    return ConvoKitSuggestionListStyle(
      backgroundColor: style?.backgroundColor ?? backgroundColor,
      border: style?.border ?? border,
      borderRadius: style?.borderRadius ?? borderRadius,
      textStyle: style?.textStyle ?? textStyle,
      textColor: style?.textColor ?? textColor,
      avatarStyle: style?.avatarStyle ?? avatarStyle,
    );
  }

  @override
  ConvoKitSuggestionListStyle copyWith({
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    Color? textColor,
    ConvoKitAvatarStyle? messageBubbleAvatarStyle,
  }) {
    return ConvoKitSuggestionListStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      textStyle: textStyle ?? this.textStyle,
      textColor: textColor ?? this.textColor,
      avatarStyle: messageBubbleAvatarStyle ?? avatarStyle,
    );
  }

  @override
  ConvoKitSuggestionListStyle lerp(
    ConvoKitSuggestionListStyle? other,
    double t,
  ) {
    return ConvoKitSuggestionListStyle(
      backgroundColor: Color.lerp(backgroundColor, other?.backgroundColor, t),
      border: BoxBorder.lerp(border, other?.border, t),
      borderRadius: BorderRadius.lerp(borderRadius, other?.borderRadius, t),
      textStyle: TextStyle.lerp(textStyle, other?.textStyle, t),
      textColor: Color.lerp(textColor, other?.textColor, t),
      avatarStyle: other?.avatarStyle ?? avatarStyle,
    );
  }

  static ConvoKitSuggestionListStyle of(BuildContext context) =>
      const ConvoKitSuggestionListStyle();
}
