import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';

import '../../../../convokit_uikit.dart';
import '../../../../convokit_uikit.dart' as cc;

/// [ConvoKitThreadedHeader] displays a parent [ChatMessage] and its live reply
/// count in a threaded conversation view by observing
/// [EventHub.getMessageStore] directly via [ConvoKitScope].
class ConvoKitThreadedHeader extends StatefulWidget {
  const ConvoKitThreadedHeader({
    super.key,
    required this.parentMessage,
    this.loggedInUser,
    this.user,
    this.group,
    this.initialReplyCount = 0,
    this.messageActionView,
    this.style,
    this.template,
    this.height,
    this.width,
    this.receiptsVisibility = true,
    this.textFormatters,
    this.colorPalette,
    this.typography,
    this.spacing,
  });

  /// Parent message for the thread.
  final ChatMessage parentMessage;

  /// Optional logged-in user; defaults to `ConvoKitScope.of(context).session.currentUser`.
  final ChatUser? loggedInUser;

  /// Optional direct-chat peer user associated with the thread.
  final ChatUser? user;

  /// Optional group associated with the thread.
  final ChatGroup? group;

  /// Initial reply count displayed before/when [MessageStore] has no replies loaded.
  final int initialReplyCount;

  /// Custom action view replacing the default reply-count row.
  final Widget Function(ChatMessage message, BuildContext context)?
  messageActionView;

  /// Style configuration.
  final ConvoKitThreadedHeaderStyle? style;

  /// Optional custom message template for the parent bubble.
  final CometChatMessageTemplate? template;

  /// Optional maximum height override.
  final double? height;

  /// Optional width override.
  final double? width;

  /// Controls visibility of receipts (also gated on `capabilities.receipts`).
  final bool? receiptsVisibility;

  /// Optional text formatters for rendering the parent message bubble.
  final List<CometChatTextFormatter>? textFormatters;

  /// Optional pre-cached color palette.
  final ConvoKitColorPalette? colorPalette;

  /// Optional pre-cached typography.
  final ConvoKitTypography? typography;

  /// Optional pre-cached spacing.
  final ConvoKitSpacing? spacing;

  @override
  State<ConvoKitThreadedHeader> createState() => _ConvoKitThreadedHeaderState();
}

class _ConvoKitThreadedHeaderState extends State<ConvoKitThreadedHeader> {
  // Theme caching
  late ConvoKitColorPalette _colorPalette;
  late ConvoKitTypography _typography;
  late ConvoKitSpacing _spacing;
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  late ConvoKitThreadedHeaderStyle _threadedHeaderStyle;
  final _bubbleKey = GlobalKey();
  double _cachedScreenHeight = 0;

  // Store observation
  EventHub? _hub;
  ConvoKit? _kit;
  MessageStore? _store;
  StreamSubscription<List<ChatMessage>>? _storeSub;
  String? _subscribedConversationId;

  late ChatMessage _parentMessage;
  late int _replyCount;

  Widget? _cachedBubble;
  ChatMessage? _cachedBubbleMessage;

  @override
  void initState() {
    super.initState();
    _parentMessage = widget.parentMessage;
    _replyCount = widget.initialReplyCount;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      _colorPalette =
          widget.colorPalette ?? ConvoKitThemeHelper.getColorPalette(context);
      _typography =
          widget.typography ?? ConvoKitThemeHelper.getTypography(context);
      _spacing = widget.spacing ?? ConvoKitThemeHelper.getSpacing(context);
      _threadedHeaderStyle =
          ConvoKitThemeHelper.getTheme<ConvoKitThreadedHeaderStyle>(
            context: context,
            defaultTheme: ConvoKitThreadedHeaderStyle.of,
          ).merge(widget.style);
      _cachedScreenHeight = MediaQuery.sizeOf(context).height;
      _themeInitialized = true;
    }

