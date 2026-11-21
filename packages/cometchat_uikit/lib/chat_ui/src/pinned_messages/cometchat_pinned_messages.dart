import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';

/// Displays pinned [ChatMessage]s for a conversation (user or group) inside
/// [ConvoKitScope], preserving styling and tap/unpin callbacks without any
/// CometChat SDK dependency.
class ConvoKitPinnedMessages extends StatefulWidget {
  const ConvoKitPinnedMessages({
    super.key,
    this.user,
    this.group,
    this.conversationId,
    this.initialMessages = const [],
    this.onItemTap,
    this.onUnpin,
    this.style,
    this.title,
    this.hideHeader = false,
    this.closeIcon,
    this.emptyStateView,
    this.errorStateView,
    this.loadingStateView,
    this.templates,
    this.textFormatters,
    this.dateTimeFormatter,
  }) : assert(
         user != null || group != null || conversationId != null,
         'ConvoKitPinnedMessages requires user, group, or conversationId',
       );

  final ChatUser? user;
  final ChatGroup? group;
  final String? conversationId;
  final List<ChatMessage> initialMessages;
  final void Function(ChatMessage message)? onItemTap;
  final Future<void> Function(ChatMessage message)? onUnpin;
  final ConvoKitPinnedMessagesStyle? style;
  final String? title;
  final bool hideHeader;
  final Widget? closeIcon;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final WidgetBuilder? loadingStateView;
  final List<CometChatMessageTemplate>? templates;
  final List<CometChatTextFormatter>? textFormatters;
  final DateTimeFormatterCallback? dateTimeFormatter;

  static Future<void> showPinnedMessages(
    BuildContext context, {
    ChatUser? user,
    ChatGroup? group,
    String? conversationId,
    List<ChatMessage> initialMessages = const [],
    void Function(ChatMessage message)? onItemTap,
    Future<void> Function(ChatMessage message)? onUnpin,
    ConvoKitPinnedMessagesStyle? style,
    String? title,
    bool hideHeader = false,
    Widget? closeIcon,
    WidgetBuilder? emptyStateView,
    WidgetBuilder? errorStateView,
    WidgetBuilder? loadingStateView,
    List<CometChatMessageTemplate>? templates,
    List<CometChatTextFormatter>? textFormatters,
    DateTimeFormatterCallback? dateTimeFormatter,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.75,
        child: ConvoKitPinnedMessages(
          user: user,
          group: group,
          conversationId: conversationId,
          initialMessages: initialMessages,
          onItemTap: onItemTap,
          onUnpin: onUnpin,
          style: style,
          title: title,
          hideHeader: hideHeader,
          closeIcon: closeIcon,
          emptyStateView: emptyStateView,
          errorStateView: errorStateView,
          loadingStateView: loadingStateView,
          templates: templates,
          textFormatters: textFormatters,
          dateTimeFormatter: dateTimeFormatter,
        ),
      ),
    );
  }

  @override
  State<ConvoKitPinnedMessages> createState() => _ConvoKitPinnedMessagesState();
}

class _ConvoKitPinnedMessagesState extends State<ConvoKitPinnedMessages> {
  late List<ChatMessage> _messages;
  final bool _isLoading = false;
  ChatError? _error;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(widget.initialMessages);
  }

  @override
  void didUpdateWidget(covariant ConvoKitPinnedMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMessages != widget.initialMessages) {
      _messages = List<ChatMessage>.from(widget.initialMessages);
    }
  }

  Future<void> _handleUnpin(ChatMessage message) async {
    if (widget.onUnpin != null) {
      await widget.onUnpin!(message);
    }
    if (!mounted) return;
    setState(() {
      _messages.removeWhere(
        (m) =>
            (m.id != null && m.id == message.id) ||
            m.localId == message.localId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);
    final style = widget.style ?? const ConvoKitPinnedMessagesStyle();

    return Container(
      decoration: BoxDecoration(
        color: style.backgroundColor ?? colorPalette.background1,
        borderRadius:
            style.borderRadius ??
            const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          if (!widget.hideHeader)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.padding4 ?? 16,
                vertical: spacing.padding3 ?? 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? Translations.of(context).pinnedMessagesTitle,
                      style: TextStyle(
                        color: colorPalette.textPrimary,
                        fontSize: typography.heading3?.bold?.fontSize ?? 18,
                        fontWeight:
                            typography.heading3?.bold?.fontWeight ??
                            FontWeight.bold,
                      ).merge(style.titleTextStyle),
                    ),
                  ),
                  IconButton(
                    icon:
                        widget.closeIcon ??
                        Icon(
                          Icons.close,
                          color:
                              style.iconColor ?? colorPalette.iconPrimary,
                        ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody(context, colorPalette, typography, style)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitPinnedMessagesStyle style,
  ) {
    if (_isLoading) {
      return widget.loadingStateView?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return widget.errorStateView?.call(context) ??
          Center(child: Text(_error!.message));
    }
    if (_messages.isEmpty) {
      return widget.emptyStateView?.call(context) ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 40,
                  color: colorPalette.iconSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  Translations.of(context).noPinnedMessages,
                  style: TextStyle(
                    color: colorPalette.textSecondary,
                    fontSize: typography.body?.regular?.fontSize ?? 14,
                  ),
                ),
              ],
            ),
          );
    }

    return ListView.separated(
      itemCount: _messages.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: colorPalette.borderLight ?? Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final message = _messages[index];
        final preview = switch (message) {
          TextMessage t => t.text,
          MediaMessage m => m.caption ?? m.attachment.name ?? 'Media',
          CustomMessage c => c.kind,
        };
        return Material(
          type: MaterialType.transparency,
          child: ListTile(
            title: Text(
              message.sender.name,
              style: TextStyle(
                color: colorPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: preview,
                style: TextStyle(color: colorPalette.textSecondary),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.push_pin, color: colorPalette.iconSecondary),
              onPressed: () => _handleUnpin(message),
            ),
            onTap: () => widget.onItemTap?.call(message),
          ),
        );
      },
    );
  }
}
