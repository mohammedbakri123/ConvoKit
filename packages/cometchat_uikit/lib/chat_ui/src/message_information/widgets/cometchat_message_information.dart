import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../convokit_uikit.dart';
import '../../../../convokit_uikit.dart' as cc;

/// [CometChatMessageInformation] displays delivery and send-state information
/// for a [ChatMessage] directly from [ChatMessage.sendState] and
/// [ChatMessage.deliveryState].
///
/// Receipt rows are gated on `ConvoKitScope.of(context).capabilities.receipts`:
/// when `false`, all receipt rows are hidden.
class CometChatMessageInformation extends StatefulWidget {
  const CometChatMessageInformation({
    super.key,
    required this.message,
    this.title,
    this.template,
    this.messageInformationStyle,
    this.textFormatters,
    this.colorPalette,
    this.typography,
    this.spacing,
  });

  /// Message whose information is displayed.
  final ChatMessage message;

  /// Optional sheet title; defaults to localized "Message Info".
  final String? title;

  /// Optional custom message template for rendering the preview bubble.
  final CometChatMessageTemplate? template;

  /// Style configuration.
  final CometChatMessageInformationStyle? messageInformationStyle;

  /// Optional text formatters for the preview bubble.
  final List<CometChatTextFormatter>? textFormatters;

  /// Optional pre-cached color palette.
  final ConvoKitColorPalette? colorPalette;

  /// Optional pre-cached typography.
  final ConvoKitTypography? typography;

  /// Optional pre-cached spacing.
  final ConvoKitSpacing? spacing;

  @override
  State<CometChatMessageInformation> createState() =>
      _CometChatMessageInformationState();
}

