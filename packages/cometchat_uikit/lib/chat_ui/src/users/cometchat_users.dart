import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';
import '../../../convokit_uikit.dart' as cc;

/// [ConvoKitUsers] displays a paginated, searchable list of [ChatUser]s
/// backed directly by [UserRepository] via [ConvoKitScope].
///
/// Search input visibility is gated on `ConvoKitScope.of(context).capabilities.search`.
/// User online presence updates are observed from [EventHub.presenceRegistry].
class ConvoKitUsers extends StatefulWidget {
  const ConvoKitUsers({
    super.key,
    this.usersStyle = const ConvoKitUsersStyle(),
    this.scrollController,
    this.searchPlaceholder,
    this.backButton,
    this.showBackButton = true,
    this.searchBoxIcon,
    this.hideSearch = false,
    this.selectionMode,
    this.onSelection,
    this.title,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.appBarOptions,
    this.usersStatusVisibility = true,
    this.activateSelection,
    this.onError,
    this.onBack,
    this.onItemTap,
    this.onItemLongPress,
    this.setOptions,
    this.addOptions,
    this.submitIcon,
    this.hideAppbar = false,
    this.height,
    this.width,
    this.stickyHeaderVisibility = false,
    this.searchKeyword,
    this.onLoad,
    this.onEmpty,
    this.subtitleView,
    this.listItemView,
    this.titleView,
    this.leadingView,
    this.trailingView,
    this.pageLimit = 30,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final Widget? Function(BuildContext, ChatUser)? subtitleView;
  final Widget Function(ChatUser)? listItemView;
  final ConvoKitUsersStyle usersStyle;
  final ScrollController? scrollController;
  final String? searchPlaceholder;
  final Widget? backButton;
  final bool showBackButton;
  final Widget? searchBoxIcon;
  final bool hideSearch;
  final SelectionMode? selectionMode;
  final Function(List<ChatUser>?, BuildContext)? onSelection;
  final String? title;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final List<Widget> Function(BuildContext context)? appBarOptions;
  final bool? usersStatusVisibility;
  final ActivateSelection? activateSelection;
  final OnError? onError;
  final VoidCallback? onBack;
  final Function(BuildContext context, ChatUser)? onItemTap;
  final Function(BuildContext context, ChatUser)? onItemLongPress;

  /// [setOptions] sets the list of actions a long press on a user offers.
  /// When it is set, [addOptions] is ignored. Starting a long-press selection
  /// comes first, then [onItemLongPress], when set, takes the long press instead.
  final List<CometChatOption>? Function(
    ChatUser user,
    BuildContext context,
  )?
  setOptions;

  /// [addOptions] adds to the actions a long press on a user offers.
  final List<CometChatOption>? Function(
    ChatUser user,
    BuildContext context,
  )?
  addOptions;

  final Widget? submitIcon;
  final bool? hideAppbar;
  final double? height;
  final double? width;
  final bool? stickyHeaderVisibility;
  final String? searchKeyword;
  final OnLoad<ChatUser>? onLoad;
  final OnEmpty? onEmpty;
  final Widget? Function(BuildContext context, ChatUser user)? trailingView;
  final Widget? Function(BuildContext context, ChatUser user)? leadingView;
  final Widget? Function(BuildContext context, ChatUser user)? titleView;
  final int pageLimit;
  final Duration debounceDuration;

  @override
  State<ConvoKitUsers> createState() => ConvoKitUsersState();
}

enum _UsersLoadStatus { loading, loaded, empty, error }

class ConvoKitUsersState extends State<ConvoKitUsers>
    with AutomaticKeepAliveClientMixin {
  ConvoKit? _kit;
  EventHub? _hub;
  StreamSubscription<Map<String, UserPresence>>? _presenceSub;
  Map<String, UserPresence> _presenceMap = const {};

  Timer? _debounceTimer;
  int _requestSeq = 0;
  String _searchKeyword = '';
  _UsersLoadStatus _status = _UsersLoadStatus.loading;
  List<ChatUser> _users = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  ChatError? _error;
  final Set<String> _selectedUserIds = <String>{};
  _UsersLoadStatus? _lastReportedStatus;

  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  @override
  bool get wantKeepAlive => true;

  late ConvoKitColorPalette colorPalette;
  late ConvoKitTypography typography;
  late ConvoKitSpacing spacing;
  late ConvoKitUsersStyle style;
  late ConvoKitAvatarStyle avatarStyle;
  late ConvoKitStatusIndicatorStyle statusIndicatorStyle;

  @override
  void initState() {
    super.initState();
    _searchKeyword = widget.searchKeyword?.trim() ?? '';
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

    final kitChanged = !identical(_kit, newKit);
    if (kitChanged) {
      _kit = newKit;
      _hub = newHub;
      _bindPresence();
      unawaited(_loadUsers(reset: true));
    }

    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      _themeInitialized = true;

      typography = ConvoKitThemeHelper.getTypography(context);
      colorPalette = ConvoKitThemeHelper.getColorPalette(context);
      spacing = ConvoKitThemeHelper.getSpacing(context);
      _resolveStyles();
    }
  }

  @override
  void didUpdateWidget(covariant ConvoKitUsers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usersStyle != widget.usersStyle) {
      _resolveStyles();
    }
    if (oldWidget.searchKeyword != widget.searchKeyword) {
      _onSearchChanged(widget.searchKeyword ?? '');
    }
  }

