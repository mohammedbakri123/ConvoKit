import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

///[ConvoKitDeletedBubble] is a widget that provides a placeholder for messages thave been deleted
///
///a [BaseMessage] is considered deleted if the value of its `deletedAt` property is not null
/// ```dart
/// CometChatDeleteMessageBubble(
///      style: ConvoKitDeletedBubbleStyle(
///           backgroundColor: Colors.white,
///           border: Border.all(color: Colors.red),
///           borderRadius: BorderRadius.circular(10),
///           iconColor: Colors.red,
///           textColor: Colors.red,
///      ),
/// )
/// ```
class ConvoKitDeletedBubble extends StatelessWidget {
  // Deprecated in 6.2.0: no effect, removed in 7.0.0.

  /// Height of the widget.
  @Deprecated(
    'Has no effect. Size it through its parent. Will be removed in 7.0.0.',
  )
  final double? height;

  /// Width of the widget.
  @Deprecated(
    'Has no effect. Size it through its parent. Will be removed in 7.0.0.',
  )
  final double? width;

  const ConvoKitDeletedBubble({
    super.key,
    this.style,
    this.padding,
    this.margin,
    this.height,
    this.width,
  });

  ///[padding] defines the padding of the widget
  final EdgeInsetsGeometry? padding;

  ///[margin] defines the margin of the widget
  final EdgeInsetsGeometry? margin;

  ///[style] contains properties that affects the appearance of this widget
  final ConvoKitDeletedBubbleStyle? style;

  @override
  Widget build(BuildContext context) {
    ConvoKitDeletedBubbleStyle deletedBubbleStyle;
    if (style == null) {
      deletedBubbleStyle =
          ConvoKitThemeHelper.getTheme<ConvoKitDeletedBubbleStyle>(
            context: context,
            defaultTheme: ConvoKitDeletedBubbleStyle.of,
          ).merge(style);
    } else {
      deletedBubbleStyle = style!;
    }
    ConvoKitSpacing spacing = ConvoKitThemeHelper.getSpacing(context);
    ConvoKitTypography typography = ConvoKitThemeHelper.getTypography(
      context,
    );
    return Container(
      margin: margin,
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            spacing.padding2 ?? 0,
            spacing.padding2 ?? 0,
            spacing.padding2 ?? 0,
            0,
          ),
      decoration: BoxDecoration(
        color: deletedBubbleStyle.backgroundColor,
        border: deletedBubbleStyle.border,
        borderRadius: deletedBubbleStyle.borderRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(right: spacing.padding1 ?? 0),
            child: Icon(
              Icons.block,
              color: deletedBubbleStyle.iconColor,
              size: 16,
            ),
          ),
          Flexible(
            child: Text(
              Translations.of(context).thisMessageDeleted,
              style:
                  TextStyle(
                        color: deletedBubbleStyle.textColor,
                        fontSize: typography.body?.regular?.fontSize,
                        fontWeight: typography.body?.regular?.fontWeight,
                        fontFamily: typography.body?.regular?.fontFamily,
                      )
                      .merge(deletedBubbleStyle.textStyle)
                      .copyWith(color: deletedBubbleStyle.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
