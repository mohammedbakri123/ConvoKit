import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

///[ConvoKitDeletedBubbleStyle] is a data class that has styling-related properties
///to customize the appearance of [ConvoKitDeletedBubble]
///
/// ```dart
/// ConvoKitDeletedBubbleStyle(
///      textStyle: TextStyle(),
///      backgroundColor: Colors.white,
///      border: Border.all(color: Colors.red),
///      borderRadius: BorderRadius.circular(10),
///      iconColor: Colors.red,
///      textColor: Colors.red,
/// );
/// ```
class ConvoKitDeletedBubbleStyle
    extends ThemeExtension<ConvoKitDeletedBubbleStyle> {
  const ConvoKitDeletedBubbleStyle({
    this.textStyle,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.iconColor,
    this.textColor,
    this.messageBubbleAvatarStyle,
    this.messageBubbleDateStyle,
    this.messageBubbleBackgroundImage,
    this.threadedMessageIndicatorTextStyle,
    this.threadedMessageIndicatorIconColor,
    this.senderNameTextStyle,
    this.messageReceiptStyle,
  });

  ///[textStyle] delete message bubble text style
  final TextStyle? textStyle;

  ///[iconColor] delete message bubble icon color
  final Color? iconColor;

  ///[textColor] delete message bubble text color
  final Color? textColor;

  ///[backgroundColor] background color of group action message
  final Color? backgroundColor;

  ///[border] border of group action message
  final BoxBorder? border;

  ///[borderRadius] border radius of message bubble
  final BorderRadiusGeometry? borderRadius;

  ///[messageBubbleAvatarStyle] provides style to the avatar of the sender
  final ConvoKitAvatarStyle? messageBubbleAvatarStyle;

  ///[messageBubbleDateStyle] provides style to the date of the message bubble
  final ConvoKitDateStyle? messageBubbleDateStyle;

  ///[messageBubbleBackgroundImage] provides background image to the message bubble of the sent message
  final DecorationImage? messageBubbleBackgroundImage;

  ///[threadedMessageIndicatorTextStyle] provides text style to the threaded message indicator
  final TextStyle? threadedMessageIndicatorTextStyle;

  ///[threadedMessageIndicatorIconColor] provides color to the threaded message icon
  final Color? threadedMessageIndicatorIconColor;

  ///[senderNameTextStyle] provides style to the sender name of the message
  final TextStyle? senderNameTextStyle;

  ///[messageReceiptStyle] provides style to the message receipt
  final CometChatMessageReceiptStyle? messageReceiptStyle;

  @override
  ConvoKitDeletedBubbleStyle copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    Color? iconColor,
    Color? textColor,
    ConvoKitAvatarStyle? messageBubbleAvatarStyle,
    ConvoKitDateStyle? messageBubbleDateStyle,
    DecorationImage? messageBubbleBackgroundImage,
    TextStyle? threadedMessageIndicatorTextStyle,
    Color? threadedMessageIndicatorIconColor,
    TextStyle? senderNameTextStyle,
    CometChatMessageReceiptStyle? messageReceiptStyle,
  }) {
    return ConvoKitDeletedBubbleStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      messageBubbleAvatarStyle:
          messageBubbleAvatarStyle ?? this.messageBubbleAvatarStyle,
      messageBubbleDateStyle:
          messageBubbleDateStyle ?? this.messageBubbleDateStyle,
      messageBubbleBackgroundImage:
          messageBubbleBackgroundImage ?? this.messageBubbleBackgroundImage,
      threadedMessageIndicatorTextStyle:
          threadedMessageIndicatorTextStyle ??
          this.threadedMessageIndicatorTextStyle,
      threadedMessageIndicatorIconColor:
          threadedMessageIndicatorIconColor ??
          this.threadedMessageIndicatorIconColor,
      senderNameTextStyle: senderNameTextStyle ?? this.senderNameTextStyle,
      messageReceiptStyle: messageReceiptStyle ?? this.messageReceiptStyle,
    );
  }

  ConvoKitDeletedBubbleStyle merge(
    covariant ConvoKitDeletedBubbleStyle? other,
  ) {
    if (other == null) return this;
    return copyWith(
      textStyle: other.textStyle,
      backgroundColor: other.backgroundColor,
      border: other.border,
      borderRadius: other.borderRadius,
      iconColor: other.iconColor,
      textColor: other.textColor,
      messageBubbleAvatarStyle: other.messageBubbleAvatarStyle,
      messageBubbleDateStyle: other.messageBubbleDateStyle,
      messageBubbleBackgroundImage: other.messageBubbleBackgroundImage,
      threadedMessageIndicatorTextStyle:
          other.threadedMessageIndicatorTextStyle,
      threadedMessageIndicatorIconColor:
          other.threadedMessageIndicatorIconColor,
      senderNameTextStyle: other.senderNameTextStyle,
      messageReceiptStyle: other.messageReceiptStyle,
    );
  }

  static ConvoKitDeletedBubbleStyle of(BuildContext context) =>
      const ConvoKitDeletedBubbleStyle();

  @override
  ConvoKitDeletedBubbleStyle lerp(
    ConvoKitDeletedBubbleStyle? other,
    double t,
  ) {
    if (other == null) return this;
    return ConvoKitDeletedBubbleStyle(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      border: BoxBorder.lerp(border, other.border, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      messageBubbleAvatarStyle: messageBubbleAvatarStyle?.lerp(
        other.messageBubbleAvatarStyle,
        t,
      ),
      messageBubbleDateStyle: messageBubbleDateStyle?.lerp(
        other.messageBubbleDateStyle,
        t,
      ),
      messageBubbleBackgroundImage: DecorationImage.lerp(
        messageBubbleBackgroundImage,
        other.messageBubbleBackgroundImage,
        t,
      ),
      threadedMessageIndicatorTextStyle: TextStyle.lerp(
        threadedMessageIndicatorTextStyle,
        other.threadedMessageIndicatorTextStyle,
        t,
      ),
      threadedMessageIndicatorIconColor: Color.lerp(
        threadedMessageIndicatorIconColor,
        other.threadedMessageIndicatorIconColor,
        t,
      ),
      senderNameTextStyle: TextStyle.lerp(
        senderNameTextStyle,
        other.senderNameTextStyle,
        t,
      ),
      messageReceiptStyle: messageReceiptStyle?.lerp(
        other.messageReceiptStyle,
        t,
      ),
    );
  }
}
