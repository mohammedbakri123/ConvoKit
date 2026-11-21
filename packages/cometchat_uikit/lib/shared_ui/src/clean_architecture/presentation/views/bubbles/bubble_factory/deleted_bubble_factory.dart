import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../../../core/constants/enums.dart';
import '../../../theme/colors/cometchat_color_palette.dart';
import '../../../theme/typography/cometchat_typography.dart';
import '../../../theme/spacing/cometchat_spacing.dart';
import '../../../theme/theme/cometchat_theme_helper.dart';
import '../../../../../../l10n/translations.dart';
import 'bubble_factory.dart';

/// Factory for creating deleted message bubbles.
class DeletedBubbleFactory extends BubbleFactory<ChatMessage> {
  final TextStyle? textStyle;
  final Color? iconColor;

  DeletedBubbleFactory({this.textStyle, this.iconColor});

  @override
  Widget build(
    BuildContext context,
    ChatMessage message,
    BubbleAlignment alignment, {
    ConvoKitColorPalette? colorPalette,
    ConvoKitTypography? typography,
    ConvoKitSpacing? spacing,
  }) {
    final palette =
        colorPalette ?? ConvoKitThemeHelper.getColorPalette(context);
    final typo = typography ?? ConvoKitThemeHelper.getTypography(context);
    final space = spacing ?? ConvoKitThemeHelper.getSpacing(context);

    final isOutgoing = alignment == BubbleAlignment.right;
    final textColor = isOutgoing ? palette.white : palette.neutral600;

    return Padding(
      padding: EdgeInsets.all(space.padding2 ?? 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: iconColor ?? textColor),
          SizedBox(width: space.padding1 ?? 4),
          Flexible(
            child: Text(
              Translations.of(context).thisMessageDeleted,
              style:
                  textStyle ??
                  TextStyle(
                    color: textColor,
                    fontSize: typo.body?.regular?.fontSize,
                    fontWeight: typo.body?.regular?.fontWeight,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
