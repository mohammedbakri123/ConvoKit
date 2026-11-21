import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';
import '../../../convokit_uikit.dart' as cc;

/// [ConvoKitGroupMembers] displays members of a [ChatGroup] backed by
/// [GroupRepository] (`listMembers`, `addMembers`, `removeMember`) via
/// [ConvoKitScope].
///
/// Gated on `kit.capabilities.groups && kit.groups != null`. When groups are
/// disabled or absent, renders an empty/disabled state cleanly without invoking
/// any repository methods or throwing null-check errors.
class ConvoKitGroupMembers extends StatefulWidget {
  const ConvoKitGroupMembers({
    super.key,
    required this.group,
    this.membersController,
    this.subtitleView,
    this.hideSeparator,
    this.listItemView,
    this.style,
    this.controller,
    this.searchPlaceholder,
    this.backButton,
    this.showBackButton = true,
    this.searchBoxIcon,
    this.hideSearch = false,
    this.selectionMode,
    this.onSelection,
    this.stateCallBack,
    this.hideError,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.appBarOptions,
    this.options,
    this.trailingView,
    this.selectIcon,
    this.submitIcon,
    this.onError,
    this.onBack,
    this.onItemTap,
    this.onItemLongPress,
    this.activateSelection,
    this.height,
    this.width,
    this.hideAppbar,
    this.searchKeyword,
    this.onLoad,
    this.onEmpty,
    this.setOptions,
    this.addOptions,
    this.leadingView,
    this.titleView,
    this.hideBanMemberOption,
    this.hideKickMemberOption,
    this.hideScopeChangeOption,
    this.usersStatusVisibility = true,
    this.pageLimit = 30,
  });

  final ChatGroup group;
  final ConvoKitGroupMembersController? membersController;
  final Widget? Function(BuildContext context, ChatMember groupMember)?
  subtitleView;
  final bool? hideSeparator;
  final Widget Function(ChatMember groupMember)? listItemView;
  final ConvoKitGroupMembersStyle? style;
  final ScrollController? controller;

  final List<CometChatOption>? Function(
    ChatGroup group,
    ChatMember member,
    ConvoKitGroupMembersController controller,
    BuildContext context,
  )?
  options;

  final String? searchPlaceholder;
  final Widget? backButton;
  final bool showBackButton;
  final Widget? searchBoxIcon;
  final bool hideSearch;
  final SelectionMode? selectionMode;
  final Function(List<ChatMember>?)? onSelection;
  final Function(ConvoKitGroupMembersController controller)? stateCallBack;
  final bool? hideError;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final List<Widget>? appBarOptions;
  final Widget Function(BuildContext context, ChatMember groupMember)?
  trailingView;
  final Widget? submitIcon;
  final Widget? selectIcon;
  final VoidCallback? onBack;
  final Function(ChatMember groupMember)? onItemTap;
  final Function(ChatMember groupMember)? onItemLongPress;
  final ActivateSelection? activateSelection;
  final OnError? onError;
  final double? height;
  final double? width;
  final bool? hideAppbar;
  final String? searchKeyword;
  final OnLoad<ChatMember>? onLoad;
  final OnEmpty? onEmpty;

  final List<CometChatOption>? Function(
    ChatGroup group,
    ChatMember groupMember,
    ConvoKitGroupMembersController controller,
    BuildContext context,
  )?
  setOptions;

  final List<CometChatOption>? Function(
    ChatGroup group,
    ChatMember groupMember,
    ConvoKitGroupMembersController controller,
    BuildContext context,
  )?
  addOptions;

  final Widget? Function(BuildContext context, ChatMember groupMember)?
  leadingView;
  final Widget? Function(BuildContext context, ChatMember groupMember)?
  titleView;
  final bool? usersStatusVisibility;
  final bool? hideKickMemberOption;
  final bool? hideBanMemberOption;
  final bool? hideScopeChangeOption;
  final int pageLimit;

  @override
  State<ConvoKitGroupMembers> createState() => _ConvoKitGroupMembersState();
}

class _ConvoKitGroupMembersState extends State<ConvoKitGroupMembers> {
  late ConvoKitGroupMembersController _controller;
  bool _isExternalController = false;
  bool _kitBound = false;
  ConvoKit? _kit;
  EventHub? _hub;
  StreamSubscription<Map<String, UserPresence>>? _presenceSub;
  Map<String, UserPresence> _presenceMap = const {};

