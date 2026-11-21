import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';

/// [ConvoKitConversations] displays all conversations for the signed-in user
/// by observing [EventHub.conversationStore], [EventHub.presenceRegistry], and
/// [EventHub.typingRegistry] directly via [ConvoKitScope].
///
/// Delivery receipt indicators are automatically hidden when
/// `ConvoKitScope.of(context).capabilities.receipts == false`.
class ConvoKitConversations extends StatefulWidget {
  final ListItemStyle? listItemStyle;

  const ConvoKitConversations({
    super.key,
    this.subtitleView,
    this.listItemView,
    this.conversationsStyle = const ConvoKitConversationsStyle(),
    this.scrollController,
    this.backButton,
    this.showBackButton = false,
    this.selectionMode,
    this.onSelection,
    this.title,
    this.hideError,
    this.emptyStateView,
    this.errorStateView,
    this.trailingView,
    this.appBarOptions,
    this.usersStatusVisibility = true,
    this.receiptsVisibility = true,
    this.protectedGroupIcon,
    this.privateGroupIcon,
    this.readIcon,
    this.deliveredIcon,
    this.sentIcon,
    this.activateSelection,
    this.datePattern,
    this.typingIndicatorText,
    this.onBack,
    this.onItemTap,
    this.onItemLongPress,
    this.hideAppbar = false,
    this.textFormatters,
    this.mentionAllLabel,
    this.mentionAllLabelId,
    this.datePadding,
    this.dateHeight,
    this.dateBackgroundIsTransparent,
    this.dateWidth,
    this.badgeWidth,
    this.badgeHeight,
    this.badgePadding,
    this.statusIndicatorWidth,
    this.statusIndicatorHeight,
    this.statusIndicatorBorderRadius,
    this.avatarMargin,
    this.avatarPadding,
    this.avatarWidth,
    this.avatarHeight,
    this.deleteConversationOptionVisibility = true,
    this.pinConversationOptionVisibility = true,
    this.groupTypeVisibility = true,
    this.setOptions,
    this.addOptions,
    this.loadingStateView,
    this.leadingView,
    this.titleView,
    this.onLoad,
    this.onEmpty,
    this.onError,
    this.customSoundForMessages,
    this.disableSoundForMessages = false,
    this.submitIcon,
    this.dateTimeFormatterCallback,
    this.routeObserver,
    this.hideSearch,
    this.searchReadOnly = false,
    this.onSearchTap,
    this.searchBoxIcon,
    this.searchPadding,
    this.searchContentPadding,
    this.listItemStyle,
    this.listPadding,
    this.pageLimit = 30,
  });

  final RouteObserver<ModalRoute<void>>? routeObserver;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      subtitleView;
  final Widget Function(ChatConversation conversation)? listItemView;
  final ConvoKitConversationsStyle conversationsStyle;
  final ScrollController? scrollController;
  final Widget? backButton;
  final bool showBackButton;
  final SelectionMode? selectionMode;
  final void Function(List<ChatConversation>?, BuildContext)? onSelection;
  final String? title;
  final bool? hideError;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      trailingView;
  final List<Widget> Function(BuildContext context)? appBarOptions;
  final bool? usersStatusVisibility;
  final bool? receiptsVisibility;
  final Widget? protectedGroupIcon;
  final Widget? privateGroupIcon;
  final Widget? readIcon;
  final Widget? deliveredIcon;
  final Widget? sentIcon;
  final ActivateSelection? activateSelection;
  final String Function(ChatConversation)? datePattern;
  final String? typingIndicatorText;
  final VoidCallback? onBack;
  final void Function(ChatConversation)? onItemTap;
  final void Function(ChatConversation)? onItemLongPress;
  final bool hideAppbar;
  final List<CometChatTextFormatter>? textFormatters;
  final String? mentionAllLabel;
  final String? mentionAllLabelId;
  final EdgeInsets? datePadding;
  final double? dateHeight;
  final bool? dateBackgroundIsTransparent;
  final double? dateWidth;
  final double? badgeWidth;
  final double? badgeHeight;
  final EdgeInsetsGeometry? badgePadding;
  final double? statusIndicatorWidth;
  final double? statusIndicatorHeight;
  final BorderRadiusGeometry? statusIndicatorBorderRadius;
  final EdgeInsetsGeometry? avatarMargin;
  final EdgeInsetsGeometry? avatarPadding;
  final double? avatarWidth;
  final double? avatarHeight;
  final bool deleteConversationOptionVisibility;
  final bool pinConversationOptionVisibility;
  final bool groupTypeVisibility;
  final List<CometChatOption>? Function(
    ChatConversation conversation,
    BuildContext context,
  )? setOptions;
  final List<CometChatOption>? Function(
    ChatConversation conversation,
    BuildContext context,
  )? addOptions;
  final WidgetBuilder? loadingStateView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      leadingView;
  final Widget? Function(BuildContext context, ChatConversation conversation)?
      titleView;
  final void Function(List<ChatConversation>)? onLoad;
  final VoidCallback? onEmpty;
  final OnError? onError;
  final String? customSoundForMessages;
  final bool disableSoundForMessages;
  final Widget? submitIcon;
  final DateTimeFormatterCallback? dateTimeFormatterCallback;
  final bool? hideSearch;
  final bool searchReadOnly;
  final VoidCallback? onSearchTap;
  final Widget? searchBoxIcon;
  final EdgeInsetsGeometry? searchPadding;
  final EdgeInsetsGeometry? searchContentPadding;
  final EdgeInsetsGeometry? listPadding;
  final int pageLimit;