  void _resolveStyles() {
    style = ConvoKitThemeHelper.getTheme<ConvoKitUsersStyle>(
      context: context,
      defaultTheme: ConvoKitUsersStyle.of,
    ).merge(widget.usersStyle);

    avatarStyle = ConvoKitThemeHelper.getTheme<ConvoKitAvatarStyle>(
      context: context,
      defaultTheme: ConvoKitAvatarStyle.of,
    ).merge(style.avatarStyle);

    statusIndicatorStyle =
        ConvoKitThemeHelper.getTheme<ConvoKitStatusIndicatorStyle>(
          context: context,
          defaultTheme: ConvoKitStatusIndicatorStyle.of,
        ).merge(style.statusIndicatorStyle);
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
    _debounceTimer?.cancel();
    _presenceSub?.cancel();
    _requestSeq++;
    super.dispose();
  }

  /// Fetches a single user by [userId] via [UserRepository.getUser] and
  /// updates the local list if present.
  Future<ChatUser?> fetchUser(String userId) async {
    final kit = _kit;
    if (kit == null) return null;
    final result = await kit.users.getUser(userId);
    ChatUser? fetched;
    result.fold(
      onSuccess: (user) {
        fetched = user;
        if (!mounted) return;
        final idx = _users.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          setState(() {
            final updated = List<ChatUser>.of(_users);
            updated[idx] = user;
            _users = updated;
          });
        }
      },
      onFailure: (err) {
        widget.onError?.call(Exception(err.message));
      },
    );
    return fetched;
  }

  /// Reloads the users list from the beginning.
  Future<void> refresh() => _loadUsers(reset: true);

  void _onSearchChanged(String raw) {
    _debounceTimer?.cancel();
    final trimmed = raw.trim();
    _searchKeyword = trimmed;

    final kit = _kit;
    if (trimmed.isNotEmpty && (kit == null || !kit.capabilities.search)) {
      return;
    }

    if (widget.debounceDuration == Duration.zero) {
      unawaited(_loadUsers(reset: true));
    } else {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (!mounted) return;
        unawaited(_loadUsers(reset: true));
      });
    }
  }

  Future<void> _loadUsers({required bool reset}) async {
    final kit = _kit;
    if (kit == null) {
      if (!mounted) return;
      setState(() {
        _status = _UsersLoadStatus.empty;
        _users = const [];
        _nextCursor = null;
        _hasMore = false;
        _isLoadingMore = false;
        _error = null;
      });
      _reportStatus(_UsersLoadStatus.empty);
      return;
    }

    if (!reset && (!_hasMore || _isLoadingMore)) return;

    final seq = ++_requestSeq;
    if (reset) {
      setState(() {
        _status = _UsersLoadStatus.loading;
        _error = null;
        _isLoadingMore = false;
        _nextCursor = null;
        _hasMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final useSearch = _searchKeyword.isNotEmpty && kit.capabilities.search;
    final cursor = reset ? null : _nextCursor;

    try {
      final result = useSearch
          ? await kit.users.searchUsers(
              _searchKeyword,
              cursor: cursor,
              limit: widget.pageLimit,
            )
          : await kit.users.listUsers(
              cursor: cursor,
              limit: widget.pageLimit,
            );

      if (!mounted || seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          final merged = reset
              ? List<ChatUser>.of(page.items)
              : <ChatUser>[..._users, ...page.items];
          final nextStatus = merged.isEmpty
              ? _UsersLoadStatus.empty
              : _UsersLoadStatus.loaded;
          setState(() {
            _users = merged;
            _nextCursor = page.olderCursor;
            _hasMore = page.hasOlder;
            _isLoadingMore = false;
            _error = null;
            _status = nextStatus;
          });
          _reportStatus(nextStatus);
        },
        onFailure: (err) {
          if (reset) {
            setState(() {
              _error = err;
              _users = const [];
              _nextCursor = null;
              _hasMore = false;
              _isLoadingMore = false;
              _status = _UsersLoadStatus.error;
            });
            _reportStatus(_UsersLoadStatus.error, error: err);
          } else {
            setState(() {
              _isLoadingMore = false;
            });
            widget.onError?.call(Exception(err.message));
          }
        },
      );
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      final err = ChatError(ChatErrorCode.unknown, e.toString(), cause: e);
      if (reset) {
        setState(() {
          _error = err;
          _users = const [];
          _nextCursor = null;
          _hasMore = false;
          _isLoadingMore = false;
          _status = _UsersLoadStatus.error;
        });
        _reportStatus(_UsersLoadStatus.error, error: err);
      } else {
        setState(() {
          _isLoadingMore = false;
        });
        widget.onError?.call(Exception(err.message));
      }
    }
  }

  void _reportStatus(_UsersLoadStatus status, {ChatError? error}) {
    if (status == _lastReportedStatus) return;
    _lastReportedStatus = status;

    if (status == _UsersLoadStatus.error && error != null) {
      widget.onError?.call(Exception(error.message));
    } else if (status == _UsersLoadStatus.empty) {
      widget.onEmpty?.call();
    } else if (status == _UsersLoadStatus.loaded) {
      if (_users.isEmpty) {
        widget.onEmpty?.call();
      } else {
        widget.onLoad?.call(_users);
      }
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (widget.selectionMode == SelectionMode.single) {
        if (_selectedUserIds.contains(userId)) {
          _selectedUserIds.clear();
        } else {
          _selectedUserIds
            ..clear()
            ..add(userId);
        }
      } else {
        if (_selectedUserIds.contains(userId)) {
          _selectedUserIds.remove(userId);
        } else {
          _selectedUserIds.add(userId);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final searchAllowed = _kit?.capabilities.search ?? false;
    final effectiveHideSearch = widget.hideSearch || !searchAllowed;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: style.borderRadius ?? BorderRadius.circular(0),
        child: CometChatListBase(
          titleView: _buildTitleView(),
          titleSpacing: widget.showBackButton ? 0 : 16,
          hideSearch: effectiveHideSearch,
          backIcon: _buildBackIcon(),
          placeholder: widget.searchPlaceholder,
          showBackButton: widget.showBackButton,
          searchBoxIcon: widget.searchBoxIcon,
          onSearch: _onSearchChanged,
          hideAppBar: widget.hideAppbar,
          searchText: widget.searchKeyword,
          searchPadding: EdgeInsets.symmetric(
            horizontal: spacing.padding4 ?? 0,
            vertical: spacing.padding3 ?? 0,
          ),
          searchContentPadding: EdgeInsets.symmetric(
            horizontal: spacing.padding3 ?? 0,
            vertical: spacing.padding2 ?? 0,
          ),
          searchBoxHeight: 40,
          menuOptions: [
            if (widget.appBarOptions != null) ...widget.appBarOptions!(context),
            _getSelectionWidget(),
          ],
          onBack: widget.onBack,
          style: _buildListBaseStyle(),
          container: UsersList(
            isLoading: _status == _UsersLoadStatus.loading,
            isEmpty: _status == _UsersLoadStatus.empty,
            error: _status == _UsersLoadStatus.error ? _error : null,
            users: _users,
            hasMore: _hasMore,
            isLoadingMore: _isLoadingMore,
            selectedUserIds: _selectedUserIds,
            presenceMap: _presenceMap,
            onLoadMore: () => unawaited(_loadUsers(reset: false)),
            onRetry: () => unawaited(_loadUsers(reset: true)),
            onToggleSelection: _toggleSelection,
            style: style,
            colorPalette: colorPalette,
            spacing: spacing,
            typography: typography,
            scrollController: widget.scrollController,
            loadingStateView: widget.loadingStateView,
            emptyStateView: widget.emptyStateView,
            errorStateView: widget.errorStateView,
            listItemView: widget.listItemView,
            subtitleView: widget.subtitleView,
            trailingView: widget.trailingView,
            leadingView: widget.leadingView,
            titleView: widget.titleView,
            usersStatusVisibility: widget.usersStatusVisibility,
            selectionMode: widget.selectionMode,
            activateSelection: widget.activateSelection,
            onItemTap: widget.onItemTap,
            onItemLongPress: widget.onItemLongPress,
            options: widget.setOptions == null && widget.addOptions == null
                ? null
                : _longPressOptions,
            stickyHeaderVisibility: widget.stickyHeaderVisibility,
            avatarStyle: avatarStyle,
            statusIndicatorStyle: statusIndicatorStyle,
          ),
        ),
      ),
    );
  }

  List<CometChatOption> _longPressOptions(BuildContext context, ChatUser user) {
    final build = widget.setOptions ?? widget.addOptions!;
    return build(user, context) ?? const <CometChatOption>[];
  }

  Widget _buildTitleView() {
    final selectedCount = _selectedUserIds.length;
    return Text(
      selectedCount > 0
          ? '$selectedCount'
          : widget.title ?? cc.Translations.of(context).users,
      style: TextStyle(
        color: colorPalette.textPrimary,
        fontSize: typography.heading1?.bold?.fontSize,
        fontWeight: typography.heading1?.bold?.fontWeight,
        fontFamily: typography.heading1?.bold?.fontFamily,
      ).merge(style.titleTextStyle).copyWith(color: style.titleTextColor),
    );
  }

  Widget _buildBackIcon() {
    final hasSelection = _selectedUserIds.isNotEmpty;
    return hasSelection
        ? IconButton(
            tooltip: Translations.of(context).clearSearch,
            onPressed: _clearSelection,
            icon: Icon(
              Icons.clear,
              color: colorPalette.iconPrimary,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          )
        : (widget.backButton ??
              IconButton(
                tooltip: Translations.of(context).back,
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: style.backIconColor ?? colorPalette.iconPrimary,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
              ));
  }

  ListBaseStyle _buildListBaseStyle() {
    return ListBaseStyle(
      width: widget.width,
      height: widget.height,
      background: style.backgroundColor ?? colorPalette.background1,
      titleStyle: TextStyle(
        color: style.titleTextColor ?? colorPalette.textPrimary,
        fontSize: typography.heading1?.bold?.fontSize,
        fontWeight: typography.heading1?.bold?.fontWeight,
        fontFamily: typography.heading1?.bold?.fontFamily,
      ).merge(style.titleTextStyle),
      backIconTint: style.backIconColor ?? colorPalette.iconPrimary,
      searchIconTint: style.searchIconColor ?? colorPalette.iconSecondary,
      border: style.border,
      borderRadius: style.borderRadius,
      searchTextStyle: TextStyle(
        color: style.searchInputTextColor ?? colorPalette.textPrimary,
        fontSize: typography.heading4?.regular?.fontSize,
        fontWeight: typography.heading4?.regular?.fontWeight,
        fontFamily: typography.heading4?.regular?.fontFamily,
      ).merge(style.searchInputTextStyle),
      searchPlaceholderStyle: TextStyle(
        color: style.searchPlaceHolderTextColor ?? colorPalette.textTertiary,
        fontSize: typography.heading4?.regular?.fontSize,
        fontWeight: typography.heading4?.regular?.fontWeight,
        fontFamily: typography.heading4?.regular?.fontFamily,
      ).merge(style.searchPlaceHolderTextStyle),
      searchBoxBackground:
          style.searchBackgroundColor ?? colorPalette.background3,
      borderSide: style.searchBorder,
      searchTextFieldRadius:
          style.searchBorderRadius ??
          BorderRadius.circular(spacing.radiusMax ?? 0),
      appBarShape: Border(
        bottom: BorderSide(
          color:
              style.separatorColor ??
              colorPalette.borderLight ??
              Colors.transparent,
          width: style.separatorHeight ?? 1,
        ),
      ),
    );
  }

  Widget _getSelectionWidget() {
    if (_selectedUserIds.isNotEmpty) {
      return IconButton(
        tooltip: Translations.of(context).done,
        onPressed: () {
          final selectedUsers = _users
              .where((u) => _selectedUserIds.contains(u.id))
              .toList();
          widget.onSelection?.call(selectedUsers, context);
        },
        icon:
            widget.submitIcon ??
            Icon(
              Icons.check,
              color: style.submitIconColor ?? colorPalette.iconPrimary,
              size: 24,
            ),
      );
    }
    return const SizedBox.shrink();
  }
}