  late ConvoKitColorPalette _colorPalette;
  late ConvoKitTypography _typography;
  late ConvoKitSpacing _spacing;
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  @override
  void initState() {
    super.initState();
    if (widget.membersController != null) {
      _controller = widget.membersController!;
      _isExternalController = true;
    } else {
      _controller = ConvoKitGroupMembersController(
        group: widget.group,
        selectionMode: widget.selectionMode ?? SelectionMode.none,
        usersStatusVisibility: widget.usersStatusVisibility ?? true,
        onError: widget.onError,
        onEmpty: widget.onEmpty,
        onLoad: widget.onLoad,
        hideBanMemberOption: widget.hideBanMemberOption,
        hideKickMemberOption: widget.hideKickMemberOption,
        hideScopeChangeOption: widget.hideScopeChangeOption,
        pageLimit: widget.pageLimit,
        initialSearchKeyword: widget.searchKeyword,
      );
      _isExternalController = false;
    }
    widget.stateCallBack?.call(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ConvoKit? newKit;
    EventHub? newHub;
    try {
      newKit = ConvoKitScope.of(context);
      newHub = ConvoKitScope.hubOf(context);
    } on StateError {
      newKit = null;
      newHub = null;
    }

    if (!_kitBound || !identical(_kit, newKit)) {
      _kitBound = true;
      _kit = newKit;
      _hub = newHub;
      _bindPresence();
      if (!_isExternalController) {
        _controller.attachKit(newKit);
        unawaited(_controller.loadMembers());
      } else if (!_controller.hasLoadedOnce) {
        if (!_controller.isGroupsEnabled && newKit != null) {
          _controller.attachKit(newKit);
        }
        unawaited(_controller.loadMembers());
      }
    }

    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      _themeInitialized = true;
      _colorPalette = ConvoKitThemeHelper.getColorPalette(context);
      _typography = ConvoKitThemeHelper.getTypography(context);
      _spacing = ConvoKitThemeHelper.getSpacing(context);
    }
  }

