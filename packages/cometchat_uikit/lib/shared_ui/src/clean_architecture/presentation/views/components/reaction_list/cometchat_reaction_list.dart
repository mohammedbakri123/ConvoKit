import 'package:flutter/material.dart';
import '../../../../clean_architecture.dart';
import '../../../../../../convokit_uikit_shared.dart'
    show ListItemStyle, ConvoKitAvatarStyle;

/// Reaction list sheet widget.
///
/// Reactions are deferred to ConvoKit v1.1 (`UI-ONLY-PLAN.md` §9); this widget
/// preserves the public widget surface without `flutter_bloc` or SDK calls.
class CometChatReactionList extends StatefulWidget {
  const CometChatReactionList({
    super.key,
    this.reactionRequestBuilder,
    this.errorStateView,
    this.errorStateText,
    this.loadingStateView,
    this.emptyStateView,
    this.emptyStateText,
    this.loadingIcon,
    this.onTap,
    this.style,
    this.selectedReaction,
    this.listItemStyle,
    this.avatarStyle,
    this.message,
    this.height,
    this.width,
    this.padding,
    this.onReactionListItemClick,
  });

  final Object? reactionRequestBuilder;
  final WidgetBuilder? errorStateView;
  final String? errorStateText;
  final WidgetBuilder? loadingStateView;
  final String? emptyStateText;
  final WidgetBuilder? emptyStateView;
  final Widget? loadingIcon;
  final Function(dynamic, ChatMessage)? onTap;
  final CometChatReactionListStyle? style;
  final String? selectedReaction;
  final ListItemStyle? listItemStyle;
  final ConvoKitAvatarStyle? avatarStyle;
  final ChatMessage? message;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Function(String? reaction, ChatMessage? message)?
      onReactionListItemClick;

  @override
  State<CometChatReactionList> createState() => _CometChatReactionListState();
}

class _CometChatReactionListState extends State<CometChatReactionList> {
  @override
  Widget build(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final effectiveStyle = ConvoKitThemeHelper.getTheme<CometChatReactionListStyle>(
      context: context,
      defaultTheme: CometChatReactionListStyle.of,
    ).merge(widget.style);

    return Container(
      height: widget.height,
      width: widget.width,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: effectiveStyle.backgroundColor ?? colorPalette.background1,
        border: effectiveStyle.border,
        borderRadius: effectiveStyle.borderRadius,
      ),
      child: widget.emptyStateView != null
          ? widget.emptyStateView!(context)
          : Center(
              child: Text(
                widget.emptyStateText ?? Translations.of(context).noReactionsFound,
                style: effectiveStyle.errorTextStyle ??
                    TextStyle(
                      color: colorPalette.textSecondary,
                      fontSize: typography.body?.regular?.fontSize,
                    ),
              ),
            ),
    );
  }
}
