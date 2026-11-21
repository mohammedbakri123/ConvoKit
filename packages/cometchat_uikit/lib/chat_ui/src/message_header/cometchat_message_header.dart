import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';

import '../../../convokit_uikit.dart';
import '../../../convokit_uikit.dart' as cc;

/// [ConvoKitMessageHeader] displays details for a [ChatUser] or [ChatGroup]
/// using [ConvoKitListItem], observing [EventHub.presenceRegistry] and
/// [EventHub.typingRegistry] directly via [ConvoKitScope].
///
/// Typing indicator rendering is gated on `capabilities.typing`. User and group
/// details are refreshed via [UserRepository.getUser] / [GroupRepository.getGroup].
class ConvoKitMessageHeader extends StatefulWidget
    implements PreferredSizeWidget {
  const ConvoKitMessageHeader({
    super.key,
    this.backButton,
    this.messageHeaderStyle,
    this.group,
    this.user,
    this.conversationId,
    this.trailingView,
    this.listItemView,
    this.showBackButton = true,
    this.subtitleView,
    this.listItemStyle,
    this.onBack,
    this.parentMessage,
    this.pinnedMessagesVisibility = true,
    this.onPinnedMessageItemTap,
    this.pinnedMessagesStyle,
    this.onInfoTap,
    this.onSearchTap,
    this.onHeaderTap,
    this.onPinnedMessagesTap,
    this.avatarHeight,
    this.avatarWidth,
    this.height,
    this.padding,
    this.titleView,
    this.leadingStateView,
    this.auxiliaryButtonView,
    this.usersStatusVisibility = true,
    this.dateTimeFormatterCallback,
  }) : assert(
         user != null || group != null,
         "One of user or group should be passed",
       ),
       assert(
         user == null || group == null,
         "Only one of user or group should be passed",
       );

  /// Custom back button widget.
  final WidgetBuilder? backButton;

  /// Custom subtitle builder.
  final Widget? Function(
    ChatGroup? group,
    ChatUser? user,
    BuildContext context,
  )?
  subtitleView;

  /// Direct-chat peer user (mutually exclusive with [group]).
  final ChatUser? user;

  /// Group (mutually exclusive with [user]).
  final ChatGroup? group;

  /// Optional conversation ID used to observe [TypingRegistry]; defaults to
  /// `user?.id ?? group?.id`.
  final String? conversationId;

  /// Custom replacement for the list item body.
  final Widget Function(
    ChatGroup? group,
    ChatUser? user,
    BuildContext context,
  )?
  listItemView;

  /// Style configuration.
  final ConvoKitMessageHeaderStyle? messageHeaderStyle;

  /// Whether to show the back button.
  final bool? showBackButton;

  /// Optional [ListItemStyle] override.
  final ListItemStyle? listItemStyle;

  /// Trailing widgets placed in the header.
  final List<Widget>? Function(
    ChatUser? user,
    ChatGroup? group,
    BuildContext context,
  )?
  trailingView;

  /// Back button callback.
  final VoidCallback? onBack;

  /// Optional thread root message (puts the header in thread mode).
  final ChatMessage? parentMessage;

  /// Controls visibility of the pinned-messages overflow entry when
  /// [onPinnedMessagesTap] is provided.
  final bool? pinnedMessagesVisibility;

  /// Callback when a pinned message item is tapped.
  final void Function(ChatMessage message)? onPinnedMessageItemTap;

  /// Styling for pinned messages.
  final ConvoKitPinnedMessagesStyle? pinnedMessagesStyle;

  /// Overflow menu "Group Info" / "User Info" callback.
  final VoidCallback? onInfoTap;

  /// Overflow menu "Search" callback.
  final VoidCallback? onSearchTap;

  /// Callback when the avatar/name/subtitle area is tapped.
  final VoidCallback? onHeaderTap;

  /// Overflow menu "Pinned messages" callback.
  final VoidCallback? onPinnedMessagesTap;

  /// Avatar height override.
  final double? avatarHeight;

  /// Avatar width override.
  final double? avatarWidth;

  /// Header height override.
  final double? height;

  /// Header padding override.
  final EdgeInsetsGeometry? padding;

  /// Custom leading view slot.
  final Widget? Function(
    ChatGroup? group,
    ChatUser? user,
    BuildContext context,
  )?
  leadingStateView;

  /// Custom title view slot.
  final Widget? Function(
    ChatGroup? group,
    ChatUser? user,
    BuildContext context,
  )?
  titleView;

  /// Custom auxiliary button slot.
  final Widget? Function(
    ChatGroup? group,
    ChatUser? user,
    BuildContext context,
  )?
  auxiliaryButtonView;

  /// Controls visibility of user online/offline status.
  final bool? usersStatusVisibility;

  /// Optional date/time formatter callback.
  final DateTimeFormatterCallback? dateTimeFormatterCallback;

  @override
  State<ConvoKitMessageHeader> createState() => _ConvoKitMessageHeaderState();

  @override
  Size get preferredSize => Size.fromHeight(height ?? 65);
}