  @override
  State<ConvoKitConversations> createState() => _ConvoKitConversationsState();
}

class _ConvoKitConversationsState extends State<ConvoKitConversations> {
  EventHub? _hub;
  ConvoKit? _kit;

  StreamSubscription<List<ChatConversation>>? _conversationsSub;
  StreamSubscription<Map<String, UserPresence>>? _presenceSub;
  StreamSubscription<Map<String, List<ChatUser>>>? _typingSub;

  List<ChatConversation> _conversations = const [];
  Map<String, UserPresence> _presenceByUserId = const {};
  Map<String, List<ChatUser>> _typingByConversation = const {};
  final Set<String> _selectedIds = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _nextCursor;
  ChatError? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kit = ConvoKitScope.of(context);
    final hub = ConvoKitScope.hubOf(context);
    if (_hub != hub || _kit != kit) {
      _detachStreams();
      _kit = kit;
      _hub = hub;
      _attachStreams(hub);
      unawaited(_loadInitial());
    }
  }

  void _attachStreams(EventHub hub) {
    _conversations = hub.conversationStore.conversations;
    _conversationsSub = hub.conversationStore.stream.listen((list) {
      if (!mounted) return;
      setState(() {
        _conversations = list;
      });
    });

    _presenceSub = hub.presenceRegistry.stream.listen((map) {
      if (!mounted) return;
      setState(() {
        _presenceByUserId = map;
      });
    });

    _typingSub = hub.typingRegistry.stream.listen((map) {
      if (!mounted) return;
      setState(() {
        _typingByConversation = map;
      });
    });
  }

  void _detachStreams() {
    unawaited(_conversationsSub?.cancel());
    _conversationsSub = null;
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;
    unawaited(_typingSub?.cancel());
    _typingSub = null;
  }

  Future<void> _loadInitial() async {
    final kit = _kit;
    final hub = _hub;
    if (kit == null || hub == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await kit.conversations.listConversations(
        limit: widget.pageLimit,
      );
      if (!mounted) return;
      result.fold(
        onSuccess: (page) {
          hub.conversationStore.setConversations(page.items);
          setState(() {
            _conversations = hub.conversationStore.conversations;
            _nextCursor = page.olderCursor;
            _hasMore = page.hasOlder;
            _isLoading = false;
            _error = null;
          });
          if (page.items.isEmpty) {
            widget.onEmpty?.call();
          } else {
            widget.onLoad?.call(page.items);
          }
        },
        onFailure: (err) {
          setState(() {
            _error = err;
            _isLoading = false;
          });
          widget.onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (!mounted) return;
      final err = ChatError(ChatErrorCode.unknown, e.toString());
      setState(() {
        _error = err;
        _isLoading = false;
      });
      widget.onError?.call(Exception(err.message));
    }
  }

  Future<void> _loadMore() async {
    final kit = _kit;
    final hub = _hub;
    if (kit == null || hub == null || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await kit.conversations.listConversations(
        cursor: _nextCursor,
        limit: widget.pageLimit,
      );
      if (!mounted) return;
      result.fold(
        onSuccess: (page) {
          for (final conv in page.items) {
            hub.conversationStore.updateConversation(conv);
          }
          setState(() {
            _conversations = hub.conversationStore.conversations;
            _nextCursor = page.olderCursor;
            _hasMore = page.hasOlder;
            _isLoadingMore = false;
          });
        },
        onFailure: (err) {
          setState(() {
            _isLoadingMore = false;
          });
          widget.onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      widget.onError?.call(Exception(e.toString()));
    }
  }

  void _toggleSelection(ChatConversation conversation) {
    setState(() {
      if (widget.selectionMode == SelectionMode.single) {
        if (_selectedIds.contains(conversation.id)) {
          _selectedIds.clear();
        } else {
          _selectedIds
            ..clear()
            ..add(conversation.id);
        }
      } else {
        if (!_selectedIds.add(conversation.id)) {
          _selectedIds.remove(conversation.id);
        }
      }
    });
  }

  void _submitSelection() {
    final selected = _conversations
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    widget.onSelection?.call(selected, context);
  }

  @override
  void dispose() {
    _detachStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = _kit ?? ConvoKitScope.of(context);
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);

    final showReceipts =
        kit.capabilities.receipts && (widget.receiptsVisibility ?? true);
    final showSearch =
        !(widget.hideSearch ?? true) && kit.capabilities.search;

    final listWidget = ConversationsList(
      conversations: _conversations,
      isLoading: _isLoading,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,
      error: _error,
      typingUsersByConversation: _typingByConversation,
      presenceByUserId: _presenceByUserId,
      loggedInUserId: kit.session.currentUser?.id,
      selectedIds: _selectedIds,
      onLoadMore: _loadMore,
      onRetry: _loadInitial,
      onSelectionToggle: _toggleSelection,
      style: widget.conversationsStyle,
      statusStyle: widget.conversationsStyle.statusIndicatorStyle ??
          const ConvoKitStatusIndicatorStyle(),
      typingStyle: widget.conversationsStyle.typingIndicatorStyle ??
          CometChatTypingIndicatorStyle(),
      receiptStyle: widget.conversationsStyle.receiptStyle ??
          CometChatMessageReceiptStyle(),
      datesStyle:
          widget.conversationsStyle.dateStyle ?? const ConvoKitDateStyle(),
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
      avatarHeight: widget.avatarHeight,
      avatarWidth: widget.avatarWidth,
      avatarPadding: widget.avatarPadding,
      avatarMargin: widget.avatarMargin,
      statusIndicatorHeight: widget.statusIndicatorHeight,
      statusIndicatorWidth: widget.statusIndicatorWidth,
      statusIndicatorBorderRadius: widget.statusIndicatorBorderRadius,
      privateGroupIcon: widget.privateGroupIcon,
      protectedGroupIcon: widget.protectedGroupIcon,
      usersStatusVisibility: widget.usersStatusVisibility,
      groupTypeVisibility: widget.groupTypeVisibility,
      selectionMode: widget.selectionMode,
      activateSelection: widget.activateSelection,
      onItemTap: widget.onItemTap,
      onItemLongPress: widget.onItemLongPress,
      receiptsVisibility: showReceipts,
      typingIndicatorText: widget.typingIndicatorText,
      readIcon: widget.readIcon,
      deliveredIcon: widget.deliveredIcon,
      sentIcon: widget.sentIcon,
      textFormatters: widget.textFormatters,
      datePattern: widget.datePattern,
      datePadding: widget.datePadding,
      dateHeight: widget.dateHeight,
      dateWidth: widget.dateWidth,
      dateBackgroundIsTransparent: widget.dateBackgroundIsTransparent,
      badgeWidth: widget.badgeWidth,
      badgeHeight: widget.badgeHeight,
      badgePadding: widget.badgePadding,
      dateTimeFormatterCallback: widget.dateTimeFormatterCallback,
      listItemStyle: widget.listItemStyle,
      listPadding: widget.listPadding,
    );

    final actions = <Widget>[
      if (widget.selectionMode != null &&
          widget.selectionMode != SelectionMode.none &&
          _selectedIds.isNotEmpty)
        IconButton(
          icon: widget.submitIcon ?? const Icon(Icons.check),
          onPressed: _submitSelection,
        ),
      ...?widget.appBarOptions?.call(context),
    ];

    return Scaffold(
      backgroundColor:
          widget.conversationsStyle.backgroundColor ?? colorPalette.background1,
      appBar: widget.hideAppbar
          ? null
          : AppBar(
              backgroundColor: widget.conversationsStyle.backgroundColor ??
                  colorPalette.background1,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: widget.showBackButton
                  ? (widget.backButton ??
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorPalette.iconPrimary,
                        ),
                        onPressed:
                            widget.onBack ?? () => Navigator.maybePop(context),
                      ))
                  : null,
              title: Text(
                widget.title ?? Translations.of(context).chats,
                style: TextStyle(
                  color: colorPalette.textPrimary,
                  fontSize: typography.heading1?.bold?.fontSize ?? 22,
                  fontWeight:
                      typography.heading1?.bold?.fontWeight ?? FontWeight.bold,
                  fontFamily: typography.heading1?.bold?.fontFamily,
                ).merge(widget.conversationsStyle.titleTextStyle),
              ),
              actions: actions,
            ),
      body: Column(
        children: [
          if (showSearch)
            Padding(
              padding: widget.searchPadding ??
                  EdgeInsets.symmetric(
                    horizontal: spacing.padding4 ?? 16,
                    vertical: spacing.padding2 ?? 8,
                  ),
              child: GestureDetector(
                onTap: widget.onSearchTap,
                child: AbsorbPointer(
                  absorbing: widget.searchReadOnly,
                  child: TextField(
                    readOnly: widget.searchReadOnly,
                    decoration: InputDecoration(
                      hintText: Translations.of(context).search,
                      prefixIcon:
                          widget.searchBoxIcon ?? const Icon(Icons.search),
                      contentPadding: widget.searchContentPadding,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(child: listWidget),
        ],
      ),
    );
  }
}
