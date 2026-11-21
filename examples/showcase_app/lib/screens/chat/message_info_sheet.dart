import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';

/// Modal bottom-sheet wrapper mounting the library's
/// [CometChatMessageInformation] widget styled with [ShowcaseTheme] and
/// concentric 28px sheet radii.
class MessageInfoSheet extends StatelessWidget {
  const MessageInfoSheet({
    super.key,
    required this.message,
    this.title,
  });

  final ChatMessage message;
  final String? title;

  /// Presents [MessageInfoSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageInfoSheet(
        message: message,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    const sheetRadius = BorderRadius.vertical(
      top: Radius.circular(ShowcaseTokens.radiusSheet),
    );

    return ClipRRect(
      borderRadius: sheetRadius,
      child: CometChatMessageInformation(
        message: message,
        title: title,
        messageInformationStyle: CometChatMessageInformationStyle(
          backgroundColor: colorScheme.surfaceContainerLow,
          backgroundHighLightColor: palette.background3,
          borderRadius: sheetRadius,
          titleTextColor: palette.textPrimary,
          titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          nameTextColor: palette.textPrimary,
          nameTextStyle: ShowcaseTypography.rowTitle.copyWith(
            color: palette.textPrimary,
          ),
          readTextColor: palette.textPrimary,
          readDateTextColor: palette.textSecondary,
          deliveredTextColor: palette.textPrimary,
          deliveredDateTextColor: palette.textSecondary,
          messageReceiptStyle: CometChatMessageReceiptStyle(
            sentIconColor: palette.iconSecondary,
            deliveredIconColor: palette.iconSecondary,
            readIconColor: ShowcaseColors.readReceiptBlue,
          ),
        ),
      ),
    );
  }
}
