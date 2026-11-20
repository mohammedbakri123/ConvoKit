import 'package:flutter/material.dart';

///[ConvoKitSavedMessagesStyle] contains the styling properties for
///[ConvoKitSavedMessages] — the saved-messages screen.
class ConvoKitSavedMessagesStyle {
  const ConvoKitSavedMessagesStyle({
    this.backgroundColor,
    this.appBarColor,
    this.titleTextStyle,
    this.itemTitleTextStyle,
    this.itemSubtitleTextStyle,
    this.itemContextTextStyle,
    this.itemDateTextStyle,
    this.iconColor,
    this.unsaveIconColor,
    this.separatorColor,
  });

  ///[backgroundColor] background of the screen body
  final Color? backgroundColor;

  ///[appBarColor] background of the app bar
  final Color? appBarColor;

  ///[titleTextStyle] style of the "{n} Saved Messages" title
  final TextStyle? titleTextStyle;

  ///[itemTitleTextStyle] style of each row's sender name
  final TextStyle? itemTitleTextStyle;

  ///[itemSubtitleTextStyle] style of each row's message preview
  final TextStyle? itemSubtitleTextStyle;

  ///[itemContextTextStyle] style of each row's conversation-context line
  final TextStyle? itemContextTextStyle;

  ///[itemDateTextStyle] style of each row's saved-at date
  final TextStyle? itemDateTextStyle;

  ///[iconColor] color of the app-bar icons
  final Color? iconColor;

  ///[unsaveIconColor] color of the icon in the unsave confirmation dialog
  final Color? unsaveIconColor;

  ///[separatorColor] color of the row separators
  final Color? separatorColor;

  ConvoKitSavedMessagesStyle merge(ConvoKitSavedMessagesStyle? other) {
    if (other == null) return this;
    return ConvoKitSavedMessagesStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      appBarColor: other.appBarColor ?? appBarColor,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      itemTitleTextStyle: other.itemTitleTextStyle ?? itemTitleTextStyle,
      itemSubtitleTextStyle:
          other.itemSubtitleTextStyle ?? itemSubtitleTextStyle,
      itemContextTextStyle: other.itemContextTextStyle ?? itemContextTextStyle,
      itemDateTextStyle: other.itemDateTextStyle ?? itemDateTextStyle,
      iconColor: other.iconColor ?? iconColor,
      unsaveIconColor: other.unsaveIconColor ?? unsaveIconColor,
      separatorColor: other.separatorColor ?? separatorColor,
    );
  }
}
