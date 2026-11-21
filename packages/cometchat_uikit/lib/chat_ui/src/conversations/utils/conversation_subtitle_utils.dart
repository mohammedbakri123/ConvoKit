import 'package:flutter/material.dart';
import '../../../../shared_ui/convokit_uikit_shared.dart';

/// Utility class for building conversation subtitle widgets.
class ConversationSubtitleUtils {
  static String getLastConversationMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    return ConversationUtils.getLastConversationMessage(conversation, context);
  }

  static Widget getLastConversationWidget(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    return ConversationUtils.getLastConversationIcon(
      conversation,
      context,
      iconColor,
    );
  }

  static Widget getConversationSubtitle(
    ChatConversation conversation,
    BuildContext context,
    TextStyle? subtitleStyle,
    Color? iconColor, {
    AdditionalConfigurations? additionalConfigurations,
  }) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final subtitleStyle0 = TextStyle(
      overflow: TextOverflow.ellipsis,
      color: colorPalette.textSecondary,
      fontSize: typography.body?.regular?.fontSize,
      fontWeight: typography.body?.regular?.fontWeight,
      fontFamily: typography.body?.regular?.fontFamily,
      letterSpacing: 0,
    ).merge(subtitleStyle);

    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) {
      return Text(
        Translations.of(context).tapToStartConversation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: subtitleStyle0,
      );
    }

    final spacing = ConvoKitThemeHelper.getSpacing(context);
    final iconWidget = ConversationUtils.getLastConversationIcon(
      conversation,
      context,
      iconColor ?? colorPalette.iconSecondary,
    );

    final messageText = ConversationUtils.getLastConversationMessage(
      conversation,
      context,
    );

    final isGroup = conversation.type == ChatConversationType.group;
    final prefix = isGroup && lastMessage.sender.name.isNotEmpty
        ? '${lastMessage.sender.name}: '
        : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: spacing.padding ?? 0),
            child: Text(
              '$prefix$messageText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle0,
            ),
          ),
        ),
      ],
    );
  }
}
