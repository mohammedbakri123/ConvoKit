import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:convokit/convokit_uikit.dart' as cc;
import 'package:flutter/material.dart';

/// Full-screen user search widget backed by `UserRepository.searchUsers` via
/// [ConvoKitScope].
///
/// Per `API-DESIGN.md` §13, v1 search is user search only and visibility is
/// gated on `ConvoKitScope.of(context).capabilities.search`. When
/// `capabilities.search` is `false`, this widget renders [SizedBox.shrink]
/// without invoking [UserRepository.searchUsers].
class CometChatSearch extends StatefulWidget {
  const CometChatSearch({
    super.key,
    this.onBack,
    this.onUserClicked,
    this.onEmpty,
    this.onError,
    this.onUsersLoad,
    this.user,
    this.group,
    this.searchStyle,
    this.searchBackIcon,
    this.searchClearIcon,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.initialStateView,
    this.userItemView,
    this.userTitleView,
    this.userLeadingView,
    this.userSubtitleView,
    this.userTailView,
    this.usersStatusVisibility = true,
    this.pageLimit = 30,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final VoidCallback? onBack;
  final void Function(ChatUser user)? onUserClicked;
  final OnError? onError;
  final OnLoad<ChatUser>? onUsersLoad;
  final OnEmpty? onEmpty;
  final ChatUser? user;
  final ChatGroup? group;
  final CometChatSearchStyle? searchStyle;
  final Widget? searchBackIcon;
  final Widget? searchClearIcon;
  final WidgetBuilder? loadingStateView;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final WidgetBuilder? initialStateView;
  final Widget? Function(BuildContext, ChatUser)? userItemView;
  final Widget? Function(BuildContext, ChatUser)? userTitleView;
  final Widget? Function(BuildContext, ChatUser)? userLeadingView;
  final Widget? Function(BuildContext, ChatUser)? userSubtitleView;
  final Widget? Function(BuildContext, ChatUser)? userTailView;
  final bool? usersStatusVisibility;
  final int pageLimit;
  final Duration debounceDuration;

  @override
  State<CometChatSearch> createState() => _CometChatSearchState();
}

enum _UserSearchStatus { initial, loading, loaded, empty, error }

class _CometChatSearchState extends State<CometChatSearch> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  // Theme caching
  late ConvoKitColorPalette colorPalette;
  late ConvoKitSpacing spacing;
  late ConvoKitTypography typography;
  late CometChatSearchStyle style;
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  // Search state
  ConvoKit? _kit;
  Timer? _debounceTimer;
  int _requestSeq = 0;
  String _searchText = '';
  _UserSearchStatus _status = _UserSearchStatus.initial;
  List<ChatUser> _users = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  ChatError? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      _kit = ConvoKitScope.of(context);
    } on StateError {
      _kit = null;
    }

    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      colorPalette = ConvoKitThemeHelper.getColorPalette(context);
      spacing = ConvoKitThemeHelper.getSpacing(context);
      typography = ConvoKitThemeHelper.getTypography(context);
      style = ConvoKitThemeHelper.getTheme<CometChatSearchStyle>(
        context: context,
        defaultTheme: CometChatSearchStyle.of,
      ).merge(widget.searchStyle);
      _themeInitialized = true;
    }
  }

  @override
  void didUpdateWidget(CometChatSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchStyle != oldWidget.searchStyle) {
      style = ConvoKitThemeHelper.getTheme<CometChatSearchStyle>(
        context: context,
        defaultTheme: CometChatSearchStyle.of,
      ).merge(widget.searchStyle);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requestSeq++;
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounceTimer?.cancel();
    final trimmed = raw.trim();

    if (trimmed.isEmpty) {
      _requestSeq++;
      setState(() {
        _searchText = '';
        _status = _UserSearchStatus.initial;
        _users = const [];
        _nextCursor = null;
        _hasMore = false;
        _isLoadingMore = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _searchText = raw;
    });

    if (widget.debounceDuration == Duration.zero) {
      unawaited(_runSearch(trimmed));
    } else {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (!mounted) return;
        unawaited(_runSearch(trimmed));
      });
    }
  }

  Future<void> _runSearch(String query) async {
    final kit = _kit;
    if (kit == null || !kit.capabilities.search) return;

    final seq = ++_requestSeq;
    setState(() {
      _status = _UserSearchStatus.loading;
      _error = null;
      _isLoadingMore = false;
    });

    try {
      final result = await kit.users.searchUsers(
        query,
        limit: widget.pageLimit,
      );
      if (!mounted || seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          final items = page.items;
          setState(() {
            _users = items;
            _nextCursor = page.olderCursor;
            _hasMore = page.hasOlder;
            _status = items.isEmpty
                ? _UserSearchStatus.empty
                : _UserSearchStatus.loaded;
          });
          if (items.isEmpty) {
            widget.onEmpty?.call();
          } else {
            widget.onUsersLoad?.call(items);
          }
        },
        onFailure: (err) {
          setState(() {
            _error = err;
            _users = const [];
            _nextCursor = null;
            _hasMore = false;
            _status = _UserSearchStatus.error;
          });
          widget.onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      final err = ChatError(ChatErrorCode.unknown, e.toString());
      setState(() {
        _error = err;
        _users = const [];
        _nextCursor = null;
        _hasMore = false;
        _status = _UserSearchStatus.error;
      });
      widget.onError?.call(Exception(err.message));
    }
  }

  Future<void> _loadMore() async {
    final kit = _kit;
    if (kit == null || !kit.capabilities.search) return;
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    final seq = _requestSeq;
    setState(() => _isLoadingMore = true);

    try {
      final result = await kit.users.searchUsers(
        _searchText.trim(),
        cursor: _nextCursor,
        limit: widget.pageLimit,
      );
      if (!mounted || seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          final merged = [..._users, ...page.items];
          setState(() {
            _users = merged;
            _nextCursor = page.olderCursor;
            _hasMore = page.hasOlder;
            _isLoadingMore = false;
          });
          if (page.items.isNotEmpty) {
            widget.onUsersLoad?.call(merged);
          }
        },
        onFailure: (err) {
          setState(() {
            _isLoadingMore = false;
            _error = err;
          });
          widget.onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _isLoadingMore = false);
      widget.onError?.call(Exception(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_kit != null && !_kit!.capabilities.search) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: style.backgroundColor ?? colorPalette.background1,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing.padding3 ?? 0,
            horizontal: spacing.padding4 ?? 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.padding3 ?? 0),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        keyboardAppearance:
            ConvoKitThemeHelper.getBrightness(context) == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
        onChanged: _onSearchChanged,
        style: TextStyle(
          color: style.searchTextColor ?? colorPalette.textPrimary,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style.searchTextStyle).copyWith(color: style.searchTextColor),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.padding3 ?? 0,
            vertical: spacing.padding2 ?? 0,
          ),
          hintText: (widget.user != null || widget.group != null)
              ? "${cc.Translations.of(context).search} in ${widget.user?.name ?? widget.group?.name ?? ""}"
              : cc.Translations.of(context).search,
          prefixIcon: Semantics(
            button: true,
            label: cc.Translations.of(context).back,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Navigator.of(context).pop(),
              child:
                  widget.searchBackIcon ??
                  Icon(
                    Icons.arrow_back,
                    color:
                        style.searchBackIconColor ?? colorPalette.iconSecondary,
                    size: 24,
                  ),
            ),
          ),
          suffixIcon: _searchText.isEmpty
              ? const SizedBox(width: 24)
              : Semantics(
                  button: true,
                  label: cc.Translations.of(context).clearSearch,
                  child: GestureDetector(
                    onTap: () {
                      _textController.clear();
                      _onSearchChanged('');
                    },
                    child:
                        widget.searchClearIcon ??
                        Icon(
                          Icons.close,
                          color:
                              style.searchClearIconColor ??
                              colorPalette.iconSecondary,
                          size: 24,
                        ),
                  ),
                ),
          hintStyle:
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
          focusedBorder: _searchBorder(),
          enabledBorder: _searchBorder(),
          border: _searchBorder(),
          fillColor: style.searchBackgroundColor ?? colorPalette.background3,
          filled: true,
        ),
      ),
    );
  }

  OutlineInputBorder _searchBorder() {
    return OutlineInputBorder(
      borderSide:
          style.searchBorder ??
          BorderSide(
            color: colorPalette.borderDark ?? Colors.transparent,
            width: 1,
          ),
      borderRadius:
          style.searchBorderRadius ??
          BorderRadius.circular(spacing.radiusMax ?? 0),
    );
  }

  Widget _buildResults() {
    switch (_status) {
      case _UserSearchStatus.initial:
        return widget.initialStateView?.call(context) ??
            const SizedBox.shrink();
      case _UserSearchStatus.loading:
        return widget.loadingStateView?.call(context) ?? _buildLoadingView();
      case _UserSearchStatus.empty:
        return widget.emptyStateView?.call(context) ?? _buildEmptyView();
      case _UserSearchStatus.error:
        return widget.errorStateView?.call(context) ?? _buildErrorView();
      case _UserSearchStatus.loaded:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _sectionHeader(cc.Translations.of(context).users),
            for (final user in _users) _buildUserItem(user),
            if (_isLoadingMore) _buildSectionLoading(),
            if (!_isLoadingMore && _hasMore)
              _seeMoreButton(onTap: _loadMore),
          ],
        );
    }
  }

  Widget _buildUserItem(ChatUser user) {
    if (widget.userItemView != null) {
      final customView = widget.userItemView!(context, user);
      if (customView == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => widget.onUserClicked?.call(user),
        child: customView,
      );
    }

    final statusIndicatorUtils =
        StatusIndicatorUtils.getStatusIndicatorFromParams(
          context: context,
          isSelected: false,
          user: user,
          onlineStatusIndicatorColor:
              style.statusIndicatorStyle?.backgroundColor ??
              colorPalette.success,
          usersStatusVisibility: widget.usersStatusVisibility ?? true,
          groupTypeVisibility: false,
        );

    return GestureDetector(
      onTap: () => widget.onUserClicked?.call(user),
      child: ConvoKitListItem(
        avatarHeight: 48,
        avatarWidth: 48,
        id: user.id,
        avatarName: user.name,
        avatarURL: user.avatarUrl,
        title: user.name,
        avatarStyle: style.avatarStyle ?? const ConvoKitAvatarStyle(),
        statusIndicatorColor: statusIndicatorUtils.statusIndicatorColor,
        statusIndicatorIcon: statusIndicatorUtils.icon,
        statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
          border: Border.all(
            width: spacing.spacing ?? 0,
            color: colorPalette.background1 ?? Colors.transparent,
          ),
          backgroundColor: colorPalette.success,
        ).merge(style.statusIndicatorStyle),
        hideSeparator: true,
        contentPadding: EdgeInsets.zero,
        style: ListItemStyle(
          background:
              style.searchConversationItemBackgroundColor ??
              colorPalette.transparent,
          titleStyle:
              TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: typography.heading4?.medium?.fontSize,
                    fontWeight: typography.heading4?.medium?.fontWeight,
                    fontFamily: typography.heading4?.medium?.fontFamily,
                    color:
                        style.searchConversationTitleTextColor ??
                        colorPalette.textPrimary,
                  )
                  .merge(style.searchConversationTitleTextStyle)
                  .copyWith(color: style.searchConversationTitleTextColor),
          padding: EdgeInsets.symmetric(vertical: spacing.padding3 ?? 0),
        ),
        subtitleView: widget.userSubtitleView?.call(context, user),
        tailView: widget.userTailView?.call(context, user),
        leadingStateView: widget.userLeadingView?.call(context, user),
        titleView: widget.userTitleView?.call(context, user),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.padding2 ?? 0),
      child: Text(
        title,
        style:
            TextStyle(
                  color:
                      style.sectionHeaderTextColor ??
                      colorPalette.textSecondary,
                  fontSize: typography.caption1?.medium?.fontSize,
                  fontWeight: typography.caption1?.medium?.fontWeight,
                  fontFamily: typography.caption1?.medium?.fontFamily,
                )
                .merge(style.sectionHeaderTextStyle)
                .copyWith(color: style.sectionHeaderTextColor),
      ),
    );
  }

  Widget _seeMoreButton({required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.padding2 ?? 0),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          cc.Translations.of(context).more,
          style:
              TextStyle(
                    color: style.seeMoreTextColor ?? colorPalette.primary,
                    fontSize: typography.body?.medium?.fontSize,
                    fontWeight: typography.body?.medium?.fontWeight,
                    fontFamily: typography.body?.medium?.fontFamily,
                  )
                  .merge(style.seeMoreTextStyle)
                  .copyWith(color: style.seeMoreTextColor),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return ConvoKitShimmerEffect(
      colorPalette: colorPalette,
      child: ListView.builder(
        itemCount: 10,
        shrinkWrap: true,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.padding4 ?? 0,
            vertical: spacing.padding3 ?? 0,
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.4,
                      height: 19,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(
                          spacing.radius2 ?? 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 16,
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
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: spacing.padding5 ?? 0),
            child: Image.asset(
              AssetConstants.conversationEmpty,
              package: UIConstants.packageName,
              height: 120,
              width: 120,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: spacing.padding1 ?? 0),
            child: Text(
              cc.Translations.of(context).noRecordsFound,
              style: TextStyle(
                color: style.emptyStateTextColor ?? colorPalette.textPrimary,
                fontSize: typography.heading3?.bold?.fontSize,
                fontWeight: typography.heading3?.bold?.fontWeight,
                fontFamily: typography.heading3?.bold?.fontFamily,
              ).merge(style.emptyStateTextStyle),
            ),
          ),
          if (_searchText.isNotEmpty)
            Text(
              '${cc.Translations.of(context).search} "$_searchText"',
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
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: spacing.padding5 ?? 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorPalette.error,
            ),
            SizedBox(height: spacing.padding3 ?? 0),
            Text(
              _error?.message.isNotEmpty == true
                  ? _error!.message
                  : cc.Translations.of(context).somethingWentWrongError,
              style: TextStyle(
                color: style.errorStateTextColor ?? colorPalette.textPrimary,
                fontSize: typography.heading4?.medium?.fontSize,
                fontWeight: typography.heading4?.medium?.fontWeight,
                fontFamily: typography.heading4?.medium?.fontFamily,
              ).merge(style.errorStateTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.padding3 ?? 0),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: colorPalette.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
