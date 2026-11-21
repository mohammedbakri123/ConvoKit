import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';
import '../utils/conversation_utils.dart' as conv_utils;
import '../utils/status_indicator_helper.dart';

/// Dedicated widget for displaying a single [ChatConversation] list item.
class ConvoKitConversationListItem extends StatelessWidget {
  const ConvoKitConversationListItem({
    super.key,
    required this.conversation,
    required this.onItemClick,
    this.onItemLongClick,
    this.onSelectionToggle,
    this.isSelected = false,
    this.selectionMode = SelectionMode.none,
    this.hideUserStatus = false,
    this.hideGroupType = false,
    this.hideReceipts = false,
    this.hideThreadIndicator = true,
    this.typingUsers = const [],
    this.userPresence,
    this.loggedInUserId,
    this.hideSeparator = false,
    this.textFormatters,
    this.dateTimeFormatterCallback,
    this.style,
    this.listItemStyle,
    this.avatarStyle,
    this.statusIndicatorStyle,
    this.receiptStyle,
    this.dateStyle,
    this.badgeStyle,
    this.typingIndicatorStyle,
    this.avatarHeight,
    this.avatarWidth,
    this.avatarPadding,
    this.avatarMargin,
    this.statusIndicatorHeight,
    this.statusIndicatorWidth,
    this.statusIndicatorBorderRadius,
    this.datePattern,
    this.datePadding,
    this.dateHeight,
    this.dateWidth,
    this.dateBackgroundIsTransparent,
    this.badgeWidth,
    this.badgeHeight,
    this.badgePadding,
    this.typingIndicatorText,
    this.readIcon,
    this.deliveredIcon,
    this.sentIcon,
    this.privateGroupIcon,
    this.protectedGroupIcon,
    this.leadingView,
    this.titleView,
    this.subtitleView,
    this.trailingView,
  });

  final ChatConversation conversation;
  final void Function(ChatConversation) onItemClick;
  final void Function(ChatConversation)? onItemLongClick;
  final VoidCallback? onSelectionToggle;
  final bool isSelected;
  final SelectionMode selectionMode;
  final bool hideUserStatus;
  final bool hideGroupType;
  final bool hideReceipts;
  final bool hideThreadIndicator;
  final List<ChatUser> typingUsers;
  final UserPresence? userPresence;
  final String? loggedInUserId;
  final bool hideSeparator;
  final List<CometChatTextFormatter>? textFormatters;
  final DateTimeFormatterCallback? dateTimeFormatterCallback;
  final ConvoKitConversationListItemStyle? style;
  final ListItemStyle? listItemStyle;
  final ConvoKitAvatarStyle? avatarStyle;
  final ConvoKitStatusIndicatorStyle? statusIndicatorStyle;
  final CometChatMessageReceiptStyle? receiptStyle;
  final ConvoKitDateStyle? dateStyle;
  final ConvoKitBadgeStyle? badgeStyle;
  final CometChatTypingIndicatorStyle? typingIndicatorStyle;
  final double? avatarHeight;
  final double? avatarWidth;
  final EdgeInsetsGeometry? avatarPadding;
  final EdgeInsetsGeometry? avatarMargin;
  final double? statusIndicatorHeight;
  final double? statusIndicatorWidth;
  final BorderRadiusGeometry? statusIndicatorBorderRadius;
  final String Function(ChatConversation)? datePattern;
  final EdgeInsets? datePadding;
  final double? dateHeight;
  final double? dateWidth;
  final bool? dateBackgroundIsTransparent;
  final double? badgeWidth;
  final double? badgeHeight;
  final EdgeInsetsGeometry? badgePadding;
  final String? typingIndicatorText;
  final Widget? readIcon;
  final Widget? deliveredIcon;
  final Widget? sentIcon;
  final Widget? privateGroupIcon;
  final Widget? protectedGroupIcon;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      leadingView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      titleView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      subtitleView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      trailingView;

  @override
  Widget build(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);

    final title = conv_utils.ConversationUtils.getConversationTitle(conversation);
    final avatarUrl =
        conv_utils.ConversationUtils.getConversationAvatar(conversation);

    final statusConfig = StatusIndicatorHelper.getStatusIndicator(
      conversation: conversation,
      hideUserStatus: hideUserStatus,
      hideGroupType: hideGroupType,
      presenceOverride: userPresence,
    );

    final conversationsStyle = ConvoKitConversationsStyle(
      badgeStyle: badgeStyle ?? style?.badgeStyle,
      itemSubtitleTextStyle: style?.subtitleTextStyle,
      titleTextStyle: style?.titleTextStyle,
    );

