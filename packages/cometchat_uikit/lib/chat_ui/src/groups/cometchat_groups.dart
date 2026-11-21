import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';
import '../../../convokit_uikit.dart' as cc;

/// [ConvoKitGroups] displays a paginated list of [ChatGroup]s backed by the
/// optional [GroupRepository] via [ConvoKitScope].
///
/// Gated on `kit.capabilities.groups && kit.groups != null`. When groups are
/// disabled or absent, renders an empty/disabled state cleanly without invoking
/// any repository methods or throwing null-check errors.
class ConvoKitGroups extends StatefulWidget {
  const ConvoKitGroups({
    super.key,
    this.subtitleView,
    this.listItemView,
    this.groupsStyle,
    this.scrollController,
    this.searchPlaceholder,
    this.backButton,
    this.showBackButton = true,
    this.searchBoxIcon,
    this.hideSearch = false,
    this.selectionMode,
    this.onSelection,
    this.title,
    this.hideError,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.appBarOptions,
    this.passwordGroupIcon,
    this.privateGroupIcon,
    this.activateSelection,
    this.onBack,
    this.onItemTap,
    this.onItemLongPress,
    this.setOptions,
    this.addOptions,
    this.onError,
    this.submitIcon,
    this.hideAppbar = false,
    this.height,
    this.width,
    this.searchKeyword,
    this.onLoad,
    this.onEmpty,
    this.groupTypeVisibility = true,
    this.titleView,
    this.leadingView,
    this.trailingView,
    this.pageLimit = 30,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final Widget? Function(BuildContext context, ChatGroup group)? subtitleView;
  final Widget Function(ChatGroup group)? listItemView;
  final ConvoKitGroupsStyle? groupsStyle;
  final ScrollController? scrollController;
  final String? searchPlaceholder;
  final Widget? backButton;
  final bool showBackButton;
  final Widget? searchBoxIcon;
  final bool hideSearch;
  final SelectionMode? selectionMode;
  final Function(List<ChatGroup>?)? onSelection;
  final String? title;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final bool? hideError;
  final List<Widget> Function(BuildContext context)? appBarOptions;
  final Widget? passwordGroupIcon;
  final Widget? privateGroupIcon;
  final ActivateSelection? activateSelection;
  final VoidCallback? onBack;
  final Function(BuildContext context, ChatGroup group)? onItemTap;
  final Function(BuildContext context, ChatGroup group)? onItemLongPress;

  /// [setOptions] sets the list of actions a long press on a group offers.
  /// [addOptions], when also set, is appended to it.
  final List<CometChatOption>? Function(
    ChatGroup group,
    BuildContext context,
  )?
  setOptions;

  /// [addOptions] appends to the actions a long press on a group offers.
  final List<CometChatOption>? Function(
    ChatGroup group,
    BuildContext context,
  )?
  addOptions;

  final Widget? submitIcon;
  final bool? hideAppbar;
  final OnError? onError;
  final double? height;
  final double? width;
  final String? searchKeyword;
  final OnLoad<ChatGroup>? onLoad;
  final OnEmpty? onEmpty;
  final bool? groupTypeVisibility;
  final Widget? Function(BuildContext context, ChatGroup group)? trailingView;
  final Widget? Function(BuildContext context, ChatGroup group)? leadingView;
  final Widget? Function(BuildContext context, ChatGroup group)? titleView;
  final int pageLimit;
  final Duration debounceDuration;

  @override
  State<ConvoKitGroups> createState() => ConvoKitGroupsState();
}

enum _GroupsLoadStatus { loading, loaded, empty, error, disabled }

class ConvoKitGroupsState extends State<ConvoKitGroups>
    with AutomaticKeepAliveClientMixin {
  ConvoKit? _kit;
  Timer? _debounceTimer;
  int _requestSeq = 0;
  String _searchKeyword = '';
  _GroupsLoadStatus _status = _GroupsLoadStatus.loading;
  List<ChatGroup> _allGroups = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  ChatError? _error;
  final Set<String> _selectedGroupIds = <String>{};
  _GroupsLoadStatus? _lastReportedStatus;

  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  @override
  bool get wantKeepAlive => true;

  late ConvoKitColorPalette colorPalette;
  late ConvoKitTypography typography;
  late ConvoKitSpacing spacing;
  late ConvoKitGroupsStyle style;
  late ConvoKitAvatarStyle avatarStyle;
  late ConvoKitStatusIndicatorStyle statusIndicatorStyle;

  GroupRepository? get _groupsRepo {
    final kit = _kit;
    if (kit == null || !kit.capabilities.groups) return null;
    return kit.groups;
  }

  List<ChatGroup> get _visibleGroups {
    if (_searchKeyword.isEmpty) return _allGroups;
    final needle = _searchKeyword.toLowerCase();
    return _allGroups
        .where(
          (g) =>
              g.name.toLowerCase().contains(needle) ||
              (g.description?.toLowerCase().contains(needle) ?? false),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchKeyword = widget.searchKeyword?.trim() ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ConvoKit? newKit;
    try {
      newKit = ConvoKitScope.of(context);
    } on StateError {
      newKit = null;
    }

    if (!identical(_kit, newKit)) {
      _kit = newKit;
      unawaited(_loadGroups(reset: true));
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
  void didUpdateWidget(covariant ConvoKitGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupsStyle != widget.groupsStyle) _resolveStyles();
    if (oldWidget.searchKeyword != widget.searchKeyword) {
      _onSearchChanged(widget.searchKeyword ?? '');
    }
  }

  void _resolveStyles() {
    style = ConvoKitThemeHelper.getTheme<ConvoKitGroupsStyle>(
      context: context,
      defaultTheme: ConvoKitGroupsStyle.of,
    ).merge(widget.groupsStyle);

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requestSeq++;
    super.dispose();
  }

  /// Reloads the groups list from the beginning.
  Future<void> refresh() => _loadGroups(reset: true);

  /// Fetches a single group by [groupId] via [GroupRepository.getGroup] and
  /// updates it in the local list if present.
  Future<ChatGroup?> fetchGroup(String groupId) async {
    final repo = _groupsRepo;
    if (repo == null) return null;
    final result = await repo.getGroup(groupId);
    ChatGroup? fetched;
    result.fold(
      onSuccess: (group) {
        fetched = group;
        if (!mounted) return;
        final idx = _allGroups.indexWhere((g) => g.id == group.id);
        if (idx != -1) {
          setState(() {
            final updated = List<ChatGroup>.of(_allGroups);
            updated[idx] = group;
            _allGroups = updated;
          });
        }
      },
      onFailure: (err) {
        widget.onError?.call(Exception(err.message));
      },
    );
    return fetched;
  }

  /// Joins [groupId] via [GroupRepository.joinGroup] and refreshes the group.
  Future<ChatResult<void>> joinGroup(String groupId) async {
    final repo = _groupsRepo;
    if (repo == null) {
      return const ChatFailure(
        ChatError(ChatErrorCode.unsupported, 'Groups capability is disabled'),
      );
    }
    final result = await repo.joinGroup(groupId);
    result.fold(
      onSuccess: (_) => unawaited(fetchGroup(groupId)),
      onFailure: (err) => widget.onError?.call(Exception(err.message)),
    );
    return result;
  }

  /// Leaves [groupId] via [GroupRepository.leaveGroup] and refreshes the group.
  Future<ChatResult<void>> leaveGroup(String groupId) async {
    final repo = _groupsRepo;
    if (repo == null) {
      return const ChatFailure(
        ChatError(ChatErrorCode.unsupported, 'Groups capability is disabled'),
      );
    }
    final result = await repo.leaveGroup(groupId);
    result.fold(
      onSuccess: (_) => unawaited(fetchGroup(groupId)),
      onFailure: (err) => widget.onError?.call(Exception(err.message)),
    );
    return result;
  }

  void _onSearchChanged(String raw) {
    _debounceTimer?.cancel();
    final trimmed = raw.trim();

    if (widget.debounceDuration == Duration.zero) {
      _applySearchFilter(trimmed);
    } else {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (!mounted) return;
        _applySearchFilter(trimmed);
      });
    }
  }

  void _applySearchFilter(String trimmed) {
    if (_groupsRepo == null) return;
    setState(() {
      _searchKeyword = trimmed;
      if (_status == _GroupsLoadStatus.loaded ||
          _status == _GroupsLoadStatus.empty) {
        _status = _visibleGroups.isEmpty
            ? _GroupsLoadStatus.empty
            : _GroupsLoadStatus.loaded;
      }
    });
  }

  Future<void> _loadGroups({required bool reset}) async {
    final repo = _groupsRepo;
    if (repo == null) {
      if (!mounted) return;
      setState(() {
        _status = _GroupsLoadStatus.disabled;
        _allGroups = const [];
        _nextCursor = null;
        _hasMore = false;
        _isLoadingMore = false;
        _error = null;
      });
      _reportStatus(_GroupsLoadStatus.disabled);
      return;
    }

    if (!reset && (!_hasMore || _isLoadingMore)) return;

    final seq = ++_requestSeq;
    if (reset) {
      setState(() {
        _status = _GroupsLoadStatus.loading;
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

    try {
      final result = await repo.listGroups(
        cursor: reset ? null : _nextCursor,
        limit: widget.pageLimit,
      );

      if (!mounted || seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          final merged = reset
              ? List<ChatGroup>.of(page.items)
              : <ChatGroup>[..._allGroups, ...page.items];
          _allGroups = merged;
          final visible = _visibleGroups;
          final nextStatus = visible.isEmpty
              ? _GroupsLoadStatus.empty
              : _GroupsLoadStatus.loaded;
          setState(() {
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
              _allGroups = const [];
              _nextCursor = null;
              _hasMore = false;
              _isLoadingMore = false;
              _status = _GroupsLoadStatus.error;
            });
            _reportStatus(_GroupsLoadStatus.error, error: err);
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
          _allGroups = const [];
          _nextCursor = null;
          _hasMore = false;
          _isLoadingMore = false;
          _status = _GroupsLoadStatus.error;
        });
        _reportStatus(_GroupsLoadStatus.error, error: err);
      } else {
        setState(() {
          _isLoadingMore = false;
        });
        widget.onError?.call(Exception(err.message));
      }
    }
  }

  void _reportStatus(_GroupsLoadStatus status, {ChatError? error}) {
    if (status == _lastReportedStatus) return;
    _lastReportedStatus = status;

    if (status == _GroupsLoadStatus.error && error != null) {
      widget.onError?.call(Exception(error.message));
    } else if (status == _GroupsLoadStatus.empty ||
        status == _GroupsLoadStatus.disabled) {
      widget.onEmpty?.call();
    } else if (status == _GroupsLoadStatus.loaded) {
      final visible = _visibleGroups;
      if (visible.isEmpty) {
        widget.onEmpty?.call();
      } else {
        widget.onLoad?.call(visible);
      }
    }
  }

  void _toggleSelection(String groupId) {
    setState(() {
      if (widget.selectionMode == SelectionMode.single) {
        if (_selectedGroupIds.contains(groupId)) {
          _selectedGroupIds.clear();
        } else {
          _selectedGroupIds
            ..clear()
            ..add(groupId);
        }
      } else {
        if (_selectedGroupIds.contains(groupId)) {
          _selectedGroupIds.remove(groupId);
        } else {
          _selectedGroupIds.add(groupId);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedGroupIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final groupsEnabled = _groupsRepo != null;
    final effectiveHideSearch = widget.hideSearch || !groupsEnabled;

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
            _buildSelectionWidget(),
          ],
          onBack: widget.onBack,
          style: _buildListBaseStyle(),
          container: GroupsList(
            groups: _visibleGroups,
            isLoading: _status == _GroupsLoadStatus.loading,
            isEmpty:
                _status == _GroupsLoadStatus.empty ||
                _status == _GroupsLoadStatus.disabled,
            error: _status == _GroupsLoadStatus.error ? _error : null,
            hasMore: _searchKeyword.isEmpty && _hasMore,
            isLoadingMore: _isLoadingMore,
            selectedGroupIds: _selectedGroupIds,
            onLoadMore: () => unawaited(_loadGroups(reset: false)),
            onRetry: () => unawaited(_loadGroups(reset: true)),
            onToggleSelection: _toggleSelection,
            style: style,
            colorPalette: colorPalette,
            spacing: spacing,
            typography: typography,
            scrollController: widget.scrollController,
            loadingStateView: widget.loadingStateView,
            emptyStateView: widget.emptyStateView,
            errorStateView: widget.errorStateView,
            hideError: widget.hideError,
            listItemView: widget.listItemView,
            subtitleView: widget.subtitleView,
            trailingView: widget.trailingView,
            leadingView: widget.leadingView,
            titleView: widget.titleView,
            hideGroupTypeIcon: !(widget.groupTypeVisibility ?? true),
            selectionMode: widget.selectionMode,
            activateSelection: widget.activateSelection,
            onItemTap: widget.onItemTap,
            onItemLongPress: widget.onItemLongPress,
            options: widget.setOptions == null && widget.addOptions == null
                ? null
                : _longPressOptions,
            avatarStyle: avatarStyle,
            statusIndicatorStyle: statusIndicatorStyle,
            privateGroupIcon: widget.privateGroupIcon,
            protectedGroupIcon: widget.passwordGroupIcon,
          ),
        ),
      ),
    );
  }

  List<CometChatOption> _longPressOptions(
    BuildContext context,
    ChatGroup group,
  ) => [
    ...?widget.setOptions?.call(group, context),
    ...?widget.addOptions?.call(group, context),
  ];

  Widget _buildTitleView() {
    final selectedCount = _selectedGroupIds.length;
    return Text(
      selectedCount > 0
          ? '$selectedCount'
          : widget.title ?? cc.Translations.of(context).groups,
      style: TextStyle(
        color: colorPalette.textPrimary,
        fontSize: typography.heading1?.bold?.fontSize,
        fontWeight: typography.heading1?.bold?.fontWeight,
        fontFamily: typography.heading1?.bold?.fontFamily,
      ).merge(style.titleTextStyle).copyWith(color: style.titleTextColor),
    );
  }

  Widget _buildBackIcon() {
    final hasSelection = _selectedGroupIds.isNotEmpty;
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
      ).merge(style.titleTextStyle).copyWith(color: style.titleTextColor),
      backIconTint: style.backIconColor ?? colorPalette.iconPrimary,
      searchIconTint: style.searchIconColor ?? colorPalette.iconSecondary,
      border: style.border,
      borderRadius: style.borderRadius,
      searchTextStyle:
          TextStyle(
                color: style.searchInputTextColor ?? colorPalette.textPrimary,
                fontSize: typography.heading4?.regular?.fontSize,
                fontWeight: typography.heading4?.regular?.fontWeight,
                fontFamily: typography.heading4?.regular?.fontFamily,
              )
              .merge(style.searchInputTextStyle)
              .copyWith(color: style.searchInputTextColor),
      searchPlaceholderStyle:
          TextStyle(
                color:
                    style.searchPlaceHolderTextColor ??
                    colorPalette.textTertiary,
                fontSize: typography.heading4?.regular?.fontSize,
                fontWeight: typography.heading4?.regular?.fontWeight,
                fontFamily: typography.heading4?.regular?.fontFamily,
              )
              .merge(style.searchPlaceHolderTextStyle)
              .copyWith(color: style.searchPlaceHolderTextColor),
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

  Widget _buildSelectionWidget() {
    if (_selectedGroupIds.isNotEmpty) {
      return IconButton(
        tooltip: Translations.of(context).done,
        onPressed: () {
          final selectedGroups = _allGroups
              .where((g) => _selectedGroupIds.contains(g.id))
              .toList();
          widget.onSelection?.call(selectedGroups);
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
