import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:convokit/convokit_uikit.dart';
import 'cometchat_flag_message_dialog.dart';

/// Callback for thread replies click.
typedef ThreadRepliesClick =
    void Function(
      ChatMessage message,
      BuildContext context, {
      CometChatMessageTemplate? template,
    });

/// Builder function for message items with animation support.
typedef MessageItemBuilder =
    Widget Function(
      BuildContext context,
      ChatMessage message,
      int index,
      Animation<double> animation,
    );

/// Builder function for header and footer views.
typedef HeaderFooterBuilder =
    Widget? Function(
      BuildContext context, {
      ChatUser? user,
      ChatGroup? group,
      String? parentMessageId,
    });

/// Builder function for state views (empty, error, loading).
typedef StateViewBuilder = Widget Function(BuildContext context);

/// Imperative handle for an already-mounted [ConvoKitMessageList].
class ConvoKitMessageListController {
  _ConvoKitMessageListState? _state;

  bool get isAttached => _state != null;

  void _attach(_ConvoKitMessageListState state) => _state = state;

  void _detach(_ConvoKitMessageListState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Scrolls to [messageId] (server ID or localId) if currently loaded.
  Future<bool> jumpToMessage(String messageId) async {
    final state = _state;
    if (state == null) return false;
    return state.jumpToMessage(messageId);
  }

  /// Triggers a manual refresh via [MessageCoordinator.refresh].
  Future<void> refresh() async {
    await _state?._handleRefresh();
  }
}

/// [ConvoKitMessageList] observes [EventHub.getMessageStore] (`stream` +
/// `gapStream`) and delegates pagination (`fetchOlder`, `refresh`), retry
/// (`retryFailed`), deletion, and read/delivery reporting to
/// [MessageCoordinator] via [ConvoKitScope].
class ConvoKitMessageList extends StatefulWidget {
  final bool? disableMentions;
  final String? mentionAllLabel;
  final String? mentionAllLabelId;
  final String? emptyStateText;

  const ConvoKitMessageList({
    super.key,
    this.conversationId,
    this.user,
    this.group,
    this.controller,
    this.templates,
    this.addTemplate,
    this.parentMessageId,
    this.withParent = true,
    this.hideDeletedMessages = false,
    this.disableSoundForMessages = false,
    this.disableReceipts = false,
    this.hideReplies = true,
    this.headerView,
    this.footerView,
    this.loadingStateView,
    this.emptyStateView,
    this.errorStateView,
    this.emptyChatGreetingView,
    this.style,
    this.scrollController,
    this.alignment = ChatAlignment.standard,
    this.onError,
    this.onLoad,
    this.onEmpty,
    this.customSoundForMessages,
    this.customSoundForMessagePackage,
    this.readIcon,
    this.deliveredIcon,
    this.sentIcon,
    this.waitIcon,
    this.avatarVisibility = true,
    this.enableMultipleAttachments = true,
    this.hideTimestamp = false,
    this.datePattern,
    this.onThreadRepliesClick,
    this.onMessageTap,
    this.onMessageLongPress,
    this.messageBuilder,
    this.textFormatters,
    this.dateTimeFormatter,
    this.hideReplyOption = false,
    this.hideCopyMessageOption = false,
    this.hideDeleteMessageOption = false,
    this.hideMessageInfoOption = false,
    this.hideFlagMessageOption = true,
    this.onReplyMessage,
    this.onDeleteMessage,
    this.onFlagMessage,
    this.pageLimit = 30,
    this.disableMentions,
    this.mentionAllLabel,
    this.mentionAllLabelId,
    this.emptyStateText,
  });

  final String? conversationId;
  final ChatUser? user;
  final ChatGroup? group;
  final ConvoKitMessageListController? controller;
  final List<CometChatMessageTemplate>? templates;
  final List<CometChatMessageTemplate>? addTemplate;
  final String? parentMessageId;
  final bool withParent;
  final bool hideDeletedMessages;
  final bool disableSoundForMessages;
  final bool disableReceipts;
  final bool hideReplies;
  final HeaderFooterBuilder? headerView;
  final HeaderFooterBuilder? footerView;
  final StateViewBuilder? loadingStateView;
  final StateViewBuilder? emptyStateView;
  final StateViewBuilder? errorStateView;
  final StateViewBuilder? emptyChatGreetingView;
  final ConvoKitMessageListStyle? style;
  final ScrollController? scrollController;
  final ChatAlignment alignment;
  final OnError? onError;
  final void Function(List<ChatMessage>)? onLoad;
  final VoidCallback? onEmpty;
  final String? customSoundForMessages;
  final String? customSoundForMessagePackage;
  final Widget? readIcon;
  final Widget? deliveredIcon;
  final Widget? sentIcon;
  final Widget? waitIcon;
  final bool avatarVisibility;
  final bool enableMultipleAttachments;
  final bool hideTimestamp;
  final String Function(ChatMessage)? datePattern;
  final ThreadRepliesClick? onThreadRepliesClick;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final Widget Function(BuildContext context, ChatMessage message)?
      messageBuilder;
  final List<CometChatTextFormatter>? textFormatters;
  final DateTimeFormatterCallback? dateTimeFormatter;
  final bool hideReplyOption;
  final bool hideCopyMessageOption;
  final bool hideDeleteMessageOption;
  final bool hideMessageInfoOption;
  final bool hideFlagMessageOption;
  final void Function(ChatMessage message)? onReplyMessage;
  final Future<void> Function(ChatMessage message)? onDeleteMessage;
  final void Function(ChatMessage message, String reason, String remark)?
      onFlagMessage;
  final int pageLimit;

