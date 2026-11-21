import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';

/// A widget that displays the trailing area for a conversation list item:
/// timestamp of the last message/update and unread message count badge.
class ConversationsTrailingView extends StatelessWidget {
  const ConversationsTrailingView({
    super.key,
    required this.conversation,
    required this.style,
    required this.datesStyle,
    required this.colorPalette,
    required this.spacing,
    required this.typography,
    this.datePattern,
    this.datePadding,
    this.dateHeight,
    this.dateWidth,
    this.dateBackgroundIsTransparent,
    this.badgeWidth,
    this.badgeHeight,
    this.badgePadding,
    this.dateTimeFormatterCallback,
  });

  final ChatConversation conversation;
  final ConvoKitConversationsStyle style;
  final ConvoKitDateStyle datesStyle;
  final ConvoKitColorPalette colorPalette;
  final ConvoKitSpacing spacing;
  final ConvoKitTypography typography;
  final String Function(ChatConversation)? datePattern;
  final EdgeInsets? datePadding;
  final double? dateHeight;
  final double? dateWidth;
  final bool? dateBackgroundIsTransparent;
  final double? badgeWidth;
  final double? badgeHeight;
  final EdgeInsetsGeometry? badgePadding;
  final DateTimeFormatterCallback? dateTimeFormatterCallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: spacing.padding2 ?? 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _getTime(context)),
          const SizedBox(height: 6.5),
          Flexible(child: _getUnreadCount(context)),
        ],
      ),
    );
  }

  Widget _getTime(BuildContext context) {
    final lastMessageTime =
        conversation.lastMessage?.serverCreatedAt ??
        conversation.lastMessage?.createdAt ??
        conversation.updatedAt;

    final customDateString = datePattern?.call(conversation);

    return ConvoKitDate(
      date: lastMessageTime,
      padding: datePadding ?? EdgeInsets.zero,
      height: dateHeight,
      isTransparentBackground: dateBackgroundIsTransparent,
      width: dateWidth,
      style: ConvoKitDateStyle(
        backgroundColor: datesStyle.backgroundColor ?? colorPalette.transparent,
        textStyle: TextStyle(
          color: datesStyle.textColor ?? colorPalette.textSecondary,
          fontSize: typography.caption1?.regular?.fontSize,
          fontWeight: typography.caption1?.regular?.fontWeight,
          fontFamily: typography.caption1?.regular?.fontFamily,
        ).merge(datesStyle.textStyle).copyWith(color: datesStyle.textColor),
        border:
            datesStyle.border ??
            Border.all(width: 0, color: Colors.transparent),
        borderRadius: datesStyle.borderRadius,
        textColor: datesStyle.textColor,
      ),
      customDateString: customDateString,
      pattern: DateTimePattern.dayDateTimeFormat,
      dateTimeFormatterCallback: dateTimeFormatterCallback,
    );
  }

  Widget _getUnreadCount(BuildContext context) {
    return ConvoKitBadge(
      count: conversation.unreadCount,
      width: badgeWidth,
      height: badgeHeight ?? 20,
      style: style.badgeStyle ?? const ConvoKitBadgeStyle(),
      padding: badgePadding,
    );
  }
}
