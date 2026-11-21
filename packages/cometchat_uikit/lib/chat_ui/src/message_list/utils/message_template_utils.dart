import 'package:flutter/material.dart';
import '../../../../shared_ui/convokit_uikit_shared.dart';
import '../../extensions/extension_constants.dart';
import '../../extensions/polls/cometchat_polls_bubble.dart';
import '../../extensions/stickers/cometchat_sticker_bubble.dart';
import '../widgets/cometchat_card_bubble.dart';

/// [MessageTemplateUtils] provides default [CometChatMessageTemplate]s and
/// default message options built on ConvoKit Core [ChatMessage] models.
class MessageTemplateUtils {
  static CometChatMessageOption getEditOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
  ) {
    return CometChatMessageOption(
      id: MessageOptionConstants.editMessage,
      title: Translations.of(context).edit,
      icon: Icon(
        Icons.edit_outlined,
        color: messageOptionSheetStyle?.iconColor ?? colorPalette.iconSecondary,
        size: 24,
      ),
      messageOptionSheetStyle: _optionStyle(
        colorPalette,
        typography,
        messageOptionSheetStyle,
      ),
    );
  }

  static CometChatMessageOption getDeleteOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
  ) {
    return CometChatMessageOption(
      id: MessageOptionConstants.deleteMessage,
      title: Translations.of(context).delete,
      icon: Image.asset(
        AssetConstants.delete,
        package: UIConstants.packageName,
        height: 24,
        width: 24,
        color: messageOptionSheetStyle?.iconColor ?? colorPalette.error,
      ),
      messageOptionSheetStyle: _optionStyle(
        colorPalette,
        typography,
        messageOptionSheetStyle,
        defaultTitleColor: colorPalette.error,
      ),
    );
  }

  static CometChatMessageOption getReplyOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
  ) {
    return CometChatMessageOption(
      id: MessageOptionConstants.replyMessage,
      title: Translations.of(context).reply,
      icon: Icon(
        Icons.reply_outlined,
        color: messageOptionSheetStyle?.iconColor ?? colorPalette.iconSecondary,
        size: 24,
      ),
      messageOptionSheetStyle: _optionStyle(
        colorPalette,
        typography,
        messageOptionSheetStyle,
      ),
    );
  }

  static CometChatMessageOption getCopyOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
  ) {
    return CometChatMessageOption(
      id: MessageOptionConstants.copyMessage,
      title: Translations.of(context).copyText,
      icon: Icon(
        Icons.copy_outlined,
        color: messageOptionSheetStyle?.iconColor ?? colorPalette.iconSecondary,
        size: 24,
      ),
      messageOptionSheetStyle: _optionStyle(
        colorPalette,
        typography,
        messageOptionSheetStyle,
      ),
    );
  }

  static CometChatMessageOption getMessageInfoOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
  ) {
    return CometChatMessageOption(
      id: MessageOptionConstants.messageInformation,
      title: Translations.of(context).info,
      icon: Icon(
        Icons.info_outline,
        color: messageOptionSheetStyle?.iconColor ?? colorPalette.iconSecondary,
        size: 24,
      ),
      messageOptionSheetStyle: _optionStyle(
        colorPalette,
        typography,
        messageOptionSheetStyle,
      ),
    );
  }

  static ConvoKitMessageOptionSheetStyle _optionStyle(
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitMessageOptionSheetStyle? base, {
    Color? defaultTitleColor,
  }) {
    return ConvoKitMessageOptionSheetStyle(
      titleTextStyle: TextStyle(
        color: base?.titleColor ?? defaultTitleColor,
        fontFamily: typography.body?.regular?.fontFamily,
        fontWeight: typography.body?.regular?.fontWeight,
        fontSize: typography.body?.regular?.fontSize,
      ).merge(base?.titleTextStyle),
      borderRadius: base?.borderRadius,
      border: base?.border,
      backgroundColor: base?.backgroundColor,
      iconColor: base?.iconColor,
      titleColor: base?.titleColor ?? defaultTitleColor,
    );
  }

  /// Returns default options for a [ChatMessage].
  static List<CometChatMessageOption> getDefaultMessageOptions(
    BuildContext context,
    ChatMessage message, {
    String? loggedInUserId,
    ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle,
    bool hideCopyMessageOption = false,
    bool hideDeleteMessageOption = false,
    bool hideReplyOption = false,
    bool hideMessageInfoOption = false,
  }) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final isOwn = loggedInUserId != null && message.sender.id == loggedInUserId;
    final options = <CometChatMessageOption>[];

    if (!hideReplyOption) {
      options.add(
        getReplyOption(context, colorPalette, typography, messageOptionSheetStyle),
      );
    }
    if (!hideCopyMessageOption && message is TextMessage) {
      options.add(
        getCopyOption(context, colorPalette, typography, messageOptionSheetStyle),
      );
    }
    if (!hideMessageInfoOption && isOwn) {
      options.add(
        getMessageInfoOption(
          context,
          colorPalette,
          typography,
          messageOptionSheetStyle,
        ),
      );
    }
    if (!hideDeleteMessageOption && isOwn) {
      options.add(
        getDeleteOption(
          context,
          colorPalette,
          typography,
          messageOptionSheetStyle,
        ),
      );
    }
    return options;
  }

  /// Builds default bubble content for a [ChatMessage].
  static Widget buildDefaultBubbleContent(
    BuildContext context,
    ChatMessage message, {
    BubbleAlignment alignment = BubbleAlignment.left,
    String? loggedInUserId,
    TextStyle? textStyle,
  }) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    return switch (message) {
      TextMessage t => Text(
        t.text,
        style:
            textStyle ??
            TextStyle(
              color: alignment == BubbleAlignment.right
                  ? colorPalette.white
                  : colorPalette.textPrimary,
            ),
      ),
      MediaMessage m => _buildMediaContent(context, m, textStyle),
      CustomMessage c => _buildCustomContent(
        context,
        c,
        loggedInUserId: loggedInUserId,
      ),
    };
  }

  static Widget _buildMediaContent(
    BuildContext context,
    MediaMessage message,
    TextStyle? textStyle,
  ) {
    final attachment = message.attachment;
    if (attachment.kind == AttachmentKind.image && attachment.url != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              attachment.url!,
              width: 220,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
            ),
          ),
          if (message.caption != null && message.caption!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(message.caption!, style: textStyle),
          ],
        ],
      );
    }

    final icon = switch (attachment.kind) {
      AttachmentKind.image => Icons.image_outlined,
      AttachmentKind.video => Icons.videocam_outlined,
      AttachmentKind.audio => Icons.audiotrack_outlined,
      AttachmentKind.file => Icons.insert_drive_file_outlined,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.caption ?? attachment.name ?? attachment.kind.name,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  static Widget _buildCustomContent(
    BuildContext context,
    CustomMessage message, {
    String? loggedInUserId,
  }) {
    if (message.kind == ExtensionType.sticker) {
      return CometChatStickerBubble(message: message);
    }
    if (message.kind == ExtensionConstants.polls ||
        message.kind == ExtensionType.extensionPoll) {
      return CometChatPollsBubble(
        loggedInUser: loggedInUserId,
        pollQuestion: message.data['question'] as String?,
        pollId: message.id ?? message.localId,
        metadata: message.data,
        choosePoll: (_, _) async {},
      );
    }
    if (message.kind == 'card') {
      return CometChatCardBubble(message: message);
    }
    return Text(
      (message.data['text'] as String?) ?? message.kind,
    );
  }

  /// Returns default [CometChatMessageTemplate]s for text, media, and custom messages.
  static List<CometChatMessageTemplate> getDefaultMessageTemplates({
    String? loggedInUserId,
  }) {
    return [
      CometChatMessageTemplate(
        type: MessageTypeConstants.text,
        category: MessageCategoryConstants.message,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
      CometChatMessageTemplate(
        type: MessageTypeConstants.image,
        category: MessageCategoryConstants.message,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
      CometChatMessageTemplate(
        type: MessageTypeConstants.video,
        category: MessageCategoryConstants.message,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
      CometChatMessageTemplate(
        type: MessageTypeConstants.audio,
        category: MessageCategoryConstants.message,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
      CometChatMessageTemplate(
        type: MessageTypeConstants.file,
        category: MessageCategoryConstants.message,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
      CometChatMessageTemplate(
        type: MessageTypeConstants.custom,
        category: MessageCategoryConstants.custom,
        contentView: (message, context, alignment, {additionalConfigurations}) => buildDefaultBubbleContent(
          context,
          message,
          alignment: alignment,
          loggedInUserId: loggedInUserId,
        ),
      ),
    ];
  }

  /// Alias for [getDefaultMessageTemplates] (zero call/meeting templates).
  static List<CometChatMessageTemplate> getAllMessageTemplates({
    String? loggedInUserId,
  }) => getDefaultMessageTemplates(loggedInUserId: loggedInUserId);

  /// Looks up a default message template by [messageType] and [messageCategory].
  /// Returns `null` for unsupported categories/types such as calls or meetings.
  static CometChatMessageTemplate? getMessageTemplate({
    required String messageType,
    required String messageCategory,
    String? loggedInUserId,
  }) {
    for (final t in getDefaultMessageTemplates(loggedInUserId: loggedInUserId)) {
      if (t.type == messageType && t.category == messageCategory) {
        return t;
      }
    }
    return null;
  }

  /// Returns the default text message template.
  static CometChatMessageTemplate getTextMessageTemplate({
    String? loggedInUserId,
  }) => getDefaultMessageTemplates(loggedInUserId: loggedInUserId).first;

  /// Returns a default poll custom message template.
  static CometChatMessageTemplate getPollMessageTemplate({
    String? loggedInUserId,
  }) {
    return CometChatMessageTemplate(
      type: ExtensionType.extensionPoll,
      category: MessageCategoryConstants.custom,
      contentView: (message, context, alignment, {additionalConfigurations}) =>
          buildDefaultBubbleContent(
            context,
            message,
            alignment: alignment,
            loggedInUserId: loggedInUserId,
          ),
    );
  }

  /// Returns default options for text messages.
  static List<CometChatMessageOption> getTextMessageOptions({
    bool hideCopyMessageOption = false,
    bool hideDeleteMessageOption = false,
    bool hideReplyOption = false,
    bool hideMessageInfoOption = false,
  }) {
    return [
      if (!hideReplyOption)
        CometChatMessageOption(
          id: MessageOptionConstants.replyMessage,
          title: 'Reply',
        ),
      if (!hideCopyMessageOption)
        CometChatMessageOption(
          id: MessageOptionConstants.copyMessage,
          title: 'Copy',
        ),
      if (!hideMessageInfoOption)
        CometChatMessageOption(
          id: MessageOptionConstants.messageInformation,
          title: 'Info',
        ),
      if (!hideDeleteMessageOption)
        CometChatMessageOption(
          id: MessageOptionConstants.deleteMessage,
          title: 'Delete',
        ),
    ];
  }

  /// Renders a placeholder bubble for a deleted message.
  static Widget getDeleteMessageBubble(
    ChatMessage message,
    BuildContext context,
    BubbleAlignment alignment,
  ) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isOutgoing = alignment == BubbleAlignment.right;
    final foreground = isOutgoing ? palette.white : palette.textSecondary;
    return ConvoKitDeletedBubble(
      style: ConvoKitDeletedBubbleStyle(
        textColor: foreground,
        iconColor: foreground,
        textStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: foreground,
        ),
      ),
    );
  }
}