class _CometChatMessageInformationState
    extends State<CometChatMessageInformation> {
  // Theme caching
  late ConvoKitColorPalette _colorPalette;
  late ConvoKitTypography _typography;
  late ConvoKitSpacing _spacing;
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  late CometChatMessageInformationStyle _messageInfoStyle;

  // Optional live store observation for real-time delivery/send state updates
  EventHub? _hub;
  ConvoKit? _kit;
  StreamSubscription<List<ChatMessage>>? _storeSub;
  String? _subscribedConversationId;
  late ChatMessage _message;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
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
      _messageInfoStyle =
          ConvoKitThemeHelper.getTheme<CometChatMessageInformationStyle>(
            context: context,
            defaultTheme: CometChatMessageInformationStyle.of,
          ).merge(widget.messageInformationStyle);
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

    final convId = widget.message.conversationId;
    if (identical(_hub, hub) && _subscribedConversationId == convId) {
      _kit = kit;
      return;
    }

    _detachFromStore();
    _kit = kit;
    _hub = hub;
    _subscribedConversationId = convId;

    if (hub != null) {
      final store = hub.getMessageStore(convId);
      _syncFromMessages(store.messages, notify: false);
      _storeSub = store.stream.listen((messages) {
        if (!mounted) return;
        _syncFromMessages(messages, notify: true);
      });
    }
  }

  void _detachFromStore() {
    unawaited(_storeSub?.cancel());
    _storeSub = null;
    _subscribedConversationId = null;
  }

  bool _isSameMessage(ChatMessage a, ChatMessage b) {
    if (a.id != null && b.id != null && a.id == b.id) return true;
    return a.localId == b.localId;
  }

  void _syncFromMessages(List<ChatMessage> messages, {required bool notify}) {
    for (final msg in messages) {
      if (_isSameMessage(msg, widget.message)) {
        if (msg != _message) {
          if (notify && mounted) {
            setState(() => _message = msg);
          } else {
            _message = msg;
          }
        }
        return;
      }
    }
  }

  @override
  void didUpdateWidget(CometChatMessageInformation oldWidget) {
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
    if (widget.messageInformationStyle != oldWidget.messageInformationStyle) {
      _messageInfoStyle =
          ConvoKitThemeHelper.getTheme<CometChatMessageInformationStyle>(
            context: context,
            defaultTheme: CometChatMessageInformationStyle.of,
          ).merge(widget.messageInformationStyle);
    }
    if (widget.message != oldWidget.message) {
      _message = widget.message;
      if (widget.message.conversationId != oldWidget.message.conversationId) {
        _attachToStore();
      }
    }
  }

  @override
  void dispose() {
    _detachFromStore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsEnabled = _kit?.capabilities.receipts ?? true;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color:
                _messageInfoStyle.backgroundColor ?? _colorPalette.background1,
            borderRadius:
                _messageInfoStyle.borderRadius ??
                BorderRadius.vertical(
                  top: Radius.circular(_spacing.radius6 ?? 0),
                ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                border: _messageInfoStyle.border,
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    _messageInfoStyle
                                        .backgroundHighLightColor ??
                                    _colorPalette.background2,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  _spacing.padding4 ?? 0,
                                ),
                                child: MessageUtils.getMessageBubble(
                                  context: context,
                                  colorPalette: _colorPalette,
                                  spacing: _spacing,
                                  typography: _typography,
                                  bubbleAlignment: BubbleAlignment.right,
                                  message: _message,
                                  template: widget.template,
                                  textFormatters:
                                      widget.textFormatters ?? const [],
                                  receiptsVisibility: receiptsEnabled,
                                ),
                              ),
                            ),
                          ),
                          if (receiptsEnabled) _buildReceiptStatusSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: _spacing.padding3 ?? 0,
            bottom: _spacing.padding2 ?? 0,
          ),
          child: Container(
            height: 4,
            width: 32,
            decoration: BoxDecoration(
              color: _colorPalette.neutral500,
              borderRadius: BorderRadius.circular(_spacing.radiusMax ?? 0),
            ),
          ),
        ),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color:
                _messageInfoStyle.backgroundColor ?? _colorPalette.background1,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: _spacing.padding2 ?? 0,
                horizontal: _spacing.padding4 ?? 0,
              ),
              child: Text(
                widget.title ?? cc.Translations.of(context).messageInformation,
                style:
                    TextStyle(
                          color:
                              _messageInfoStyle.titleTextColor ??
                              _colorPalette.textPrimary,
                          fontSize: _typography.heading2?.bold?.fontSize,
                          fontWeight: _typography.heading2?.bold?.fontWeight,
                          fontFamily: _typography.heading2?.bold?.fontFamily,
                        )
                        .merge(_messageInfoStyle.titleTextStyle)
                        .copyWith(color: _messageInfoStyle.titleTextColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText(
    String text,
    TextStyle? mergeTextStyle,
    Color? textColor,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: textColor ?? _colorPalette.textSecondary,
        fontSize: _typography.body?.regular?.fontSize,
        fontWeight: _typography.body?.regular?.fontWeight,
        fontFamily: _typography.body?.regular?.fontFamily,
      ).merge(mergeTextStyle).copyWith(color: textColor),
    );
  }

  static String _formatTimestamp(DateTime? time) {
    if (time == null) return "----";
    return DateFormat("dd/M/yyyy, h:mm a").format(time);
  }

  /// Renders receipt and send-state rows directly from [ChatMessage.sendState]
  /// and [ChatMessage.deliveryState].
  Widget _buildReceiptStatusSection() {
    final timestamp = _message.serverCreatedAt ?? _message.createdAt;
    final isSent = _message.sendState == SendState.sent;
    final isRead = isSent && _message.deliveryState == DeliveryState.read;
    final isDelivered =
        isSent &&
        (_message.deliveryState == DeliveryState.delivered ||
            _message.deliveryState == DeliveryState.read);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_message.sendState == SendState.sending ||
            _message.sendState == SendState.failed)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _spacing.padding4 ?? 0,
              vertical: _spacing.padding3 ?? 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: _spacing.padding1 ?? 0),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: _spacing.padding1 ?? 0),
                        child: ConvoKitReceipt(
                          status: MessageReceiptUtils.getReceiptStatus(
                            _message,
                          ),
                          size: 16,
                          style: _messageInfoStyle.messageReceiptStyle,
                        ),
                      ),
                      _buildTimeText(
                        _message.sendState == SendState.failed
                            ? (_message.failure?.message ??
                                  cc.Translations.of(
                                    context,
                                  ).somethingWentWrongError)
                            : cc.Translations.of(context).sent,
                        _messageInfoStyle.deliveredTextStyle,
                        _message.sendState == SendState.failed
                            ? _colorPalette.error
                            : _messageInfoStyle.deliveredTextColor,
                      ),
                    ],
                  ),
                ),
                _buildTimeText(
                  "----",
                  _messageInfoStyle.deliveredDateTextStyle,
                  _messageInfoStyle.deliveredDateTextColor,
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _spacing.padding4 ?? 0,
            vertical: _spacing.padding3 ?? 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: _spacing.padding1 ?? 0),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: _spacing.padding1 ?? 0),
                      child: ConvoKitReceipt(
                        status: ReceiptStatus.read,
                        size: 16,
                        style: _messageInfoStyle.messageReceiptStyle,
                      ),
                    ),
                    _buildTimeText(
                      cc.Translations.of(context).read,
                      _messageInfoStyle.readTextStyle,
                      _messageInfoStyle.readTextColor,
                    ),
                  ],
                ),
              ),
              _buildTimeText(
                isRead ? _formatTimestamp(timestamp) : "----",
                _messageInfoStyle.readDateTextStyle,
                _messageInfoStyle.readDateTextColor,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _spacing.padding4 ?? 0,
            vertical: _spacing.padding3 ?? 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: _spacing.padding1 ?? 0),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: _spacing.padding1 ?? 0),
                      child: ConvoKitReceipt(
                        status: ReceiptStatus.delivered,
                        size: 16,
                        style: _messageInfoStyle.messageReceiptStyle,
                      ),
                    ),
                    _buildTimeText(
                      cc.Translations.of(context).delivered,
                      _messageInfoStyle.deliveredTextStyle,
                      _messageInfoStyle.deliveredTextColor,
                    ),
                  ],
                ),
              ),
              _buildTimeText(
                isDelivered ? _formatTimestamp(timestamp) : "----",
                _messageInfoStyle.deliveredDateTextStyle,
                _messageInfoStyle.deliveredDateTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows [CometChatMessageInformation] in a modal bottom sheet.
Future showMessageInformation({
  required BuildContext context,
  required final ChatMessage message,
  final String? title,
  final CometChatMessageTemplate? template,
  final CometChatMessageInformationStyle? messageInformationStyle,
  final List<CometChatTextFormatter>? textFormatters,
}) {
  final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor:
        messageInformationStyle?.backgroundColor ?? colorPalette.background1,
    builder: (BuildContext context) {
      return CometChatMessageInformation(
        message: message,
        title: title,
        template: template,
        messageInformationStyle: messageInformationStyle,
        textFormatters: textFormatters,
      );
    },
  );
}
