import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';
import '../utils/conversation_subtitle_utils.dart';

/// A widget that displays the subtitle area for a conversation list item:
/// live typing indicator, optional delivery receipt icon (gated on
/// `capabilities.receipts`), and last message preview.
class ConversationsSubtitleView extends StatelessWidget {
  const ConversationsSubtitleView({
    super.key,
    required this.conversation,
    required this.style,
    required this.receiptStyle,
    required this.typingStyle,
    required this.colorPalette,
    required this.spacing,
    required this.typography,
    this.typingUsers = const [],
    this.loggedInUserId,
    this.hideThreadIndicator = true,
    this.receiptsVisibility = true,
    this.typingIndicatorText,
    this.readIcon,
    this.deliveredIcon,
    this.sentIcon,
    this.textFormatters,
  });

  final ChatConversation conversation;
  final List<ChatUser> typingUsers;
  final String? loggedInUserId;
  final ConvoKitConversationsStyle style;
  final CometChatMessageReceiptStyle receiptStyle;
  final CometChatTypingIndicatorStyle typingStyle;
  final ConvoKitColorPalette colorPalette;
  final ConvoKitSpacing spacing;
  final ConvoKitTypography typography;
  final bool? hideThreadIndicator;
  final bool? receiptsVisibility;
  final String? typingIndicatorText;
  final Widget? readIcon;
  final Widget? deliveredIcon;
  final Widget? sentIcon;
  final List<CometChatTextFormatter>? textFormatters;

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isNotEmpty) {
      return _buildTypingIndicator(context);
    }

    final lastMessage = conversation.lastMessage;
    final showReceipts = receiptsVisibility ?? true;
    final isOutgoing =
        lastMessage != null &&
        loggedInUserId != null &&
        lastMessage.sender.id == loggedInUserId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showReceipts && isOutgoing) ...[
          _buildReceipt(lastMessage),
          SizedBox(width: spacing.padding1 ?? 4),
        ],
        Expanded(
          child: ConversationSubtitleUtils.getConversationSubtitle(
            conversation,
            context,
            style.itemSubtitleTextStyle,
            colorPalette.iconSecondary,
            additionalConfigurations: AdditionalConfigurations(
              textFormatters: textFormatters,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final text = typingIndicatorText ??
        (conversation.type == ChatConversationType.group
            ? '${typingUsers.first.name} ${Translations.of(context).isTyping}'
            : Translations.of(context).typing);

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: typingStyle.textStyle?.color ?? colorPalette.primary,
        fontSize: typography.body?.regular?.fontSize,
        fontWeight: typography.body?.regular?.fontWeight,
        fontFamily: typography.body?.regular?.fontFamily,
      ).merge(typingStyle.textStyle),
    );
  }

  Widget _buildReceipt(ChatMessage message) {
    final status = MessageReceiptUtils.getReceiptStatus(message);
    return ConvoKitReceipt(
      status: status,
      readIcon: readIcon,
      deliveredIcon: deliveredIcon,
      sentIcon: sentIcon,
      style: receiptStyle,
    );
  }
}
