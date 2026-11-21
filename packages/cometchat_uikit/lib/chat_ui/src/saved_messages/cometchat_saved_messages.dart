import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';

/// Displays saved [ChatMessage]s inside [ConvoKitScope] without any
/// CometChat SDK dependency.
class ConvoKitSavedMessages extends StatefulWidget {
  const ConvoKitSavedMessages({
    super.key,
    this.initialMessages = const [],
    this.onItemTap,
    this.onUnsave,
    this.style,
    this.title,
    this.hideAppbar = false,
    this.showBackButton = true,
    this.backButton,
    this.onBack,
    this.emptyStateView,
    this.errorStateView,
    this.loadingStateView,
    this.templates,
    this.textFormatters,
    this.dateTimeFormatter,
  });

  final List<ChatMessage> initialMessages;
  final void Function(ChatMessage message)? onItemTap;
  final Future<void> Function(ChatMessage message)? onUnsave;
  final ConvoKitSavedMessagesStyle? style;
  final String? title;
  final bool hideAppbar;
  final bool showBackButton;
  final Widget? backButton;
  final VoidCallback? onBack;
  final WidgetBuilder? emptyStateView;
  final WidgetBuilder? errorStateView;
  final WidgetBuilder? loadingStateView;
  final List<CometChatMessageTemplate>? templates;
  final List<CometChatTextFormatter>? textFormatters;
  final DateTimeFormatterCallback? dateTimeFormatter;

  @override
  State<ConvoKitSavedMessages> createState() => _ConvoKitSavedMessagesState();
}

class _ConvoKitSavedMessagesState extends State<ConvoKitSavedMessages> {
  late List<ChatMessage> _messages;
  final bool _isLoading = false;
  ChatError? _error;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(widget.initialMessages);
  }

  @override
  void didUpdateWidget(covariant ConvoKitSavedMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMessages != widget.initialMessages) {
      _messages = List<ChatMessage>.from(widget.initialMessages);
    }
  }

  Future<void> _handleUnsave(ChatMessage message) async {
    if (widget.onUnsave != null) {
      await widget.onUnsave!(message);
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
    final style = widget.style ?? const ConvoKitSavedMessagesStyle();

    return Scaffold(
      backgroundColor: style.backgroundColor ?? colorPalette.background1,
      appBar: widget.hideAppbar
          ? null
          : AppBar(
              backgroundColor:
                  style.backgroundColor ?? colorPalette.background1,
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
                widget.title ?? Translations.of(context).savedMessagesTitle,
                style: TextStyle(
                  color: colorPalette.textPrimary,
                  fontSize: typography.heading2?.bold?.fontSize ?? 20,
                  fontWeight:
                      typography.heading2?.bold?.fontWeight ?? FontWeight.bold,
                ).merge(style.titleTextStyle),
              ),
            ),
      body: _buildBody(context, colorPalette, typography),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
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
                  Icons.bookmark_border,
                  size: 40,
                  color: colorPalette.iconSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  Translations.of(context).noSavedMessages,
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
        return ListTile(
          title: Text(
            message.sender.name,
            style: TextStyle(
              color: colorPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorPalette.textSecondary),
          ),
          trailing: IconButton(
            icon: Icon(Icons.bookmark, color: colorPalette.iconSecondary),
            onPressed: () => _handleUnsave(message),
          ),
          onTap: () => widget.onItemTap?.call(message),
        );
      },
    );
  }
}
