import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';
import '../../shared/list_options_menu.dart';

/// Stateless widget for rendering the users list from [ConvoKitUsers].
class UsersList extends StatelessWidget {
  const UsersList({
    super.key,
    required this.users,
    required this.style,
    required this.colorPalette,
    required this.spacing,
    required this.typography,
    this.isLoading = false,
    this.isEmpty = false,
    this.error,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedUserIds = const <String>{},
    this.presenceMap = const <String, UserPresence>{},
    this.onLoadMore,
    this.onRetry,
    this.onToggleSelection,
    this.scrollController,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.listItemView,
    this.subtitleView,
    this.trailingView,
    this.leadingView,
    this.titleView,
    this.usersStatusVisibility,
    this.selectionMode,
    this.activateSelection,
    this.onItemTap,
    this.onItemLongPress,
    this.options,
    this.stickyHeaderVisibility,
    this.avatarStyle,
    this.statusIndicatorStyle,
    this.listPadding,
  });

  final List<ChatUser> users;
  final bool isLoading;
  final bool isEmpty;
  final ChatError? error;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<String> selectedUserIds;
  final Map<String, UserPresence> presenceMap;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(String userId)? onToggleSelection;

  final ConvoKitUsersStyle style;
  final ConvoKitColorPalette colorPalette;
  final ConvoKitSpacing spacing;
  final ConvoKitTypography typography;
  final ScrollController? scrollController;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final Widget Function(ChatUser)? listItemView;
  final Widget? Function(BuildContext, ChatUser)? subtitleView;
  final Widget? Function(BuildContext, ChatUser)? trailingView;
  final Widget? Function(BuildContext, ChatUser)? leadingView;
  final Widget? Function(BuildContext, ChatUser)? titleView;
  final bool? usersStatusVisibility;
  final SelectionMode? selectionMode;
  final ActivateSelection? activateSelection;
  final Function(BuildContext, ChatUser)? onItemTap;
  final Function(BuildContext, ChatUser)? onItemLongPress;

  /// Builds the menu a long press opens on a user. Nothing opens when it is
  /// null or returns no options. Starting a long-press selection comes first,
  /// then [onItemLongPress], when set, takes the long press instead.
  final List<CometChatOption> Function(BuildContext context, ChatUser user)?
  options;