    _attachToStore();
  }

  void _attachToStore() {
    ConvoKit? kit;
    EventHub? hub;
    try {
      kit = ConvoKitScope.of(context);
      hub = ConvoKitScope.hubOf(context);
    } on StateError {
      kit = null;
      hub = null;
    }

    final convId = widget.parentMessage.conversationId;
    if (identical(_hub, hub) && _subscribedConversationId == convId) {
      _kit = kit;
      return;
    }

    _detachFromStore();
    _kit = kit;
    _hub = hub;
    _subscribedConversationId = convId;

    if (hub != null) {
      _store = hub.getMessageStore(convId);
      _syncFromMessages(_store!.messages, notify: false);
      _storeSub = _store!.stream.listen((messages) {
        if (!mounted) return;
        _syncFromMessages(messages, notify: true);
      });
    }
  }

  void _detachFromStore() {
    unawaited(_storeSub?.cancel());
    _storeSub = null;
    _store = null;
    _subscribedConversationId = null;
  }

  bool _isSameMessage(ChatMessage a, ChatMessage b) {
    if (a.id != null && b.id != null && a.id == b.id) return true;
    return a.localId == b.localId;
  }

  void _syncFromMessages(List<ChatMessage> messages, {required bool notify}) {
    ChatMessage updatedParent = _parentMessage;
    var count = 0;

    for (final msg in messages) {
      if (_isSameMessage(msg, widget.parentMessage)) {
        updatedParent = msg;
      }
      final replied = msg.repliedTo;
      if (replied != null && _isSameMessage(replied, widget.parentMessage)) {
        count++;
      }
    }

    final resolvedCount = count > 0 ? count : widget.initialReplyCount;
    if (updatedParent != _parentMessage || resolvedCount != _replyCount) {
      if (notify && mounted) {
        setState(() {
          _parentMessage = updatedParent;
          _replyCount = resolvedCount;
        });
      } else {
        _parentMessage = updatedParent;
        _replyCount = resolvedCount;
      }
    }
  }

  @override
  void didUpdateWidget(ConvoKitThreadedHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.colorPalette != oldWidget.colorPalette &&
        widget.colorPalette != null) {
      _colorPalette = widget.colorPalette!;
    }
    if (widget.typography != oldWidget.typography &&
        widget.typography != null) {
      _typography = widget.typography!;
    }
    if (widget.spacing != oldWidget.spacing && widget.spacing != null) {
      _spacing = widget.spacing!;
    }
    if (widget.style != oldWidget.style) {
      _threadedHeaderStyle =
          ConvoKitThemeHelper.getTheme<ConvoKitThreadedHeaderStyle>(
            context: context,
            defaultTheme: ConvoKitThreadedHeaderStyle.of,
          ).merge(widget.style);
    }

    final parentChanged = !_isSameMessage(
      widget.parentMessage,
      oldWidget.parentMessage,
    );
    if (parentChanged ||
        widget.parentMessage != oldWidget.parentMessage ||
        widget.initialReplyCount != oldWidget.initialReplyCount) {
      _parentMessage = widget.parentMessage;
      _replyCount = widget.initialReplyCount;
      _cachedBubble = null;
      _cachedBubbleMessage = null;
      if (widget.parentMessage.conversationId !=
          oldWidget.parentMessage.conversationId) {
        _attachToStore();
      } else if (_store != null) {
        _syncFromMessages(_store!.messages, notify: false);
      }
    }
  }

  @override
  void dispose() {
    _detachFromStore();
    super.dispose();
  }

  Widget _buildActionView(int replyCount, BuildContext context) {
    if (widget.messageActionView != null) {
      return widget.messageActionView!(_parentMessage, context);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            _threadedHeaderStyle.countContainerBackGroundColor ??
            _colorPalette.extendedPrimary100,
        border:
            _threadedHeaderStyle.countContainerBorder ??
            Border(
              bottom: BorderSide(
                width: 1.0,
                color: _colorPalette.borderDefault ?? Colors.transparent,
                style: BorderStyle.solid,
              ),
            ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: _spacing.padding1 ?? 0,
        horizontal: _spacing.padding4 ?? 0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$replyCount ${replyCount > 1 ? cc.Translations.of(context).replies : cc.Translations.of(context).reply}",
              style:
                  TextStyle(
                        color:
                            _threadedHeaderStyle.countTextColor ??
                            _colorPalette.textSecondary,
                        fontSize: _typography.body?.regular?.fontSize,
                        fontFamily: _typography.body?.regular?.fontFamily,
                        fontWeight: _typography.body?.regular?.fontWeight,
                      )
                      .merge(_threadedHeaderStyle.countTextStyle)
                      .copyWith(color: _threadedHeaderStyle.countTextColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        widget.loggedInUser?.id ?? _kit?.session.currentUser?.id;
    final isOutgoing =
        currentUserId != null && _parentMessage.sender.id == currentUserId;
    final effectiveReceiptsVisibility =
        (widget.receiptsVisibility ?? true) &&
        (_kit?.capabilities.receipts ?? true);

    if (_cachedBubble == null || _cachedBubbleMessage != _parentMessage) {
      _cachedBubbleMessage = _parentMessage;
      _cachedBubble = MessageUtils.getMessageBubble(
        context: context,
        colorPalette: _colorPalette,
        spacing: _spacing,
        typography: _typography,
        bubbleAlignment: isOutgoing
            ? BubbleAlignment.right
            : BubbleAlignment.left,
        message: _parentMessage,
        template: widget.template,
        outgoingMessageBubbleStyle:
            _threadedHeaderStyle.outgoingMessageBubbleStyle,
        incomingMessageBubbleStyle:
            _threadedHeaderStyle.incomingMessageBubbleStyle,
        textFormatters: widget.textFormatters ?? const [],
        key: _bubbleKey,
        receiptsVisibility: effectiveReceiptsVisibility,
      );
    }

    final maxHeight = widget.height ?? _cachedScreenHeight * 0.30;
    final minHeight = (_cachedScreenHeight * 0.10)
        .clamp(0.0, maxHeight)
        .toDouble();

    return Container(
      width: widget.width ?? double.infinity,
      constraints:
          _threadedHeaderStyle.constraints ??
          BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      child: IntrinsicHeight(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _threadedHeaderStyle.bubbleContainerBackGroundColor ??
                      _colorPalette.background3,
                  borderRadius:
                      _threadedHeaderStyle.bubbleContainerBorderRadius,
                  border: _threadedHeaderStyle.bubbleContainerBorder,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(top: _spacing.padding4 ?? 0),
                    child: IgnorePointer(child: _cachedBubble),
                  ),
                ),
              ),
            ),
            _buildActionView(_replyCount, context),
          ],
        ),
      ),
    );
  }
}