  @override
  void didUpdateWidget(covariant ConvoKitGroupMembers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchKeyword != widget.searchKeyword) {
      _controller.onSearch(widget.searchKeyword ?? '');
    }
  }

  void _bindPresence() {
    _presenceSub?.cancel();
    _presenceSub = null;
    final hub = _hub;
    if (hub == null) {
      _presenceMap = const {};
      return;
    }
    _presenceSub = hub.presenceRegistry.stream.listen((map) {
      if (!mounted) return;
      setState(() {
        _presenceMap = map;
      });
    });
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  ConvoKitGroupMembersStyle _resolvedStyle(BuildContext context) {
    return ConvoKitThemeHelper.getTheme<ConvoKitGroupMembersStyle>(
      context: context,
      defaultTheme: ConvoKitGroupMembersStyle.of,
    ).merge(widget.style);
  }

  Widget _buildScopeBadge(
    ChatMember member,
    ConvoKitGroupMembersStyle style,
  ) {
    Color? bg;
    BoxBorder? border;
    Color? textColor;
    TextStyle? textStyle;
    String label;

    switch (member.role) {
      case GroupRole.owner:
        label = 'Owner';
        bg = style.ownerMemberScopeBackgroundColor ?? _colorPalette.primary;
        textColor =
            style.ownerMemberScopeTextColor ??
            style.ownerMemberScopeTextStyle?.color ??
            _colorPalette.white;
        border = style.ownerMemberScopeBorder;
        textStyle = style.ownerMemberScopeTextStyle;
      case GroupRole.admin:
        label = 'Admin';
        bg =
            style.adminMemberScopeBackgroundColor ??
            _colorPalette.extendedPrimary100;
        border =
            style.adminMemberScopeBorder ??
            Border.all(
              color: _colorPalette.borderHighlight ?? Colors.transparent,
              width: 1,
            );
        textColor =
            style.adminMemberScopeTextColor ??
            style.adminMemberScopeTextStyle?.color ??
            _colorPalette.textHighlight;
        textStyle = style.adminMemberScopeTextStyle;
      case GroupRole.member:
        return const SizedBox();
    }

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: _spacing.padding3 ?? 0,
        vertical: _spacing.padding1 ?? 0,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(_spacing.radiusMax ?? 0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _typography.caption1?.regular?.fontSize,
          fontWeight: _typography.caption1?.regular?.fontWeight,
          color: textColor,
        ).merge(textStyle).copyWith(color: textColor),
      ),
    );
  }

  Widget _buildListItem(
    ChatMember member,
    ConvoKitGroupMembersStyle groupMemberStyle,
    GlobalKey itemKey,
  ) {
    if (widget.listItemView != null) {
      return widget.listItemView!(member);
    }

    final subtitle = widget.subtitleView?.call(context, member);
    final title = widget.titleView?.call(context, member);
    final leading = widget.leadingView?.call(context, member);
    final Widget tail = widget.trailingView != null
        ? widget.trailingView!(context, member)
        : _buildScopeBadge(member, groupMemberStyle);

    final isSelected = _controller.selectedMemberIds.contains(member.user.id);
    final hasSelection = _controller.selectedMemberIds.isNotEmpty;

    final livePresence = _presenceMap[member.user.id] ?? member.user.presence;
    final effectiveMember = ChatMember(
      user: ChatUser(
        id: member.user.id,
        name: member.user.name,
        avatarUrl: member.user.avatarUrl,
        presence: livePresence,
        isBlocked: member.user.isBlocked,
      ),
      role: member.role,
    );

    final statusUtils = StatusIndicatorUtils.getStatusIndicatorFromParams(
      context: context,
      groupMember: effectiveMember,
      isSelected: isSelected,
      onlineStatusIndicatorColor:
          groupMemberStyle.onlineStatusColor ?? _colorPalette.success,
      usersStatusVisibility: widget.usersStatusVisibility,
      selectIcon: widget.selectIcon,
    );

    final currentUserId = _controller.loggedInUser?.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (groupMemberStyle.listItemSelectedBackgroundColor ??
                  _colorPalette.background4)
            : _colorPalette.transparent,
      ),
      padding: EdgeInsets.only(
        left: hasSelection ? 0 : _spacing.padding4 ?? 0,
        right: _spacing.padding4 ?? 0,
        top: _spacing.padding2 ?? 0,
        bottom: _spacing.padding2 ?? 0,
      ),
      child: GestureDetector(
        onLongPress: () => _onItemLongPress(member, groupMemberStyle, itemKey),
        onTap: () => _onItemTap(member),
        child: Row(
          children: [
            if (hasSelection)
              Checkbox(
                fillColor: isSelected
                    ? WidgetStateProperty.all(
                        groupMemberStyle.checkboxCheckedBackgroundColor ??
                            _colorPalette.iconHighlight,
                      )
                    : WidgetStateProperty.all(
                        groupMemberStyle.checkboxBackgroundColor ??
                            _colorPalette.transparent,
                      ),
                value: isSelected,
                onChanged: (_) => _onItemTap(member),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      groupMemberStyle.checkboxBorderRadius ??
                      BorderRadius.circular(_spacing.radius1 ?? 0),
                ),
                checkColor:
                    groupMemberStyle.checkboxSelectedIconColor ??
                    _colorPalette.white,
                side:
                    groupMemberStyle.checkboxBorder ??
                    BorderSide(
                      color:
                          (isSelected
                              ? _colorPalette.borderHighlight
                              : _colorPalette.borderDefault) ??
                          Colors.transparent,
                      width: 1.25,
                    ),
              )
            else
              const SizedBox(),
            Expanded(
              child: ConvoKitListItem(
                id: member.user.id,
                avatarName: member.user.name,
                avatarURL: member.user.avatarUrl,
                title: (currentUserId != null &&
                        currentUserId == member.user.id)
                    ? cc.Translations.of(context).you
                    : member.user.name,
                subtitleView: subtitle,
                tailView: tail,
                avatarStyle:
                    groupMemberStyle.avatarStyle ??
                    const ConvoKitAvatarStyle(),
                avatarHeight: 40,
                avatarWidth: 40,
                statusIndicatorColor: statusUtils.statusIndicatorColor,
                statusIndicatorIcon: statusUtils.icon,
                statusIndicatorStyle:
                    groupMemberStyle.statusIndicatorStyle ??
                    const ConvoKitStatusIndicatorStyle(),
                hideSeparator: widget.hideSeparator ?? true,
                titleView: title,
                leadingStateView: leading,
                style: ListItemStyle(
                  background: _colorPalette.transparent,
                  titleStyle: TextStyle(
                    fontSize: _typography.heading4?.medium?.fontSize,
                    fontWeight: _typography.heading4?.medium?.fontWeight,
                    fontFamily: _typography.heading4?.medium?.fontFamily,
                    color: _colorPalette.textPrimary,
                  ),
                ).merge(groupMemberStyle.listItemStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTap(ChatMember member) {
    final isOwner = member.role == GroupRole.owner;
    final canSelect =
        !isOwner &&
        (widget.activateSelection == ActivateSelection.onClick ||
            (widget.activateSelection == ActivateSelection.onLongClick &&
                _controller.selectedMemberIds.isNotEmpty)) &&
        !(widget.selectionMode == null ||
            widget.selectionMode == SelectionMode.none);

    if (canSelect) {
      _controller.toggleSelection(member.user.id);
    } else if (widget.onItemTap != null) {
      widget.onItemTap!(member);
    }
  }

  void _onItemLongPress(
    ChatMember member,
    ConvoKitGroupMembersStyle groupMemberStyle,
    GlobalKey itemKey,
  ) {
    final isOwner = member.role == GroupRole.owner;
    final canStartSelection =
        !isOwner &&
        widget.activateSelection == ActivateSelection.onLongClick &&
        _controller.selectedMemberIds.isEmpty &&
        !(widget.selectionMode == null ||
            widget.selectionMode == SelectionMode.none);

    if (canStartSelection) {
      _controller.toggleSelection(member.user.id);
      return;
    }

    if (widget.onItemLongPress != null) {
      widget.onItemLongPress!(member);
      return;
    }

    List<CometChatOption> opts = [];

    if (widget.options != null) {
      opts = widget.options!(widget.group, member, _controller, context) ?? [];
    } else if (widget.setOptions != null) {
      opts =
          widget.setOptions!(widget.group, member, _controller, context) ?? [];
    } else {
      if (widget.addOptions != null) {
        opts.addAll(
          widget.addOptions!(widget.group, member, _controller, context) ?? [],
        );
      }
      final metaOptions = _controller.defaultFunction(
        widget.group,
        member,
        context,
        _colorPalette,
        _typography,
        _spacing,
      );
      opts.addAll(
        metaOptions.map(
          (o) => CometChatOption(
            id: o.id,
            title: o.title,
            icon: o.icon,
            packageName: o.packageName,
            backgroundColor: o.backgroundColor,
            iconTint: _colorPalette.iconSecondary,
            iconWidget: o.iconWidget,
            onClick: () =>
                _handleMemberOptionClick(o.id, member, groupMemberStyle),
          ),
        ),
      );
    }

    _showPopupMenu(opts, groupMemberStyle, itemKey, member);
  }

  void _handleMemberOptionClick(
    String optionId,
    ChatMember member,
    ConvoKitGroupMembersStyle groupMemberStyle,
  ) {
    final confirmDialogStyle =
        ConvoKitThemeHelper.getTheme<ConvoKitConfirmDialogStyle>(
          context: context,
          defaultTheme: ConvoKitConfirmDialogStyle.of,
        ).merge(groupMemberStyle.confirmDialogStyle);
    final changeScopeStyle =
        ConvoKitThemeHelper.getTheme<ConvoKitChangeScopeStyle>(
          context: context,
          defaultTheme: ConvoKitChangeScopeStyle.of,
        ).merge(groupMemberStyle.changeScopeStyle);

    switch (optionId) {
      case GroupMemberOptionConstants.kick:
        _showConfirmDialog(
          title: '${cc.Translations.of(context).kick} ${member.user.name}?',
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 48,
            color: confirmDialogStyle.iconColor ?? _colorPalette.error,
          ),
          message:
              '${cc.Translations.of(context).areYouSureRemove} ${member.user.name} ${cc.Translations.of(context).from} ${widget.group.name}?',
          confirmText: cc.Translations.of(context).kick.toUpperCase(),
          confirmDialogStyle: confirmDialogStyle,
          onConfirm: () {
            unawaited(_controller.removeMember(member.user.id));
          },
        );
      case GroupMemberOptionConstants.ban:
        _showConfirmDialog(
          title: '${cc.Translations.of(context).ban} ${member.user.name}?',
          icon: Icon(
            Icons.not_interested,
            size: 48,
            color: confirmDialogStyle.iconColor ?? _colorPalette.error,
          ),
          message:
              '${cc.Translations.of(context).areYouSureBan} ${member.user.name} ${cc.Translations.of(context).from} ${widget.group.name}?',
          confirmText: cc.Translations.of(context).ban.toUpperCase(),
          confirmDialogStyle: confirmDialogStyle,
          onConfirm: () {
            unawaited(_controller.removeMember(member.user.id));
          },
        );
      case GroupMemberOptionConstants.changeScope:
        showModalBottomSheet(
          context: context,
          barrierColor: (_colorPalette.textPrimary ?? const Color(0xFF141414))
              .withValues(alpha: 0.8),
          builder: (_) => SingleChildScrollView(
            child: ConvoKitChangeScope(
              group: widget.group,
              member: member,
              style: changeScopeStyle,
              onSave: (group, m, newScope, oldScope) async {
                final role = newScope.toLowerCase() == 'admin'
                    ? GroupRole.admin
                    : GroupRole.member;
                _controller.updateMemberRole(m.user.id, role);
              },
            ),
          ),
        );
    }
  }

  void _showConfirmDialog({
    required String title,
    required Widget icon,
    required String message,
    required String confirmText,
    required ConvoKitConfirmDialogStyle confirmDialogStyle,
    required VoidCallback onConfirm,
  }) {
    ConvoKitConfirmDialog(
      context: context,
      icon: icon,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _typography.heading2?.medium?.fontSize,
          fontWeight: _typography.heading2?.medium?.fontWeight,
          fontFamily: _typography.heading2?.medium?.fontFamily,
          color: _colorPalette.textPrimary,
        ).merge(confirmDialogStyle.titleTextStyle),
      ),
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _typography.body?.regular?.fontSize,
          fontWeight: _typography.body?.regular?.fontWeight,
          fontFamily: _typography.body?.regular?.fontFamily,
          color: _colorPalette.textSecondary,
        ).merge(confirmDialogStyle.messageTextStyle),
      ),
      confirmButtonText: confirmText,
      cancelButtonText: cc.Translations.of(context).cancelCapital,
      style: ConvoKitConfirmDialogStyle(
        iconColor: confirmDialogStyle.iconColor ?? _colorPalette.error,
        backgroundColor: confirmDialogStyle.backgroundColor,
        cancelButtonBackground:
            confirmDialogStyle.cancelButtonBackground ??
            _colorPalette.borderLight,
        confirmButtonBackground:
            confirmDialogStyle.confirmButtonBackground ?? _colorPalette.error,
        cancelButtonTextColor: confirmDialogStyle.cancelButtonTextColor,
        confirmButtonTextColor:
            confirmDialogStyle.confirmButtonTextColor ?? _colorPalette.white,
      ),
      onCancel: (dialogContext) => Navigator.of(dialogContext).pop(),
      onConfirm: (dialogContext) {
        Navigator.of(dialogContext).pop();
        onConfirm();
      },
    ).show();
  }

  void _showPopupMenu(
    List<CometChatOption> options,
    ConvoKitGroupMembersStyle groupMemberStyle,
    GlobalKey widgetKey,
    ChatMember member,
  ) {
    if (options.isEmpty) return;
    final position = WidgetPositionUtil.getWidgetPosition(context, widgetKey);
    showMenu(
      context: context,
      position: position ?? const RelativeRect.fromLTRB(0, 0, 0, 0),
      menuPadding: EdgeInsets.zero,
      color:
          groupMemberStyle.optionsBackgroundColor ?? _colorPalette.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_spacing.radius2 ?? 0),
        side: BorderSide(
          color: _colorPalette.borderLight ?? Colors.transparent,
          width: 1,
        ),
      ),
      shadowColor: _colorPalette.transparent,
      elevation: 8,
      items: options
          .map(
            (o) => CustomPopupMenuItem<CometChatOption>(
              value: o,
              child: GetMenuView(
                option: o,
                textStyle: groupMemberStyle.optionsTextStyle,
                iconTint: groupMemberStyle.optionsIconColor ?? o.iconTint,
              ),
            ),
          )
          .toList(),
    ).then((selected) {
      if (selected?.onClick != null) selected!.onClick!();
    });
  }

  Widget _buildLoading(ConvoKitGroupMembersStyle style) {
    if (widget.loadingStateView != null) {
      return Center(child: widget.loadingStateView!(context));
    }
    return ConvoKitShimmerEffect(
      colorPalette: _colorPalette,
      child: ListView.builder(
        itemCount: 30,
        shrinkWrap: true,
        itemBuilder: (_, _) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _spacing.padding4 ?? 0,
            vertical: _spacing.padding3 ?? 0,
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: _spacing.padding3 ?? 0),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 19,
                          width: MediaQuery.sizeOf(context).width * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(
                              _spacing.radius2 ?? 0,
                            ),
                          ),
                        ),
                        Container(
                          height: 19,
                          width: MediaQuery.sizeOf(context).width * 0.2,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(
                              _spacing.radius2 ?? 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(
                          _spacing.radius2 ?? 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ConvoKitGroupMembersStyle style) {
    if (widget.emptyStateView != null) return widget.emptyStateView!(context);
    return UIStateUtils.getDefaultEmptyStateView(
      context,
      _colorPalette,
      _typography,
      _spacing,
      emptyStateTextColor: style.emptyStateTextColor,
      emptyStateTextStyle: style.emptyStateTextStyle,
      emptyStateSubtitleColor: style.emptyStateSubtitleTextColor,
      emptyStateSubtitleStyle: style.emptyStateSubtitleTextStyle,
    );
  }

  Widget _buildError(ConvoKitGroupMembersStyle style) {
    if (widget.errorStateView != null) return widget.errorStateView!(context);
    return UIStateUtils.getDefaultErrorStateView(
      context,
      _colorPalette,
      _typography,
      _spacing,
      () => unawaited(_controller.loadMembers()),
      errorStateTextStyle: style.errorStateTextStyle,
      errorStateSubtitleStyle: style.errorStateSubtitleStyle,
      buttonTextStyle: style.retryButtonTextStyle,
      buttonTextColor: style.retryButtonTextColor,
      buttonBackgroundColor: style.retryButtonBackgroundColor,
      buttonBorderSide: style.retryButtonBorder,
      buttonBorderRadius: style.retryButtonBorderRadius,
    );
  }

  Widget _buildList(
    List<ChatMember> members,
    ConvoKitGroupMembersStyle style,
  ) {
    final keys = List.generate(members.length, (_) => GlobalKey());
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            _controller.hasMore &&
            !_controller.isLoadingMore) {
          unawaited(_controller.loadMoreMembers());
        }
        return false;
      },
      child: ListView.builder(
        controller: widget.controller,
        padding: style.listPadding,
        itemCount: members.length + (_controller.isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          if (index >= members.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(_spacing.padding4 ?? 16),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    color: style.loadingIconColor ?? _colorPalette.primary,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            key: keys[index],
            child: _buildListItem(members[index], style, keys[index]),
          );
        },
      ),
    );
  }

  Widget _buildSelectionWidget(ConvoKitGroupMembersStyle style) {
    if (_controller.selectedMemberIds.isEmpty) {
      return const SizedBox(height: 0, width: 0);
    }
    return IconButton(
      tooltip: Translations.of(context).done,
      onPressed: () {
        widget.onSelection?.call(_controller.getSelectedList());
      },
      icon:
          widget.submitIcon ??
          Icon(
            Icons.check,
            color: style.submitIconColor ?? _colorPalette.iconPrimary,
            size: 24,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupMemberStyle = _resolvedStyle(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (ctx, _) {
        final hasSelection = _controller.selectedMemberIds.isNotEmpty;
        final titleText = hasSelection
            ? '${_controller.selectedMemberIds.length}'
            : cc.Translations.of(context).members;
        final effectiveHideSearch =
            widget.hideSearch || !_controller.isGroupsEnabled;

        return CometChatListBase(
          titleSpacing: widget.showBackButton ? 0 : 16,
          titleView: Text(
            titleText,
            style: TextStyle(
              color: _colorPalette.textPrimary,
              fontSize: _typography.heading1?.bold?.fontSize,
              fontWeight: _typography.heading1?.bold?.fontWeight,
              fontFamily: _typography.heading1?.bold?.fontFamily,
            ).merge(groupMemberStyle.titleStyle),
          ),
          hideSearch: effectiveHideSearch,
          hideAppBar: widget.hideAppbar ?? false,
          backIcon: hasSelection
              ? IconButton(
                  tooltip: Translations.of(context).clearSearch,
                  onPressed: _controller.clearSelection,
                  icon: Icon(
                    Icons.clear,
                    color: _colorPalette.iconPrimary,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                )
              : (widget.backButton ??
                    IconButton(
                      tooltip: Translations.of(context).back,
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            groupMemberStyle.backIconColor ??
                            _colorPalette.iconPrimary,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    )),
          onBack: widget.onBack,
          placeholder: widget.searchPlaceholder,
          searchText: widget.searchKeyword,
          showBackButton: widget.showBackButton,
          searchBoxIcon: widget.searchBoxIcon,
          onSearch: _controller.onSearch,
          menuOptions: [
            if (widget.appBarOptions != null &&
                widget.appBarOptions!.isNotEmpty)
              ...widget.appBarOptions!,
            _buildSelectionWidget(groupMemberStyle),
          ],
          searchPadding: EdgeInsets.symmetric(
            horizontal: _spacing.padding4 ?? 0,
            vertical: _spacing.padding3 ?? 0,
          ),
          searchContentPadding: EdgeInsets.symmetric(
            horizontal: _spacing.padding3 ?? 0,
            vertical: _spacing.padding2 ?? 0,
          ),
          searchBoxHeight: 40,
          style: ListBaseStyle(
            background:
                groupMemberStyle.backgroundColor ?? _colorPalette.background1,
            titleStyle: TextStyle(
              color: _colorPalette.textPrimary,
              fontSize: _typography.heading1?.bold?.fontSize,
              fontWeight: _typography.heading1?.bold?.fontWeight,
              fontFamily: _typography.heading1?.bold?.fontFamily,
            ).merge(groupMemberStyle.titleStyle),
            height: widget.height,
            width: widget.width,
            backIconTint: groupMemberStyle.backIconColor,
            searchIconTint:
                groupMemberStyle.searchIconColor ?? _colorPalette.iconSecondary,
            border: groupMemberStyle.border,
            borderRadius: groupMemberStyle.borderRadius,
            searchTextStyle: TextStyle(
              color: _colorPalette.textPrimary,
              fontSize: _typography.heading4?.regular?.fontSize,
              fontWeight: _typography.heading4?.regular?.fontWeight,
              fontFamily: _typography.heading4?.regular?.fontFamily,
            ).merge(groupMemberStyle.searchTextStyle),
            searchPlaceholderStyle: TextStyle(
              color: _colorPalette.textTertiary,
              fontSize: _typography.heading4?.regular?.fontSize,
              fontWeight: _typography.heading4?.regular?.fontWeight,
              fontFamily: _typography.heading4?.regular?.fontFamily,
            ).merge(groupMemberStyle.searchPlaceholderStyle),
            searchTextFieldRadius: groupMemberStyle.searchBorderRadius,
            searchBoxBackground:
                groupMemberStyle.searchBackground ?? _colorPalette.background3,
            appBarShape: Border(
              bottom: BorderSide(
                color:
                    groupMemberStyle.separatorColor ??
                    _colorPalette.borderLight ??
                    Colors.transparent,
                width: groupMemberStyle.separatorHeight ?? 1,
              ),
            ),
          ),
          container: _buildContainer(groupMemberStyle),
        );
      },
    );
  }

  Widget _buildContainer(ConvoKitGroupMembersStyle style) {
    if (_controller.isDisabled) {
      return _buildEmpty(style);
    }
    if (_controller.isLoading) {
      return _buildLoading(style);
    }
    if (_controller.error != null) {
      if (widget.hideError == true) return const SizedBox.shrink();
      return _buildError(style);
    }
    final members = _controller.visibleMembers;
    if (members.isEmpty) {
      return _buildEmpty(style);
    }
    return _buildList(members, style);
  }
}