  final bool? stickyHeaderVisibility;
  final ConvoKitAvatarStyle? avatarStyle;
  final ConvoKitStatusIndicatorStyle? statusIndicatorStyle;
  final EdgeInsetsGeometry? listPadding;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _buildErrorState(context);
    }
    if (isLoading) {
      return _buildLoadingState(context);
    }
    if (isEmpty || users.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildUsersList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    if (loadingStateView != null) {
      return Center(child: loadingStateView!(context));
    }
    return ConvoKitShimmerEffect(
      colorPalette: colorPalette,
      child: ListView.builder(
        itemCount: 20,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.padding4 ?? 0,
              vertical: spacing.padding3 ?? 0,
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: spacing.padding3 ?? 0),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                  ),
                ),
                Container(
                  height: 22.0,
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(spacing.radius2 ?? 0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyStateView != null) {
      return Center(child: emptyStateView!(context));
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: spacing.padding5 ?? 0),
              child: Image.asset(
                AssetConstants(
                  ConvoKitThemeHelper.getBrightness(context),
                ).emptyUserList,
                package: UIConstants.packageName,
                width: 120,
                height: 120,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: spacing.padding1 ?? 0),
              child: Text(
                Translations.of(context).usersUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.emptyStateTextColor ?? colorPalette.textPrimary,
                  fontSize: typography.heading3?.bold?.fontSize,
                  fontWeight: typography.heading3?.bold?.fontWeight,
                  fontFamily: typography.heading3?.bold?.fontFamily,
                ).merge(style.emptyStateTextStyle),
              ),
            ),
            Text(
              Translations.of(context).addContactsToStartConversations,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    style.emptyStateSubTitleTextColor ??
                    colorPalette.textSecondary,
                fontSize: typography.body?.regular?.fontSize,
                fontWeight: typography.body?.regular?.fontWeight,
                fontFamily: typography.body?.regular?.fontFamily,
              ).merge(style.emptyStateSubTitleTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    if (errorStateView != null) {
      return Center(child: errorStateView!(context));
    }
    return UIStateUtils.getDefaultErrorStateView(
      context,
      colorPalette,
      typography,
      spacing,
      () => onRetry?.call(),
      errorStateTextColor: style.errorStateTextColor,
      errorStateTextStyle: style.errorStateTextStyle,
      errorStateSubtitleColor: style.errorStateSubTitleTextColor,
      errorStateSubtitleStyle: style.errorStateSubTitleTextStyle,
      buttonTextStyle: style.retryButtonTextStyle,
      buttonTextColor: style.retryButtonTextColor,
      buttonBackgroundColor: style.retryButtonBackgroundColor,
      buttonBorderSide: style.retryButtonBorder,
      buttonBorderRadius: style.retryButtonBorderRadius,
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: listPadding,
      itemCount: hasMore ? users.length + 1 : users.length,
      itemBuilder: (context, index) {
        if (index >= users.length) {
          if (!isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore?.call();
            });
          }
          return _buildLoadingIndicator();
        }
        final user = users[index];
        return Column(
          children: [
            if (stickyHeaderVisibility != true)
              _buildUserListDivider(users, index),
            _buildUserItem(context, user),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(spacing.padding4 ?? 16),
      child: Center(
        child: CircularProgressIndicator(color: colorPalette.primary),
      ),
    );
  }

  Widget _buildUserListDivider(List<ChatUser> users, int index) {
    final currentName = users[index].name;
    if (currentName.isEmpty) return const SizedBox.shrink();
    final currentInitial = currentName.substring(0, 1).toLowerCase();
    final prevInitial = (index > 0 && users[index - 1].name.isNotEmpty)
        ? users[index - 1].name.substring(0, 1).toLowerCase()
        : null;
    if (index == 0 || currentInitial != prevInitial) {
      return Padding(
        padding: EdgeInsets.only(
          left: spacing.padding5 ?? 0,
          right: spacing.padding5 ?? 0,
          top: spacing.padding2 ?? 0,
        ),
        child: SectionSeparator(
          text: currentName.substring(0, 1).toUpperCase(),
          dividerColor: colorPalette.transparent,
          textStyle: TextStyle(
            color: style.stickyTitleColor ?? colorPalette.primary,
            fontSize: typography.heading4?.medium?.fontSize,
            fontWeight: typography.heading4?.medium?.fontWeight,
            fontFamily: typography.heading4?.medium?.fontFamily,
          ).merge(style.stickyTitleTextStyle),
          height: 0,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUserItem(BuildContext context, ChatUser user) {
    if (listItemView != null) {
      return listItemView!(user);
    }
    final isSelected = selectedUserIds.contains(user.id);
    final showCheckbox =
        selectionMode != null && selectionMode != SelectionMode.none;

    final presence = presenceMap[user.id] ?? user.presence;
    final isStatusVisible =
        usersStatusVisibility != false && !user.isBlocked;
    final isOnline = isStatusVisible && presence == UserPresence.online;

    final statusColor = isOnline
        ? (statusIndicatorStyle?.backgroundColor ?? colorPalette.success)
        : null;

    return Builder(
      builder: (rowContext) => Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (style.listItemSelectedBackgroundColor ??
                    colorPalette.background4)
              : colorPalette.transparent,
        ),
        child: GestureDetector(
          onTap: () => _handleItemTap(rowContext, user),
          onLongPress: () => _handleItemLongPress(rowContext, user),
          child: Row(
            children: [
              if (showCheckbox || selectedUserIds.isNotEmpty)
                Checkbox(
                  fillColor: isSelected
                      ? WidgetStateProperty.all(
                          style.checkBoxCheckedBackgroundColor ??
                              colorPalette.iconHighlight,
                        )
                      : WidgetStateProperty.all(
                          style.checkBoxBackgroundColor ??
                              colorPalette.transparent,
                        ),
                  value: isSelected,
                  onChanged: (_) => _handleItemTap(rowContext, user),
                  activeColor:
                      style.checkBoxCheckedBackgroundColor ??
                      colorPalette.iconHighlight,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        style.checkBoxBorderRadius ??
                        BorderRadius.circular(spacing.radius1 ?? 4),
                  ),
                  checkColor:
                      style.checkboxSelectedIconColor ?? colorPalette.white,
                  side:
                      style.checkBoxBorder ??
                      BorderSide(
                        color:
                            colorPalette.borderDefault ?? Colors.transparent,
                        width: 1.25,
                      ),
                ),
              Expanded(
                child: ConvoKitListItem(
                  id: user.id,
                  avatarName: user.name,
                  avatarURL: user.avatarUrl,
                  avatarHeight: 40,
                  avatarWidth: 40,
                  title: user.name,
                  subtitleView: subtitleView?.call(rowContext, user),
                  tailView: trailingView?.call(rowContext, user),
                  avatarStyle:
                      avatarStyle ?? ConvoKitAvatarStyle.of(rowContext),
                  statusIndicatorColor: statusColor,
                  statusIndicatorIcon: null,
                  statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
                    border:
                        statusIndicatorStyle?.border ??
                        Border.all(
                          width: spacing.spacing ?? 0,
                          color:
                              colorPalette.background1 ?? Colors.transparent,
                        ),
                    backgroundColor:
                        statusIndicatorStyle?.backgroundColor ??
                        colorPalette.success,
                  ),
                  hideSeparator: true,
                  style: ListItemStyle(
                    background: isSelected
                        ? (style.listItemSelectedBackgroundColor ??
                              colorPalette.background4)
                        : colorPalette.transparent,
                    titleStyle: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: typography.heading4?.medium?.fontSize,
                      fontWeight: typography.heading4?.medium?.fontWeight,
                      fontFamily: typography.heading4?.medium?.fontFamily,
                      color:
                          style.itemTitleTextColor ?? colorPalette.textPrimary,
                    ).merge(style.itemTitleTextStyle),
                    padding: EdgeInsets.only(
                      left: (showCheckbox || selectedUserIds.isNotEmpty)
                          ? 0
                          : spacing.padding4 ?? 0,
                      right: spacing.padding4 ?? 0,
                      top: spacing.padding2 ?? 0,
                      bottom: spacing.padding2 ?? 0,
                    ),
                    border: style.itemBorder,
                  ),
                  leadingStateView: leadingView?.call(rowContext, user),
                  titleView: titleView?.call(rowContext, user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, ChatUser user) {
    if (activateSelection == ActivateSelection.onClick ||
        (activateSelection == ActivateSelection.onLongClick &&
            selectedUserIds.isNotEmpty)) {
      onToggleSelection?.call(user.id);
    } else if (onItemTap != null) {
      onItemTap!(context, user);
    }
  }

  void _handleItemLongPress(BuildContext rowContext, ChatUser user) {
    if (activateSelection == ActivateSelection.onLongClick &&
        selectedUserIds.isEmpty) {
      onToggleSelection?.call(user.id);
    } else if (onItemLongPress != null) {
      onItemLongPress!(rowContext, user);
    } else if (options != null) {
      showListOptionsMenu(
        rowContext: rowContext,
        options: options!(rowContext, user),
        colorPalette: colorPalette,
        spacing: spacing,
      );
    }
  }
}
