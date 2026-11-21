import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';

/// Displays a list of [ChatConversation] items with loading, empty, error,
/// and paginated states without depending on `flutter_bloc`.
class ConversationsList extends StatelessWidget {
  const ConversationsList({
    super.key,
    required this.conversations,
    required this.isLoading,
    required this.style,
    required this.statusStyle,
    required this.typingStyle,
    required this.receiptStyle,
    required this.datesStyle,
    required this.colorPalette,
    required this.spacing,
    required this.typography,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.typingUsersByConversation = const {},
    this.presenceByUserId = const {},
    this.loggedInUserId,
    this.selectedIds = const {},
    this.onLoadMore,
    this.onRetry,
    this.onSelectionToggle,
    this.scrollController,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.hideError,
    this.listItemView,
    this.subtitleView,
    this.trailingView,
    this.leadingView,
    this.titleView,
    this.avatarHeight,
    this.avatarWidth,
    this.avatarPadding,
    this.avatarMargin,
    this.statusIndicatorHeight,
    this.statusIndicatorWidth,
    this.statusIndicatorBorderRadius,
    this.privateGroupIcon,
    this.protectedGroupIcon,
    this.usersStatusVisibility,
    this.groupTypeVisibility,
    this.selectionMode,
    this.activateSelection,
    this.onItemTap,
    this.onItemLongPress,
    this.hideThreadIndicator,
    this.receiptsVisibility,
    this.typingIndicatorText,
    this.readIcon,
    this.deliveredIcon,
    this.sentIcon,
    this.textFormatters,
    this.datePattern,
    this.datePadding,
    this.dateHeight,
    this.dateWidth,
    this.dateBackgroundIsTransparent,
    this.badgeWidth,
    this.badgeHeight,
    this.badgePadding,
    this.dateTimeFormatterCallback,
    this.itemWrapperBuilder,
    this.listItemStyle,
    this.listPadding,
  });

  final List<ChatConversation> conversations;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ChatError? error;
  final Map<String, List<ChatUser>> typingUsersByConversation;
  final Map<String, UserPresence> presenceByUserId;
  final String? loggedInUserId;
  final Set<String> selectedIds;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(ChatConversation)? onSelectionToggle;

  final ConvoKitConversationsStyle style;
  final ConvoKitStatusIndicatorStyle statusStyle;
  final CometChatTypingIndicatorStyle typingStyle;
  final CometChatMessageReceiptStyle receiptStyle;
  final ConvoKitDateStyle datesStyle;
  final ConvoKitColorPalette colorPalette;
  final ConvoKitSpacing spacing;
  final ConvoKitTypography typography;
  final ScrollController? scrollController;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final bool? hideError;
  final Widget Function(ChatConversation)? listItemView;
  final Widget? Function(BuildContext, ChatConversation)? subtitleView;
  final Widget? Function(BuildContext, ChatConversation)? trailingView;
  final Widget? Function(BuildContext, ChatConversation)? leadingView;
  final Widget? Function(BuildContext, ChatConversation)? titleView;
  final double? avatarHeight;
  final double? avatarWidth;
  final EdgeInsetsGeometry? avatarPadding;
  final EdgeInsetsGeometry? avatarMargin;
  final double? statusIndicatorHeight;
  final double? statusIndicatorWidth;
  final BorderRadiusGeometry? statusIndicatorBorderRadius;
  final Widget? privateGroupIcon;
  final Widget? protectedGroupIcon;
  final bool? usersStatusVisibility;
  final bool? groupTypeVisibility;
  final SelectionMode? selectionMode;
  final ActivateSelection? activateSelection;
  final void Function(ChatConversation)? onItemTap;
  final void Function(ChatConversation)? onItemLongPress;
  final bool? hideThreadIndicator;
  final bool? receiptsVisibility;
  final String? typingIndicatorText;
  final Widget? readIcon;
  final Widget? deliveredIcon;
  final Widget? sentIcon;
  final List<CometChatTextFormatter>? textFormatters;
  final String Function(ChatConversation)? datePattern;
  final EdgeInsets? datePadding;
  final double? dateHeight;
  final double? dateWidth;
  final bool? dateBackgroundIsTransparent;
  final double? badgeWidth;
  final double? badgeHeight;
  final EdgeInsetsGeometry? badgePadding;
  final DateTimeFormatterCallback? dateTimeFormatterCallback;
  final Widget Function(BuildContext, ChatConversation, Widget)?
      itemWrapperBuilder;
  final ListItemStyle? listItemStyle;
  final EdgeInsetsGeometry? listPadding;

