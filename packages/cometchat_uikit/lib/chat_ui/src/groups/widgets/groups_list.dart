import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';
import '../../shared/list_options_menu.dart';

/// Stateless widget that displays a list of [ChatGroup]s with state handling
/// and cursor pagination.
class GroupsList extends StatelessWidget {
  const GroupsList({
    super.key,
    required this.groups,
    required this.style,
    required this.colorPalette,
    required this.spacing,
    required this.typography,
    this.isLoading = false,
    this.isEmpty = false,
    this.error,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedGroupIds = const <String>{},
    this.onLoadMore,
    this.onRetry,
    this.onToggleSelection,
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
    this.hideGroupTypeIcon,
    this.selectionMode,
    this.activateSelection,
    this.onItemTap,
    this.onItemLongPress,
    this.options,
    this.avatarStyle,
    this.statusIndicatorStyle,
    this.privateGroupIcon,
    this.protectedGroupIcon,
  });

  final List<ChatGroup> groups;
  final bool isLoading;
  final bool isEmpty;
  final ChatError? error;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<String> selectedGroupIds;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final void Function(String groupId)? onToggleSelection;

  final ConvoKitGroupsStyle style;
  final ConvoKitColorPalette colorPalette;
  final ConvoKitSpacing spacing;
  final ConvoKitTypography typography;
  final ScrollController? scrollController;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final bool? hideError;
  final Widget Function(ChatGroup)? listItemView;
  final Widget? Function(BuildContext, ChatGroup)? subtitleView;
  final Widget? Function(BuildContext, ChatGroup)? trailingView;
  final Widget? Function(BuildContext, ChatGroup)? leadingView;
  final Widget? Function(BuildContext, ChatGroup)? titleView;
  final bool? hideGroupTypeIcon;
  final SelectionMode? selectionMode;
  final ActivateSelection? activateSelection;
  final Function(BuildContext, ChatGroup)? onItemTap;
  final Function(BuildContext, ChatGroup)? onItemLongPress;
  final List<CometChatOption> Function(BuildContext context, ChatGroup group)?
  options;
  final ConvoKitAvatarStyle? avatarStyle;
  final ConvoKitStatusIndicatorStyle? statusIndicatorStyle;
  final Widget? privateGroupIcon;
  final Widget? protectedGroupIcon;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      if (hideError == true) return const SizedBox.shrink();
      return _buildErrorState(context);
    }
    if (isLoading) {
      return _buildLoadingState(context);
    }
    if (isEmpty || groups.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildGroupsList(context);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.0,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(
                            spacing.radius2 ?? 0,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.padding1 ?? 4),
                      Container(
                        height: 12.0,
                        width: MediaQuery.of(context).size.width * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(
                            spacing.radius2 ?? 0,
                          ),
                        ),
                      ),
                    ],
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
                ).emptyGroupList,
                package: UIConstants.packageName,
                width: 120,
                height: 120,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: spacing.padding1 ?? 0),
              child: Text(
                Translations.of(context).noGroupsFound,
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
              'Create or join groups to see them listed here\nand start collaborating.',
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
    if (hideError == true) {
      return const SizedBox.shrink();
    }
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

  Widget _buildGroupsList(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: hasMore ? groups.length + 1 : groups.length,
      itemBuilder: (context, index) {
        if (index >= groups.length) {
          if (!isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore?.call();
            });
          }
          return _buildLoadingIndicator();
        }
        return _buildGroupItem(context, groups[index]);
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

  Widget _buildGroupItem(BuildContext context, ChatGroup group) {
    if (listItemView != null) {
      return listItemView!(group);
    }

    final isSelected = selectedGroupIds.contains(group.id);

    return Builder(
      builder: (rowContext) => _buildGroupListItem(
        context,
        rowContext,
        group,
        isSelected,
      ),
    );
  }

  Widget _buildGroupListItem(
    BuildContext context,
    BuildContext rowContext,
    ChatGroup group,
    bool isSelected,
  ) {
    return CometChatGroupListItem(
      group: group,
      onItemClick: (g) => _handleItemTap(context, g),
      onItemLongClick:
          onItemLongPress != null ||
              options != null ||
              activateSelection == ActivateSelection.onLongClick
          ? (g) => _handleItemLongPress(context, g, rowContext)
          : null,
      onSelectionToggle: () => onToggleSelection?.call(group.id),
      isSelected: isSelected,
      selectionMode: selectionMode ?? SelectionMode.none,
      hideGroupTypeIcon: hideGroupTypeIcon ?? false,
      avatarStyle: avatarStyle ?? style.avatarStyle,
      statusIndicatorStyle: statusIndicatorStyle ?? style.statusIndicatorStyle,
      privateGroupIcon: privateGroupIcon,
      protectedGroupIcon: protectedGroupIcon,
      privateGroupIconBackground: style.privateGroupIconBackground,
      protectedGroupIconBackground: style.protectedGroupIconBackground,
      colorPalette: colorPalette,
      spacing: spacing,
      typography: typography,
      leadingView: leadingView != null ? (g) => leadingView!(context, g) : null,
      titleView: titleView != null ? (g) => titleView!(context, g) : null,
      subtitleView: subtitleView != null
          ? (g) => subtitleView!(context, g)
          : null,
      trailingView: trailingView != null
          ? (g) => trailingView!(context, g)
          : null,
      style: CometChatGroupListItemStyle(
        titleTextStyle: style.itemTitleTextStyle,
        titleTextColor: style.itemTitleTextColor,
        subtitleTextStyle: style.itemSubtitleTextStyle,
        subtitleTextColor: style.itemSubtitleTextColor,
        selectedBackgroundColor: style.listItemSelectedBackgroundColor,
        checkBoxBackgroundColor: style.checkBoxBackgroundColor,
        checkBoxCheckedBackgroundColor: style.checkBoxCheckedBackgroundColor,
        checkBoxBorderRadius: style.checkBoxBorderRadius?.resolve(
          Directionality.of(context),
        ),
        checkBoxStrokeColor: style.checkBoxBorder?.color,
        checkBoxStrokeWidth: style.checkBoxBorder?.width,
        checkBoxCheckColor: style.checkboxSelectedIconColor,
        privateGroupIconBackground: style.privateGroupIconBackground,
        protectedGroupIconBackground: style.protectedGroupIconBackground,
      ),
    );
  }

  void _handleItemTap(BuildContext context, ChatGroup group) {
    if ((activateSelection == ActivateSelection.onClick ||
            (activateSelection == ActivateSelection.onLongClick &&
                selectedGroupIds.isNotEmpty)) &&
        !(selectionMode == null || selectionMode == SelectionMode.none)) {
      onToggleSelection?.call(group.id);
    } else if (onItemTap != null) {
      onItemTap!(context, group);
    }
  }

  void _handleItemLongPress(
    BuildContext context,
    ChatGroup group,
    BuildContext rowContext,
  ) {
    if (activateSelection == ActivateSelection.onLongClick &&
        selectedGroupIds.isEmpty &&
        !(selectionMode == null || selectionMode == SelectionMode.none)) {
      onToggleSelection?.call(group.id);
    } else if (onItemLongPress != null) {
      onItemLongPress!(context, group);
    } else if (options != null) {
      showListOptionsMenu(
        rowContext: rowContext,
        options: options!(rowContext, group),
        colorPalette: colorPalette,
        spacing: spacing,
      );
    }
  }
}