  String get resolvedConversationId =>
      conversationId ?? group?.id ?? user?.id ?? '';

  @override
  State<ConvoKitMessageList> createState() => _ConvoKitMessageListState();
}

class _ConvoKitMessageListState extends State<ConvoKitMessageList> {
  EventHub? _hub;
  ConvoKit? _kit;
  MessageStore? _store;
  MessageCoordinator? _coordinator;
  String _activeConversationId = '';

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<bool>? _gapSub;

  late final ScrollController _scrollController;
  bool _ownsScrollController = false;

  List<ChatMessage> _messages = const [];
  bool _hasPossibleGap = false;
  bool _isLoading = true;
  bool _isLoadingOlder = false;
  ChatError? _error;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wireIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ConvoKitMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.resolvedConversationId != widget.resolvedConversationId) {
      _wireIfNeeded(forceRewire: true);
    }
  }

  void _wireIfNeeded({bool forceRewire = false}) {
    final kit = ConvoKitScope.of(context);
    final hub = ConvoKitScope.hubOf(context);
    final convId = widget.resolvedConversationId;

    if (!forceRewire &&
        _hub == hub &&
        _kit == kit &&
        _activeConversationId == convId) {
      return;
    }

    _cleanupWiring();

    _kit = kit;
    _hub = hub;
    _coordinator = hub.coordinator;
    _activeConversationId = convId;

    if (convId.isEmpty) {
      setState(() {
        _messages = const [];
        _isLoading = false;
      });
      return;
    }

    _store = hub.getMessageStore(convId);
    hub.registerVisibleConversation(convId);

    _messagesSub = _store!.stream.listen((msgs) {
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _reportReceiptsIfEnabled(msgs);
    });

    _gapSub = _store!.gapStream.listen((gap) {
      if (!mounted) return;
      setState(() {
        _hasPossibleGap = gap;
      });
    });

    _messages = _store!.messages;
    _hasPossibleGap = _store!.hasPossibleGap;

    if (_messages.isEmpty) {
      _isLoading = true;
      unawaited(_fetchInitial());
    } else {
      _isLoading = false;
      _reportReceiptsIfEnabled(_messages);
    }
  }

  void _cleanupWiring() {
    unawaited(_messagesSub?.cancel());
    _messagesSub = null;
    unawaited(_gapSub?.cancel());
    _gapSub = null;
    if (_hub != null && _activeConversationId.isNotEmpty) {
      _hub!.unregisterVisibleConversation(_activeConversationId);
    }
  }

  Future<void> _fetchInitial() async {
    final coordinator = _coordinator;
    final convId = _activeConversationId;
    if (coordinator == null || convId.isEmpty) return;

    final result = await coordinator.fetchLatest(
      convId,
      limit: widget.pageLimit,
    );
    if (!mounted || convId != _activeConversationId) return;

    result.fold(
      onSuccess: (page) {
        setState(() {
          _messages = _store?.messages ?? page.items;
          _isLoading = false;
          _error = null;
        });
        if (_messages.isEmpty) {
          widget.onEmpty?.call();
        } else {
          widget.onLoad?.call(_messages);
          _reportReceiptsIfEnabled(_messages);
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
  }

  Future<void> _loadOlder() async {
    final coordinator = _coordinator;
    final store = _store;
    final convId = _activeConversationId;
    if (coordinator == null ||
        store == null ||
        convId.isEmpty ||
        _isLoadingOlder ||
        !store.hasOlder) {
      return;
    }

    setState(() => _isLoadingOlder = true);
    final result = await coordinator.fetchOlder(
      convId,
      limit: widget.pageLimit,
    );
    if (!mounted || convId != _activeConversationId) return;

    setState(() {
      _isLoadingOlder = false;
      _messages = store.messages;
    });
    if (result.isFailure) {
      widget.onError?.call(Exception((result as ChatFailure<ChatPage<ChatMessage>>).error.message));
    }
  }

  Future<void> _handleRefresh() async {
    final coordinator = _coordinator;
    final convId = _activeConversationId;
    if (coordinator == null || convId.isEmpty) return;
    await coordinator.refresh(convId);
  }

  Future<void> _handleDelete(ChatMessage message) async {
    if (widget.onDeleteMessage != null) {
      await widget.onDeleteMessage!(message);
      return;
    }
    final kit = _kit;
    final store = _store;
    final id = message.id ?? message.localId;
    if (kit == null || id.isEmpty) return;

    final result = await kit.messages.deleteMessage(id);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) => store?.removeMessage(id),
      onFailure: (err) => widget.onError?.call(Exception(err.message)),
    );
  }

  void _reportReceiptsIfEnabled(List<ChatMessage> messages) {
    final kit = _kit;
    if (kit == null ||
        widget.disableReceipts ||
        !kit.capabilities.receipts ||
        _activeConversationId.isEmpty ||
        messages.isEmpty) {
      return;
    }
    final myId = kit.session.currentUser?.id;
    final lastIncoming = messages.lastWhere(
      (m) => m.id != null && m.sender.id != myId,
      orElse: () => messages.last,
    );
    if (lastIncoming.id != null && lastIncoming.sender.id != myId) {
      unawaited(
        kit.messages.markAsRead(lastIncoming.id!),
      );
    }
  }

  Future<bool> jumpToMessage(String messageId) async {
    final idx = _messages.indexWhere(
      (m) => m.id == messageId || m.localId == messageId,
    );
    if (idx == -1 || !_scrollController.hasClients) return false;
    final targetOffset = (idx * 72.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    return true;
  }

  void _showOptionsForMessage(ChatMessage message) {
    if (widget.onMessageLongPress != null) {
      widget.onMessageLongPress!(message);
      return;
    }
    final kit = _kit;
    final options = MessageTemplateUtils.getDefaultMessageOptions(
      context,
      message,
      loggedInUserId: kit?.session.currentUser?.id,
      hideCopyMessageOption: widget.hideCopyMessageOption,
      hideDeleteMessageOption: widget.hideDeleteMessageOption,
      hideReplyOption: widget.hideReplyOption,
      hideMessageInfoOption: widget.hideMessageInfoOption,
    );
    if (options.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opt in options)
              ListTile(
                leading: opt.icon,
                title: Text(opt.title),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handleOptionTap(opt.id, message);
                },
              ),
            if (!widget.hideFlagMessageOption)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(Translations.of(context).reportProblem),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showDialog<void>(
                    context: context,
                    builder: (_) => CometChatFlagMessageDialog(
                      message: message,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleOptionTap(String? optionId, ChatMessage message) {
    switch (optionId) {
      case MessageOptionConstants.copyMessage:
        if (message is TextMessage) {
          Clipboard.setData(ClipboardData(text: message.text));
        }
      case MessageOptionConstants.replyMessage:
        widget.onReplyMessage?.call(message);
      case MessageOptionConstants.deleteMessage:
        unawaited(_handleDelete(message));
      case MessageOptionConstants.messageInformation:
        showMessageInformation(
          context: context,
          message: message,
        );
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _cleanupWiring();
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = _kit ?? ConvoKitScope.of(context);
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);
    final showReceipts = kit.capabilities.receipts && !widget.disableReceipts;

    final header = widget.headerView?.call(
      context,
      user: widget.user,
      group: widget.group,
      parentMessageId: widget.parentMessageId,
    );
    final footer = widget.footerView?.call(
      context,
      user: widget.user,
      group: widget.group,
      parentMessageId: widget.parentMessageId,
    );

    return Container(
      color: widget.style?.backgroundColor ?? colorPalette.background1,
      child: Column(
        children: [
          ?header,
          if (_hasPossibleGap) _buildGapBanner(context),
          Expanded(
            child: _buildListBody(
              context,
              kit,
              colorPalette,
              spacing,
              showReceipts,
            ),
          ),
          ?footer,
        ],
      ),
    );
  }

  Widget _buildGapBanner(BuildContext context) {
    return Container(
      key: const Key('gap_banner'),
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Some messages may be missing',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
          TextButton(
            key: const Key('gap_banner_refresh'),
            onPressed: _handleRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    ConvoKit kit,
    ConvoKitColorPalette colorPalette,
    ConvoKitSpacing spacing,
    bool showReceipts,
  ) {
    if (_isLoading && _messages.isEmpty) {
      return widget.loadingStateView?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return widget.errorStateView?.call(context) ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!.message),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchInitial,
                  child: Text(Translations.of(context).tryAgain),
                ),
              ],
            ),
          );
    }

    if (_messages.isEmpty) {
      return widget.emptyStateView?.call(context) ??
          widget.emptyChatGreetingView?.call(context) ??
          Center(
            child: Text(
              widget.emptyStateText ?? Translations.of(context).noMessagesFound,
              style: TextStyle(color: colorPalette.textSecondary),
            ),
          );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if ((_store?.hasOlder ?? false) &&
            !_isLoadingOlder &&
            notification.metrics.pixels <= 100) {
          unawaited(_loadOlder());
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.padding3 ?? 12,
          vertical: spacing.padding2 ?? 8,
        ),
        itemCount: _messages.length + (_isLoadingOlder ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingOlder && index == 0) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final msgIndex = _isLoadingOlder ? index - 1 : index;
          final message = _messages[msgIndex];
          return _buildMessageRow(
            context,
            message,
            kit,
            colorPalette,
            showReceipts,
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context,
    ChatMessage message,
    ConvoKit kit,
    ConvoKitColorPalette colorPalette,
    bool showReceipts,
  ) {
    if (widget.messageBuilder != null) {
      return widget.messageBuilder!(context, message);
    }

    final myId = kit.session.currentUser?.id;
    final isMe = myId != null && message.sender.id == myId;
    final bubbleAlignment =
        widget.alignment == ChatAlignment.leftAligned
            ? BubbleAlignment.left
            : (isMe ? BubbleAlignment.right : BubbleAlignment.left);

    final outgoingStyle = widget.style?.outgoingMessageBubbleStyle;
    final incomingStyle = widget.style?.incomingMessageBubbleStyle;
    final bubbleTextStyle = bubbleAlignment == BubbleAlignment.right
        ? outgoingStyle?.textBubbleStyle?.textStyle
        : incomingStyle?.textBubbleStyle?.textStyle;
    final bubbleDateStyle = bubbleAlignment == BubbleAlignment.right
        ? outgoingStyle?.messageBubbleDateStyle?.textStyle
        : incomingStyle?.messageBubbleDateStyle?.textStyle;
    final bubbleBackgroundColor = bubbleAlignment == BubbleAlignment.right
        ? (outgoingStyle?.backgroundColor ?? colorPalette.primary ?? Colors.blue)
        : (incomingStyle?.backgroundColor ??
              colorPalette.background3 ??
              Colors.grey.shade200);
    final bubbleBorderRadius =
        (bubbleAlignment == BubbleAlignment.right
            ? outgoingStyle?.borderRadius
            : incomingStyle?.borderRadius) ??
        BorderRadius.circular(12);

    final content = MessageTemplateUtils.buildDefaultBubbleContent(
      context,
      message,
      alignment: bubbleAlignment,
      textStyle: bubbleTextStyle,
      loggedInUserId: myId,
    );

    Widget? statusWidget;
    if (isMe) {
      if (message.sendState == SendState.sending) {
        statusWidget =
            widget.waitIcon ??
            const SizedBox(
              key: Key('indicator_sending'),
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
      } else if (message.sendState == SendState.failed) {
        statusWidget = Row(
          key: const Key('indicator_failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            IconButton(
              key: Key('retry_${message.localId}'),
              icon: const Icon(Icons.refresh, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _coordinator?.retryFailed(
                  message.localId,
                  conversationId: _activeConversationId,
                );
              },
            ),
          ],
        );
      } else if (message.sendState == SendState.sent && showReceipts) {
        final receiptStatus = MessageReceiptUtils.getReceiptStatus(message);
        statusWidget = ConvoKitReceipt(
          status: receiptStatus,
          readIcon: widget.readIcon,
          deliveredIcon: widget.deliveredIcon,
          sentIcon: widget.sentIcon,
        );
      }
    }

    return Padding(
      key: ValueKey(message.id ?? message.localId),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: bubbleAlignment == BubbleAlignment.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (bubbleAlignment == BubbleAlignment.left &&
              widget.avatarVisibility) ...[
            ConvoKitAvatar(
              image: message.sender.avatarUrl,
              name: message.sender.name,
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: InkWell(
              onTap: () => widget.onMessageTap?.call(message),
              onLongPress: () => _showOptionsForMessage(message),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bubbleBackgroundColor,
                  borderRadius: bubbleBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    if (statusWidget != null || !widget.hideTimestamp) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.hideTimestamp)
                            Text(
                              widget.datePattern?.call(message) ??
                                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                              style:
                                  bubbleDateStyle ??
                                  TextStyle(
                                    fontSize: 11,
                                    color:
                                        bubbleAlignment == BubbleAlignment.right
                                        ? Colors.white70
                                        : colorPalette.textSecondary,
                                  ),
                            ),
                          if (statusWidget != null) ...[
                            const SizedBox(width: 4),
                            statusWidget,
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