  @override
  Widget build(BuildContext context) {
    if (isLoading && conversations.isEmpty) {
      return loadingStateView?.call(context) ??
          ConversationsLoadingView(
            colorPalette: colorPalette,
            spacing: spacing,
            typography: typography,
          );
    }

    if (error != null && conversations.isEmpty) {
      if (hideError == true) {
        return const SizedBox.shrink();
      }
      return errorStateView?.call(context) ??
          ConversationsErrorView(
            errorMessage: error!.message,
            style: style,
            colorPalette: colorPalette,
            spacing: spacing,
            typography: typography,
          );
    }

    if (conversations.isEmpty) {
      return emptyStateView?.call(context) ??
          ConversationsEmptyView(
            style: style,
            colorPalette: colorPalette,
            spacing: spacing,
            typography: typography,
          );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            !isLoadingMore &&
            onLoadMore != null &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: listPadding,
        itemCount: conversations.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= conversations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final conversation = conversations[index];
          final isLast = index == conversations.length - 1;
          final peerId = conversation.peer?.id;
          final presence = peerId != null ? presenceByUserId[peerId] : null;
          final typingUsers =
              typingUsersByConversation[conversation.id] ?? const [];

          Widget itemWidget = listItemView != null
              ? listItemView!(conversation)
              : ConvoKitConversationListItem(
                  conversation: conversation,
                  onItemClick: (c) => onItemTap?.call(c),
                  onItemLongClick: onItemLongPress,
                  onSelectionToggle: onSelectionToggle != null
                      ? () => onSelectionToggle!(conversation)
                      : null,
                  isSelected: selectedIds.contains(conversation.id),
                  selectionMode: selectionMode ?? SelectionMode.none,
                  hideUserStatus: !(usersStatusVisibility ?? true),
                  hideGroupType: !(groupTypeVisibility ?? true),
                  hideReceipts: !(receiptsVisibility ?? true),
                  hideThreadIndicator: hideThreadIndicator ?? true,
                  typingUsers: typingUsers,
                  userPresence: presence,
                  loggedInUserId: loggedInUserId,
                  hideSeparator: isLast,
                  textFormatters: textFormatters,
                  dateTimeFormatterCallback: dateTimeFormatterCallback,
                  listItemStyle: listItemStyle,
                  avatarStyle: style.avatarStyle,
                  statusIndicatorStyle: statusStyle,
                  receiptStyle: receiptStyle,
                  dateStyle: datesStyle,
                  badgeStyle: style.badgeStyle,
                  typingIndicatorStyle: typingStyle,
                  avatarHeight: avatarHeight,
                  avatarWidth: avatarWidth,
                  avatarPadding: avatarPadding,
                  avatarMargin: avatarMargin,
                  statusIndicatorHeight: statusIndicatorHeight,
                  statusIndicatorWidth: statusIndicatorWidth,
                  statusIndicatorBorderRadius: statusIndicatorBorderRadius,
                  datePattern: datePattern,
                  datePadding: datePadding,
                  dateHeight: dateHeight,
                  dateWidth: dateWidth,
                  dateBackgroundIsTransparent: dateBackgroundIsTransparent,
                  badgeWidth: badgeWidth,
                  badgeHeight: badgeHeight,
                  badgePadding: badgePadding,
                  typingIndicatorText: typingIndicatorText,
                  readIcon: readIcon,
                  deliveredIcon: deliveredIcon,
                  sentIcon: sentIcon,
                  privateGroupIcon: privateGroupIcon,
                  protectedGroupIcon: protectedGroupIcon,
                  leadingView: leadingView,
                  titleView: titleView,
                  subtitleView: subtitleView,
                  trailingView: trailingView,
                );

          if (itemWrapperBuilder != null) {
            itemWidget = itemWrapperBuilder!(context, conversation, itemWidget);
          }

          return itemWidget;
        },
      ),
    );
  }
}