class _ConvoKitMessageHeaderState extends State<ConvoKitMessageHeader> {
  // Theme caching
  late ConvoKitMessageHeaderStyle headerStyle;
  late ConvoKitColorPalette colorPalette;
  late ConvoKitTypography typography;
  late ConvoKitSpacing spacing;
  late ConvoKitStatusIndicatorStyle statusIndicatorStyle;
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;
  double _cachedWidth = 300;

  // Core wiring
  ConvoKit? _kit;
  EventHub? _hub;
  StreamSubscription<Map<String, UserPresence>>? _presenceSub;
  StreamSubscription<Map<String, List<ChatUser>>>? _typingSub;
  int _fetchSeq = 0;

  ChatUser? _user;
  ChatGroup? _group;
  UserPresence _presence = UserPresence.unknown;
  List<ChatUser> _typingUsers = const [];

  String get _effectiveConversationId =>
      widget.conversationId ?? widget.user?.id ?? widget.group?.id ?? '';

  bool get _typingEnabled => _kit?.capabilities.typing ?? false;

  bool get _showPinnedMessagesButton =>
      widget.parentMessage == null &&
      widget.pinnedMessagesVisibility != false &&
      widget.onPinnedMessagesTap != null;

  bool get _showOverflowMenu =>
      widget.parentMessage == null &&
      (_showPinnedMessagesButton ||
          widget.onInfoTap != null ||
          widget.onSearchTap != null);

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _group = widget.group;
    _presence = widget.user?.presence ?? UserPresence.unknown;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      _themeInitialized = true;
      _cachedWidth = MediaQuery.sizeOf(context).width;