    final leading = leadingView?.call(context, conversation) ??
        Stack(
          clipBehavior: Clip.none,
          children: [
            ConvoKitAvatar(
              image: avatarUrl,
              name: title,
              width: avatarWidth ?? 48,
              height: avatarHeight ?? 48,
              style: avatarStyle ?? style?.avatarStyle ?? const ConvoKitAvatarStyle(),
            ),
            if (statusConfig.show)
              Positioned(
                right: 0,
                bottom: 0,
                child: ConvoKitStatusIndicator(
                  height: statusIndicatorHeight ?? 14,
                  width: statusIndicatorWidth ?? 14,
                  style: (statusIndicatorStyle ??
                          style?.statusIndicatorStyle ??
                          const ConvoKitStatusIndicatorStyle())
                      .copyWith(
                    backgroundColor: statusConfig.color ?? colorPalette.success,
                  ),
                  backgroundImage: statusConfig.icon ??
                      (conversation.group?.type == GroupType.private
                          ? privateGroupIcon
                          : null),
                ),
              ),
          ],
        );

    final titleWidget = titleView?.call(context, conversation) ??
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: style?.titleTextColor ?? colorPalette.textPrimary,
            fontSize: typography.heading4?.medium?.fontSize ?? 16,
            fontWeight: typography.heading4?.medium?.fontWeight ?? FontWeight.w500,
            fontFamily: typography.heading4?.medium?.fontFamily,
          ).merge(style?.titleTextStyle),
        );

    final subtitleWidget = subtitleView?.call(context, conversation) ??
        ConversationsSubtitleView(
          conversation: conversation,
          typingUsers: typingUsers,
          loggedInUserId: loggedInUserId,
          style: conversationsStyle,
          receiptStyle: receiptStyle ??
              style?.receiptStyle ??
              CometChatMessageReceiptStyle(),
          typingStyle: typingIndicatorStyle ??
              style?.typingIndicatorStyle ??
              CometChatTypingIndicatorStyle(),
          colorPalette: colorPalette,
          spacing: spacing,
          typography: typography,
          hideThreadIndicator: hideThreadIndicator,
          receiptsVisibility: !hideReceipts,
          typingIndicatorText: typingIndicatorText,
          readIcon: readIcon,
          deliveredIcon: deliveredIcon,
          sentIcon: sentIcon,
          textFormatters: textFormatters,
        );

    final trailingWidget = trailingView?.call(context, conversation) ??
        ConversationsTrailingView(
          conversation: conversation,
          style: conversationsStyle,
          datesStyle: dateStyle ?? style?.dateStyle ?? const ConvoKitDateStyle(),
          colorPalette: colorPalette,
          spacing: spacing,
          typography: typography,
          datePattern: datePattern,
          datePadding: datePadding,
          dateHeight: dateHeight,
          dateWidth: dateWidth,
          dateBackgroundIsTransparent: dateBackgroundIsTransparent,
          badgeWidth: badgeWidth,
          badgeHeight: badgeHeight,
          badgePadding: badgePadding,
          dateTimeFormatterCallback: dateTimeFormatterCallback,
        );

    final itemContent = InkWell(
      onTap: () {
        if (selectionMode != SelectionMode.none && onSelectionToggle != null) {
          onSelectionToggle!();
        } else {
          onItemClick(conversation);
        }
      },
      onLongPress: onItemLongClick != null
          ? () => onItemLongClick!(conversation)
          : null,
      child: Container(
        color: isSelected
            ? (style?.selectedBackgroundColor ??
                colorPalette.background3 ??
                Colors.grey.shade200)
            : (style?.backgroundColor ?? listItemStyle?.background),
        padding: listItemStyle?.padding ??
            EdgeInsets.symmetric(
              horizontal: spacing.padding4 ?? 16,
              vertical: spacing.padding3 ?? 12,
            ),
        child: Row(
          children: [
            if (selectionMode != SelectionMode.none) ...[
              Checkbox(
                value: isSelected,
                onChanged: (_) => onSelectionToggle?.call(),
              ),
              SizedBox(width: spacing.padding2 ?? 8),
            ],
            leading,
            SizedBox(width: spacing.padding3 ?? 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  titleWidget,
                  const SizedBox(height: 4),
                  subtitleWidget,
                ],
              ),
            ),
            trailingWidget,
          ],
        ),
      ),
    );

    if (hideSeparator) {
      return itemContent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        itemContent,
        Divider(
          height: 1,
          thickness: 1,
          color: listItemStyle?.separatorColor ??
              style?.separatorColor ??
              colorPalette.borderLight ??
              Colors.grey.shade200,
        ),
      ],
    );
  }
}
