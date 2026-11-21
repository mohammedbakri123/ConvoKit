import 'package:flutter/material.dart';
import '../../../../clean_architecture.dart';

/// Displays reaction pills below a message bubble.
///
/// Reactions backend actions are deferred to ConvoKit v1.1 (`UI-ONLY-PLAN.md` §9);
/// this widget renders any supplied reaction entries purely in Flutter without
/// `flutter_bloc` or SDK dependencies.
class CometChatReactions extends StatelessWidget {
  const CometChatReactions({
    super.key,
    required this.reactionList,
    this.alignment,
    this.onReactionTap,
    this.onReactionLongPress,
    this.style,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.colorPalette,
    this.spacing,
    this.typography,
  });

  /// Reaction entries (duck-typed for `reaction`, `count`, `reactedByMe` or Map).
  final List<dynamic> reactionList;
  final BubbleAlignment? alignment;
  final Function(String? reaction)? onReactionTap;
  final Function(String? reaction)? onReactionLongPress;
  final CometChatReactionsStyle? style;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final ConvoKitColorPalette? colorPalette;
  final ConvoKitSpacing? spacing;
  final ConvoKitTypography? typography;

  String _emojiOf(dynamic item) {
    if (item is Map) return (item['reaction'] ?? '').toString();
    try {
      // ignore: avoid_dynamic_calls
      return (item.reaction ?? '').toString();
    } catch (_) {
      return item.toString();
    }
  }

  int _countOf(dynamic item) {
    if (item is Map) return (item['count'] as int?) ?? 0;
    try {
      // ignore: avoid_dynamic_calls
      return (item.count as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool _reactedByMeOf(dynamic item) {
    if (item is Map) return (item['reactedByMe'] as bool?) ?? false;
    try {
      // ignore: avoid_dynamic_calls
      return (item.reactedByMe as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reactionList.isEmpty) return const SizedBox.shrink();
    final palette = colorPalette ?? ConvoKitThemeHelper.getColorPalette(context);
    final typo = typography ?? ConvoKitThemeHelper.getTypography(context);
    final space = spacing ?? ConvoKitThemeHelper.getSpacing(context);
    final effectiveStyle = ConvoKitThemeHelper.getTheme<CometChatReactionsStyle>(
      context: context,
      defaultTheme: CometChatReactionsStyle.of,
    ).merge(style);

    final hasOverflow = reactionList.length > 4;
    final visibleReactions = hasOverflow
        ? reactionList.take(3).toList()
        : reactionList;
    final overflowCount = reactionList.length - visibleReactions.length;

    final baseCountStyle = TextStyle(
      color: effectiveStyle.countTextColor ?? palette.textPrimary,
      fontSize: typo.caption1?.regular?.fontSize ?? 12,
    ).merge(effectiveStyle.countTextStyle);

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      child: Wrap(
        spacing: space.padding1 ?? 4,
        runSpacing: space.padding1 ?? 4,
        alignment: alignment == BubbleAlignment.right
            ? WrapAlignment.end
            : WrapAlignment.start,
        children: [
          ...visibleReactions.map((item) {
            final emoji = _emojiOf(item);
            final count = _countOf(item);
            final active = _reactedByMeOf(item);
            final bg = active
                ? (effectiveStyle.activeReactionBackgroundColor ??
                    palette.extendedPrimary50)
                : (effectiveStyle.backgroundColor ?? palette.background1);
            final border = active
                ? effectiveStyle.activeReactionBorder
                : effectiveStyle.border;
            final radius = effectiveStyle.borderRadius;

            return GestureDetector(
              onTap: () => onReactionTap?.call(emoji),
              onLongPress: () => onReactionLongPress?.call(emoji),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: space.padding2 ?? 6,
                  vertical: space.padding ?? 2,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  border: border ??
                      Border.all(
                        color: active
                            ? (palette.primary ?? Colors.blue)
                            : (palette.borderLight ?? Colors.grey.shade300),
                      ),
                  borderRadius:
                      radius ?? BorderRadius.circular(space.radiusMax ?? 1000),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: effectiveStyle.emojiTextStyle ??
                          TextStyle(
                            fontSize: typo.caption1?.regular?.fontSize ?? 12,
                          ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: space.padding ?? 2),
                      Text('$count', style: baseCountStyle),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (hasOverflow)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: space.padding2 ?? 6,
                vertical: space.padding ?? 2,
              ),
              decoration: BoxDecoration(
                color: effectiveStyle.backgroundColor ?? palette.background1,
                border: effectiveStyle.border ??
                    Border.all(
                      color: palette.borderLight ?? Colors.grey.shade300,
                    ),
                borderRadius:
                    effectiveStyle.borderRadius ??
                    BorderRadius.circular(space.radiusMax ?? 1000),
              ),
              child: Text('+$overflowCount', style: baseCountStyle),
            ),
        ],
      ),
    );
  }
}