      headerStyle = ConvoKitThemeHelper.getTheme<ConvoKitMessageHeaderStyle>(
        context: context,
        defaultTheme: ConvoKitMessageHeaderStyle.of,
      ).merge(widget.messageHeaderStyle);
      statusIndicatorStyle =
          ConvoKitThemeHelper.getTheme<ConvoKitStatusIndicatorStyle>(
            context: context,
            defaultTheme: ConvoKitStatusIndicatorStyle.of,
          ).merge(headerStyle.statusIndicatorStyle);
      typography = ConvoKitThemeHelper.getTypography(context);
      colorPalette = ConvoKitThemeHelper.getColorPalette(context);
      spacing = ConvoKitThemeHelper.getSpacing(context);
    }

    _attachToScope();
  }

  void _attachToScope() {
    ConvoKit? kit;
    EventHub? hub;
    try {
      kit = ConvoKitScope.of(context);
      hub = ConvoKitScope.hubOf(context);
    } on StateError {
      kit = null;
      hub = null;
    }

    if (identical(_kit, kit) && identical(_hub, hub)) {
      return;
    }

    _unsubscribeRegistries();
    _kit = kit;
    _hub = hub;
    _subscribeRegistries();
    unawaited(_refreshEntityDetails());
  }

  void _subscribeRegistries() {
    final hub = _hub;
    if (hub == null) return;

    final user = _user;
    if (user != null) {
      final existing = hub.presenceRegistry.getPresence(user.id);
      _presence = existing != UserPresence.unknown ? existing : user.presence;
      _presenceSub = hub.presenceRegistry.stream.listen((presenceMap) {
        if (!mounted) return;
        final next = presenceMap[user.id];
        if (next != null && next != _presence) {
          setState(() => _presence = next);
        }
      });
    }

    if (_typingEnabled) {
      final convId = _effectiveConversationId;
      _typingUsers = hub.typingRegistry.getTypingUsers(convId);
      _typingSub = hub.typingRegistry.stream.listen((typingMap) {
        if (!mounted) return;
        final next = typingMap[convId] ?? const <ChatUser>[];
        setState(() => _typingUsers = next);
      });
    } else {
      _typingUsers = const [];
    }
  }

  void _unsubscribeRegistries() {
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;
    unawaited(_typingSub?.cancel());
    _typingSub = null;
  }

  Future<void> _refreshEntityDetails() async {
    final kit = _kit;
    if (kit == null) return;
    final seq = ++_fetchSeq;

    if (widget.user != null) {
      final res = await kit.users.getUser(widget.user!.id);
      if (!mounted || seq != _fetchSeq) return;
      res.fold(
        onSuccess: (fetched) {
          setState(() {
            _user = fetched;
            if (_presence == UserPresence.unknown) {
              _presence = fetched.presence;
            }
          });
        },
        onFailure: (_) {},
      );
    } else if (widget.group != null &&
        kit.capabilities.groups &&
        kit.groups != null) {
      final res = await kit.groups!.getGroup(widget.group!.id);
      if (!mounted || seq != _fetchSeq) return;
      res.fold(
        onSuccess: (fetched) {
          setState(() => _group = fetched);
        },
        onFailure: (_) {},
      );
    }
  }

  @override
  void didUpdateWidget(ConvoKitMessageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messageHeaderStyle != oldWidget.messageHeaderStyle) {
      headerStyle = ConvoKitThemeHelper.getTheme<ConvoKitMessageHeaderStyle>(
        context: context,
        defaultTheme: ConvoKitMessageHeaderStyle.of,
      ).merge(widget.messageHeaderStyle);
      statusIndicatorStyle =
          ConvoKitThemeHelper.getTheme<ConvoKitStatusIndicatorStyle>(
            context: context,
            defaultTheme: ConvoKitStatusIndicatorStyle.of,
          ).merge(headerStyle.statusIndicatorStyle);
    }

    final targetChanged =
        widget.user?.id != oldWidget.user?.id ||
        widget.group?.id != oldWidget.group?.id ||
        widget.conversationId != oldWidget.conversationId;

    if (targetChanged) {
      _unsubscribeRegistries();
      _user = widget.user;
      _group = widget.group;
      _presence = widget.user?.presence ?? UserPresence.unknown;
      _typingUsers = const [];
      _subscribeRegistries();
      unawaited(_refreshEntityDetails());
    } else if (widget.user != oldWidget.user) {
      _user = widget.user;
      if (widget.user != null && _presence == UserPresence.unknown) {
        _presence = widget.user!.presence;
      }
    } else if (widget.group != oldWidget.group) {
      _group = widget.group;
    }
  }

  @override
  void dispose() {
    _fetchSeq++;
    _unsubscribeRegistries();
    super.dispose();
  }

  List<({String label, IconData icon, VoidCallback action, bool isDestructive})>
  get _overflowEntries {
    final translations = cc.Translations.of(context);
    return [
      if (widget.onSearchTap != null)
        (
          label: translations.search,
          icon: Icons.search,
          action: widget.onSearchTap!,
          isDestructive: false,
        ),
      if (_showPinnedMessagesButton)
        (
          label: translations.pinnedMessagesTitle,
          icon: Icons.push_pin_outlined,
          action: widget.onPinnedMessagesTap!,
          isDestructive: false,
        ),
      if (widget.onInfoTap != null)
        (
          label: _group != null
              ? translations.groupInfo
              : translations.userInfo,
          icon: Icons.info_outline,
          action: widget.onInfoTap!,
          isDestructive: false,
        ),
    ];
  }

  Widget _buildOverflowMenu(
    ConvoKitMessageHeaderStyle headerStyle,
    ConvoKitColorPalette colorPalette,
  ) {
    final entries = _overflowEntries;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorPalette.background1 ?? colorPalette.white,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        visualDensity: VisualDensity.standard,
      ),
      builder: (context, controller, child) => IconButton(
        tooltip: Translations.of(context).more,
        iconSize: 26,
        icon: Icon(
          Icons.more_vert,
          color:
              headerStyle.menuIconColor ??
              headerStyle.backIconColor ??
              colorPalette.iconPrimary,
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        for (final entry in entries)
          MenuItemButton(
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(112, 48),
              maximumSize: const Size(280, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: entry.isDestructive
                  ? colorPalette.error
                  : colorPalette.textPrimary,
              iconColor: entry.isDestructive
                  ? colorPalette.error
                  : colorPalette.iconSecondary,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                fontFamily: typography.body?.medium?.fontFamily,
              ),
            ),
            leadingIcon: Icon(
              entry.icon,
              size: 24,
              color: entry.isDestructive
                  ? colorPalette.error
                  : colorPalette.iconSecondary,
            ),
            onPressed: entry.action,
            child: Text(entry.label),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final blurSigma = headerStyle.blurSigma ?? 0;
    final headerRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _getBackButtonView(context, headerStyle, colorPalette),
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(left: spacing.padding4 ?? 0),
            child: _getListItem(context),
          ),
        ),
        if (widget.listItemView != null && widget.trailingView != null)
          ...?widget.trailingView!(_user, _group, context),
      ],
    );

    if (blurSigma > 0) {
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          headerStyle.backgroundColor ??
                          colorPalette.background1,
                      border: headerStyle.border,
                      borderRadius:
                          headerStyle.borderRadius ?? BorderRadius.zero,
                      boxShadow: headerStyle.boxShadow,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              height: widget.height ?? 65,
              padding:
                  widget.padding ??
                  EdgeInsets.only(left: spacing.padding4 ?? 0),
              child: headerRow,
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: Container(
        height: widget.height,
        width: _cachedWidth,
        padding:
            widget.padding ?? EdgeInsets.only(left: spacing.padding4 ?? 0),
        decoration: BoxDecoration(
          color: headerStyle.backgroundColor ?? colorPalette.background1,
          border: headerStyle.border,
          borderRadius: headerStyle.borderRadius ?? BorderRadius.circular(0),
          boxShadow: headerStyle.boxShadow,
        ),
        child: headerRow,
      ),
    );
  }

  Widget _getBackButtonView(
    BuildContext context,
    ConvoKitMessageHeaderStyle style,
    ConvoKitColorPalette colorPalette,
  ) {
    if (widget.showBackButton == true) {
      if (widget.backButton != null) {
        return widget.backButton!(context);
      }
      return Semantics(
        button: true,
        label: cc.Translations.of(context).back,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onBack ?? () => Navigator.pop(context),
          child:
              style.backIcon ??
              Image.asset(
                AssetConstants.back,
                excludeFromSemantics: true,
                package: UIConstants.packageName,
                color: style.backIconColor ?? colorPalette.iconPrimary,
                width: 24,
                height: 24,
              ),
        ),
      );
    }
    return const SizedBox(height: 0, width: 0);
  }

  Widget _getTypingIndicator(
    BuildContext context,
    TextStyle? typingIndicatorTextStyle,
    ConvoKitTypography typography,
    Color? color,
  ) {
    final String text;
    if (_user != null) {
      text = cc.Translations.of(context).typing;
    } else {
      final firstName = _typingUsers.isNotEmpty ? _typingUsers.first.name : '';
      text = "$firstName: ${cc.Translations.of(context).typing}";
    }
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: typography.caption1?.regular?.fontSize,
        color: color,
        fontWeight: typography.caption1?.regular?.fontWeight,
      ).merge(typingIndicatorTextStyle),
    );
  }

  Widget? _getSubtitleView(
    BuildContext context,
    ConvoKitMessageHeaderStyle style,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
  ) {
    final subtitleStyle = TextStyle(
      color:
          style.subtitleTextColor ??
          style.subtitleTextStyle?.color ??
          colorPalette.textSecondary,
      fontSize:
          style.subtitleTextStyle?.fontSize ??
          typography.caption1?.regular?.fontSize,
      fontFamily:
          style.subtitleTextStyle?.fontFamily ??
          typography.caption1?.regular?.fontFamily,
      fontWeight:
          style.subtitleTextStyle?.fontWeight ??
          typography.caption1?.regular?.fontWeight,
    );

    final userIsNotBlocked = !(_user?.isBlocked ?? false);
    final isTyping = _typingEnabled && _typingUsers.isNotEmpty;

    if (isTyping && userIsNotBlocked) {
      return _getTypingIndicator(
        context,
        style.typingIndicatorTextStyle,
        typography,
        colorPalette.primary,
      );
    }
    if (widget.subtitleView != null) {
      return widget.subtitleView!(_group, _user, context);
    }
    if (_user != null) {
      if (widget.usersStatusVisibility == true && userIsNotBlocked) {
        final statusText = _presence == UserPresence.online
            ? cc.Translations.of(context).online
            : cc.Translations.of(context).offline;
        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: CometChatMarquee(
                velocity: 30,
                text: statusText,
                style: subtitleStyle,
              ),
            );
          },
        );
      }
      return null;
    }
    final memberCount = _group?.memberCount ?? 0;
    return Text(
      '$memberCount ${memberCount == 1 ? cc.Translations.of(context).member : cc.Translations.of(context).members}',
      style: subtitleStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _getListItem(BuildContext context) {
    if (widget.listItemView != null) {
      return GestureDetector(
        onTap: widget.onHeaderTap,
        child: widget.listItemView!(_group, _user, context),
      );
    }

    if (_user == null && _group == null) {
      return const SizedBox.shrink();
    }

    final ChatUser? effectiveUser = _user != null
        ? ChatUser(
            id: _user!.id,
            name: _user!.name,
            avatarUrl: _user!.avatarUrl,
            presence: _presence,
            isBlocked: _user!.isBlocked,
          )
        : null;

    final avatarName = effectiveUser?.name ?? _group?.name;
    final avatarUrl = effectiveUser?.avatarUrl ?? _group?.avatarUrl;
    final title = avatarName;

    final userIsNotBlocked = !(effectiveUser?.isBlocked ?? false);
    final hideUserPresence =
        effectiveUser != null &&
        (widget.usersStatusVisibility == false || !userIsNotBlocked);

    final util = StatusIndicatorUtils.getStatusIndicatorFromParams(
      context: context,
      user: effectiveUser,
      group: _group,
      privateGroupIcon: headerStyle.privateGroupBadgeIcon,
      protectedGroupIcon: headerStyle.passwordProtectedGroupBadgeIcon,
      onlineStatusIndicatorColor:
          statusIndicatorStyle.backgroundColor ??
          headerStyle.onlineStatusColor ??
          colorPalette.success,
      usersStatusVisibility: !hideUserPresence,
      groupTypeVisibility: true,
      privateGroupIconBackground: headerStyle.privateGroupBadgeIconColor,
      protectedGroupIconBackground:
          headerStyle.passwordProtectedGroupBadgeIconColor,
    );

    final leadingStateView = widget.leadingStateView?.call(
      _group,
      effectiveUser,
      context,
    );
    final titleView = widget.titleView?.call(_group, effectiveUser, context);
    final subtitleView = _getSubtitleView(
      context,
      headerStyle,
      colorPalette,
      typography,
    );

    final tailWidgetList = <Widget>[];
    final auxiliaryHeaderMenu = widget.auxiliaryButtonView?.call(
      _group,
      effectiveUser,
      context,
    );
    if (auxiliaryHeaderMenu != null) {
      tailWidgetList.add(auxiliaryHeaderMenu);
    }
    if (widget.trailingView != null) {
      final trailing = widget.trailingView!(effectiveUser, _group, context);
      if (trailing != null) {
        tailWidgetList.addAll(trailing);
      }
    }
    if (_showOverflowMenu) {
      tailWidgetList.add(_buildOverflowMenu(headerStyle, colorPalette));
    }

    Widget? tailView;
    if (tailWidgetList.isNotEmpty) {
      tailView = Padding(
        padding: EdgeInsets.only(
          left: spacing.padding3 ?? 0,
          top: spacing.padding2 ?? 0,
          bottom: spacing.padding2 ?? 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: tailWidgetList,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onHeaderTap,
      child: ConvoKitListItem(
        avatarName: avatarName,
        avatarURL: avatarUrl,
        avatarWidth: widget.avatarWidth ?? 40,
        avatarHeight: widget.avatarHeight ?? 40,
        title: title,
        subtitleView: subtitleView,
        titlePadding: EdgeInsets.only(left: spacing.padding2 ?? 0),
        avatarStyle: ConvoKitAvatarStyle(
          backgroundColor: _group != null
              ? headerStyle.groupIconBackgroundColor
              : null,
        ).merge(headerStyle.avatarStyle),
        statusIndicatorColor: util.statusIndicatorColor,
        statusIndicatorIcon: util.icon,
        statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
          border: Border.all(
            width: spacing.spacing ?? 0,
            color: colorPalette.background1 ?? Colors.white,
          ),
          backgroundColor: colorPalette.success,
        ).merge(statusIndicatorStyle),
        hideSeparator: true,
        tailView: tailView,
        titleView: titleView,
        leadingStateView: leadingStateView,
        style:
            widget.listItemStyle ??
            ListItemStyle(
              background: Colors.transparent,
              height: 56,
              titleStyle: TextStyle(
                fontSize:
                    headerStyle.titleTextStyle?.fontSize ??
                    typography.heading4?.medium?.fontSize,
                fontWeight:
                    headerStyle.titleTextStyle?.fontWeight ??
                    typography.heading4?.medium?.fontWeight,
                fontFamily:
                    headerStyle.titleTextStyle?.fontFamily ??
                    typography.heading4?.medium?.fontFamily,
                color:
                    headerStyle.titleTextColor ??
                    headerStyle.titleTextStyle?.color ??
                    colorPalette.textPrimary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ),
    );
  }
}
