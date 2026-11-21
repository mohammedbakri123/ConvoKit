import 'package:convokit/src/core/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/additional_configurations.dart';

// Import all necessary dependencies
import '../../presentation/theme/theme/cometchat_theme_helper.dart';
import '../../presentation/theme/colors/cometchat_color_palette.dart';
import '../../presentation/theme/typography/cometchat_typography.dart';
import '../../presentation/theme/spacing/cometchat_spacing.dart';
import '../../presentation/formatters/cometchat_text_formatter.dart';
import '../../../../convokit_uikit_shared.dart'
    show
        ConvoKitDateStyle,
        CometChatMessageReceiptStyle,
        ConvoKitAvatarStyle,
        ConvoKitActionBubbleStyle,
        ConvoKitMessageBubble,
        ConvoKitMessageBubbleStyle,
        CometChatTextBubble,
        CometChatImagesBubble,
        CometChatVideosBubble,
        CometChatAudiosBubble,
        CometChatFilesBubble,
        ConvoKitDate,
        ConvoKitReceipt,
        MessageReceiptUtils,
        ReceiptStatus,
        ConvoKitUIKit,
        MessageCategoryConstants,
        MessageTypeConstants,
        CallTypeConstants,
        ExtensionType,
        DateTimePattern,
        ErrorConstants;
import 'moderation_check_util.dart';
import '../../data/models/extension_bubble_styles/cometchat_outgoing_message_bubble_style.dart';
import '../../data/models/extension_bubble_styles/cometchat_incoming_message_bubble_style.dart';
import '../../data/models/cometchat_message_template.dart';
import '../constants/enums.dart';

/// A utility class for message related operations.
/// This class contains methods required for message related operations.
/// It is used to get the message bubble, message time, and message receipt icon.
/// ``` dart
/// MessageUtils.getMessageBubble(
///  message: message,
///  template: messageTemplate,
///  bubbleAlignment: BubbleAlignment.left,
///  colorPalette: colorPalette,
///  typography: typography,
///  spacing: spacing,
///  context: context,
///  );
///  ```
class MessageUtils {
  static Widget getMessageBubble({
    required ChatMessage message,
    CometChatMessageTemplate? template,
    required BubbleAlignment bubbleAlignment,
    required ConvoKitColorPalette colorPalette,
    required ConvoKitTypography typography,
    required ConvoKitSpacing spacing,
    required BuildContext context,
    List<CometChatTextFormatter>? textFormatters,
    CometChatOutgoingMessageBubbleStyle? outgoingMessageBubbleStyle,
    CometChatIncomingMessageBubbleStyle? incomingMessageBubbleStyle,
    Key? key,
    bool? receiptsVisibility,
    // List surfaces (pinned messages) render every bubble flush-left so the
    // column reads as one list. Layout (row alignment, avatar, sender name)
    // follows LEFT while content/status styling still follows
    // [bubbleAlignment], so an outgoing bubble keeps its own colour scheme
    // and readable text. Default off — no change for the chat list.
    bool forceLeftLayout = false,
    // Replaces the sender name in the header (e.g. "You" for the logged-in
    // user's own messages in a pinned list). Null keeps sender.name.
    String? senderNameOverride,
    // Appends "• dd/MM/yy" after the sender name. List surfaces span many
    // days with no date separators, so each row states its own date.
    bool showSentDateInHeader = false,
    // Prefixes the bubble's status line with a pin glyph — the pinned list
    // marks every row as pinned. Default off for the chat list.
    bool showPinIndicator = false,
    // Adds a bookmark glyph beside it when the message is also saved.
    bool showSaveIndicator = false,
  }) {
    final isDeleted = message is CustomMessage && message.kind == 'deleted';
    if (!isDeleted && template?.bubbleView != null) {
      return template?.bubbleView!(message, context, BubbleAlignment.left) ??
          const SizedBox();
    }
    Widget? contentView;
    Widget? statusInfoView;
    Widget? leadingView;
    Widget? headerView;

    final outgoingMessageBubbleStyle0 =
        ConvoKitThemeHelper.getTheme<CometChatOutgoingMessageBubbleStyle>(
          context: context,
          defaultTheme: CometChatOutgoingMessageBubbleStyle.of,
        ).merge(outgoingMessageBubbleStyle);
    final incomingMessageBubbleStyle0 =
        ConvoKitThemeHelper.getTheme<CometChatIncomingMessageBubbleStyle>(
          context: context,
          defaultTheme: CometChatIncomingMessageBubbleStyle.of,
        ).merge(incomingMessageBubbleStyle);

    final bubbleStyleData = BubbleUIBuilder.getBubbleStyle(
      message,
      outgoingMessageBubbleStyle0,
      incomingMessageBubbleStyle0,
      colorPalette,
      typography,
      spacing,
    );
    final additionalConfigurations =
        BubbleUIBuilder.getAdditionalConfigurations(
          context,
          message,
          textFormatters,
          incomingMessageBubbleStyle0,
          outgoingMessageBubbleStyle0,
          null,
        );

    final layoutAlignment = forceLeftLayout
        ? BubbleAlignment.left
        : bubbleAlignment;

    contentView = _getSuitableContentView(
      message,
      colorPalette,
      context,
      template,
      bubbleAlignment,
      additionalConfigurations,
    );

    statusInfoView = _getStatusInfoView(
      bubbleAlignment,
      message,
      context,
      colorPalette,
      typography,
      spacing,
      template,
      bubbleStyleData?.messageBubbleDateStyle,
      bubbleStyleData?.messageReceiptStyle,
      receiptsVisibility,
      showPinIndicator: showPinIndicator,
      showSaveIndicator: showSaveIndicator,
    );

    leadingView = _getAvatar(
      layoutAlignment,
      message,
      context,
      colorPalette,
      typography,
      spacing,
      template,
      bubbleStyleData?.messageBubbleAvatarStyle,
    );

    headerView = _getHeaderView(
      layoutAlignment,
      message,
      context,
      colorPalette,
      typography,
      spacing,
      template,
      bubbleStyleData,
      senderNameOverride: senderNameOverride,
      alwaysShowName: forceLeftLayout,
      showSentDate: showSentDateInHeader,
    );

    Color backgroundColor =
        bubbleStyleData?.backgroundColor ??
        _getBubbleBackgroundColor(
          message,
          template,
          colorPalette,
          bubbleAlignment,
        );

    return Column(
      key: key,
      children: [
        Row(
          mainAxisAlignment: layoutAlignment == BubbleAlignment.left
              ? MainAxisAlignment.start
              : layoutAlignment == BubbleAlignment.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.end,
          children: [
            // Flexible, not a bare child: a Row lays out non-flex children
            // with unbounded width, so a long message would size to its
            // intrinsic width and overflow the row (and ignore any maxWidth
            // the caller set). Loose fit keeps short bubbles hugging their
            // content while long ones wrap at the available width.
            Flexible(
              child: ConvoKitMessageBubble(
                style: ConvoKitMessageBubbleStyle(
                  backgroundColor: backgroundColor,
                  border: bubbleStyleData?.border,
                  borderRadius: bubbleStyleData?.borderRadius,
                  backgroundImage:
                      bubbleStyleData?.messageBubbleBackgroundImage,
                ),
                headerView: headerView,
                alignment: layoutAlignment,
                contentView: contentView,
                footerView: const SizedBox(),
                leadingView: leadingView,
                statusInfoView: statusInfoView,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _getBubbleBackgroundColor(
    ChatMessage messageObject,
    CometChatMessageTemplate? template,
    ConvoKitColorPalette colorPalette,
    BubbleAlignment alignment,
  ) {
    final isSent =
        ConvoKitUIKit.loggedInUser != null &&
        messageObject.sender.id == ConvoKitUIKit.loggedInUser!.id;
    return isSent
        ? colorPalette.primary ?? Colors.transparent
        : colorPalette.neutral300 ?? Colors.transparent;
  }

  static Widget? _getSuitableContentView(
    ChatMessage messageObject,
    ConvoKitColorPalette colorPalette,
    BuildContext context,
    CometChatMessageTemplate? template,
    BubbleAlignment alignment,
    AdditionalConfigurations? additionalConfigurations,
  ) {
    if (template?.contentView != null) {
      return template?.contentView!(
        messageObject,
        context,
        alignment,
        additionalConfigurations: additionalConfigurations,
      );
    }
    return switch (messageObject) {
      TextMessage t => CometChatTextBubble(
        text: t.text,
        alignment: alignment,
        formatters: additionalConfigurations?.textFormatters,
      ),
      MediaMessage m => switch (m.attachment.kind) {
        AttachmentKind.image => CometChatImagesBubble(
          message: m,
          alignment: alignment,
          formatters: additionalConfigurations?.textFormatters,
        ),
        AttachmentKind.video => CometChatVideosBubble(
          message: m,
          alignment: alignment,
          formatters: additionalConfigurations?.textFormatters,
        ),
        AttachmentKind.audio => CometChatAudiosBubble(
          message: m,
          alignment: alignment,
          formatters: additionalConfigurations?.textFormatters,
        ),
        AttachmentKind.file => CometChatFilesBubble(
          message: m,
          alignment: alignment,
          formatters: additionalConfigurations?.textFormatters,
        ),
      },
      CustomMessage c => CometChatTextBubble(
        text: (c.data['text'] as String?) ?? c.kind,
        alignment: alignment,
        formatters: additionalConfigurations?.textFormatters,
      ),
    };
  }

  /// Separator between a state glyph and whatever follows it in the caption
  /// row. Its surrounding spaces are the spacing — no extra padding.
  static Widget _statusBullet(Color? color, ConvoKitTypography typography) {
    return Text(
      ' • ',
      style: TextStyle(
        color: color,
        fontSize: typography.caption2?.regular?.fontSize,
        fontWeight: typography.caption2?.regular?.fontWeight,
        fontFamily: typography.caption2?.regular?.fontFamily,
      ),
    );
  }

  static Widget? _getStatusInfoView(
    BubbleAlignment alignment,
    ChatMessage message,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
    CometChatMessageTemplate? template,
    ConvoKitDateStyle? dateStyle,
    CometChatMessageReceiptStyle? receiptStyle,
    bool? receiptsVisibility, {
    bool showPinIndicator = false,
    bool showSaveIndicator = false,
  }) {
    if (template?.statusInfoView != null) {
      return template?.statusInfoView!(message, context, alignment);
    } else {
      final statusForeground = alignment == BubbleAlignment.right
          ? colorPalette.white
          : colorPalette.neutral600;
      return Padding(
        padding: EdgeInsets.only(top: spacing.padding1 ?? 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // State glyphs sit ahead of the time, each closed by its own
            // bullet: pinned when the row is a pin, saved when the reader
            // saved it too, so "pin • save • time" reads as three items.
            if (showPinIndicator) ...[
              Icon(Icons.push_pin, size: 12, color: statusForeground),
              _statusBullet(statusForeground, typography),
            ],
            _getTime(
              message,
              colorPalette,
              typography,
              alignment,
              dateStyle,
              // With a glyph ahead of it, the date's default side padding
              // widens the status row past the message text — the bubble
              // then sizes to the row and the line stops reading as
              // right-aligned. Drop it so the row hugs.
              compact: showPinIndicator || showSaveIndicator,
            ),
            if (alignment == BubbleAlignment.right &&
                (receiptsVisibility ?? true))
              _getReceiptIcon(message, colorPalette, spacing, receiptStyle),
          ],
        ),
      );
    }
  }

  static Widget? _getAvatar(
    BubbleAlignment alignment,
    ChatMessage message,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
    CometChatMessageTemplate? template,
    ConvoKitAvatarStyle? avatarStyle,
  ) {
    return const SizedBox();
  }

  static Widget? _getHeaderView(
    BubbleAlignment alignment,
    ChatMessage message,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
    CometChatMessageTemplate? template,
    ConvoKitMessageBubbleStyleData? messageBubbleStyleData, {
    String? senderNameOverride,
    // Pinned/saved list surfaces show a name on EVERY row (including 1-1
    // and own messages) so each row is attributable at a glance.
    bool alwaysShowName = false,
    // Renders the sent date beside the name, bullet-separated.
    bool showSentDate = false,
  }) {
    if (alwaysShowName) {
      if (template?.headerView != null) {
        return template?.headerView!(message, context, alignment);
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _getName(
            alignment,
            message,
            context,
            colorPalette,
            typography,
            spacing,
            template,
            messageBubbleStyleData,
            senderNameOverride: senderNameOverride,
            showSentDate: showSentDate,
          ),
        );
      }
    }
    return const SizedBox();
  }

  static Widget _getName(
    BubbleAlignment alignment,
    ChatMessage message,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
    CometChatMessageTemplate? template,
    ConvoKitMessageBubbleStyleData? messageBubbleStyleData, {
    String? senderNameOverride,
    bool showSentDate = false,
  }) {
    // List surfaces (the ones showing the date) give the name a little more
    // presence than a chat bubble does — it is the row's title there, not a
    // caption above the message.
    final baseNameSize = typography.caption1?.medium?.fontSize;
    final nameText = Text(
      senderNameOverride ?? message.sender.name,
      style: TextStyle(
        fontSize: showSentDate && baseNameSize != null
            ? baseNameSize + 2
            : baseNameSize,
        color: colorPalette.primary,
        fontWeight: showSentDate
            ? FontWeight.w500
            : typography.caption1?.medium?.fontWeight,
        fontFamily: typography.caption1?.medium?.fontFamily,
        letterSpacing: 0,
      ).merge(messageBubbleStyleData?.senderNameTextStyle),
      overflow: TextOverflow.ellipsis,
    );

    final sentAt = message.serverCreatedAt ?? message.createdAt;
    return Padding(
      padding: EdgeInsets.only(
        right: spacing.padding2 ?? 0,
        left: spacing.padding2 ?? 0,
      ),
      child: !showSentDate
          ? nameText
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The name yields first: a long name ellipsizes rather than
                // pushing the date out of the row.
                Flexible(child: nameText),
                Text(
                  ' • ${DateFormat('dd/MM/yyyy').format(sentAt)}',
                  style: TextStyle(
                    fontSize: typography.caption1?.regular?.fontSize,
                    color: colorPalette.textSecondary,
                    fontWeight: typography.caption1?.regular?.fontWeight,
                    fontFamily: typography.caption1?.regular?.fontFamily,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
    );
  }

  static Widget _getTime(
    ChatMessage messageObject,
    ConvoKitColorPalette? colorPalette,
    ConvoKitTypography? typography,
    BubbleAlignment alignment,
    ConvoKitDateStyle? dateStyle, {
    bool compact = false,
  }) {
    final DateTime lastMessageTime =
        messageObject.serverCreatedAt ?? messageObject.createdAt;
    return ConvoKitDate(
      date: lastMessageTime,
      pattern: DateTimePattern.timeFormat,
      isTransparentBackground: true,
      padding: compact ? EdgeInsets.zero : null,
      style: ConvoKitDateStyle(
        backgroundColor: Colors.transparent,
        textStyle: TextStyle(
          color: alignment == BubbleAlignment.right
              ? colorPalette?.white
              : colorPalette?.neutral600,
          fontSize: typography?.caption2?.regular?.fontSize,
          fontWeight: typography?.caption2?.regular?.fontWeight,
          fontFamily: typography?.caption2?.regular?.fontFamily,
        ),
        border: Border.all(color: Colors.transparent, width: 0),
      ).merge(dateStyle),
    );
  }

  static Widget _getReceiptIcon(
    ChatMessage message,
    ConvoKitColorPalette colorPalette,
    ConvoKitSpacing spacing,
    CometChatMessageReceiptStyle? receiptStyle,
  ) {
    ReceiptStatus status = MessageReceiptUtils.getReceiptStatus(message);

    return Padding(
      padding: EdgeInsets.only(left: spacing.padding1 ?? 0),
      child: ConvoKitReceipt(
        status: status,
        size: 16,
        style: CometChatMessageReceiptStyle(
          deliveredIconColor: colorPalette.iconSecondary,
          readIconColor: colorPalette.messageSeen,
          sentIconColor: colorPalette.iconSecondary,
          waitIconColor: colorPalette.iconSecondary,
        ).merge(receiptStyle),
      ),
    );
  }
}

///the following extension [BubbleUIBuilder] is used to build the UI of the message bubbles.
extension BubbleUIBuilder on MessageUtils {
  static ConvoKitMessageBubbleStyleData? getBubbleStyle(
    ChatMessage message,
    CometChatOutgoingMessageBubbleStyle? outgoingMessageBubbleStyle,
    CometChatIncomingMessageBubbleStyle? incomingMessageBubbleStyle,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  ) {
    final isSent =
        ConvoKitUIKit.loggedInUser != null &&
        message.sender.id == ConvoKitUIKit.loggedInUser!.id;
    if (message is CustomMessage && message.kind == 'deleted') {
      return ConvoKitMessageBubbleStyleData(
        backgroundColor: isSent
            ? outgoingMessageBubbleStyle?.deletedBubbleStyle?.backgroundColor
            : incomingMessageBubbleStyle?.deletedBubbleStyle?.backgroundColor,
        border: isSent
            ? outgoingMessageBubbleStyle?.deletedBubbleStyle?.border
            : incomingMessageBubbleStyle?.deletedBubbleStyle?.border,
        borderRadius: isSent
            ? outgoingMessageBubbleStyle?.deletedBubbleStyle?.borderRadius
            : incomingMessageBubbleStyle?.deletedBubbleStyle?.borderRadius,
        threadedMessageIndicatorIconColor: isSent
            ? outgoingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.threadedMessageIndicatorIconColor
            : incomingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.threadedMessageIndicatorIconColor,
        messageBubbleAvatarStyle: isSent
            ? outgoingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleAvatarStyle
            : incomingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleAvatarStyle,
        senderNameTextStyle:
            incomingMessageBubbleStyle?.deletedBubbleStyle?.senderNameTextStyle,
        messageReceiptStyle:
            outgoingMessageBubbleStyle?.deletedBubbleStyle?.messageReceiptStyle,
        messageBubbleDateStyle: isSent
            ? outgoingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleDateStyle
            : incomingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleDateStyle,
        messageBubbleBackgroundImage: isSent
            ? outgoingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleBackgroundImage
            : incomingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.messageBubbleBackgroundImage,
        threadedMessageIndicatorTextStyle: isSent
            ? outgoingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.threadedMessageIndicatorTextStyle
            : incomingMessageBubbleStyle
                  ?.deletedBubbleStyle
                  ?.threadedMessageIndicatorTextStyle,
      );
    }

    final String msgCategory = message is CustomMessage
        ? (message.kind == MessageTypeConstants.card
            ? MessageCategoryConstants.card
            : MessageCategoryConstants.custom)
        : MessageCategoryConstants.message;
    final String msgType = switch (message) {
      TextMessage _ => MessageTypeConstants.text,
      MediaMessage m => switch (m.attachment.kind) {
        AttachmentKind.image => MessageTypeConstants.image,
        AttachmentKind.video => MessageTypeConstants.video,
        AttachmentKind.audio => MessageTypeConstants.audio,
        AttachmentKind.file => MessageTypeConstants.file,
      },
      CustomMessage c => c.kind,
    };
    String key = "$msgCategory$msgType";
    if (key ==
            MessageCategoryConstants.action +
                MessageTypeConstants.groupActions ||
        key == MessageCategoryConstants.call + CallTypeConstants.audioCall ||
        key == MessageCategoryConstants.call + CallTypeConstants.videoCall) {
      return ConvoKitMessageBubbleStyleData(
        backgroundColor: colorPalette.transparent,
      );
    }
    ConvoKitMessageBubbleStyleData? messageBubbleStyleData;
    switch (key) {
      case const (MessageCategoryConstants.message + MessageTypeConstants.text):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle?.textBubbleStyle?.backgroundColor
              : incomingMessageBubbleStyle?.textBubbleStyle?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle?.textBubbleStyle?.border
              : incomingMessageBubbleStyle?.textBubbleStyle?.border,
          borderRadius: isSent
              ? getSentTextMediaBorderRadiusGeometry(
                  message,
                  outgoingMessageBubbleStyle?.textBubbleStyle?.borderRadius,
                  colorPalette,
                  typography,
                  spacing,
                )
              : incomingMessageBubbleStyle?.textBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle:
              incomingMessageBubbleStyle?.textBubbleStyle?.senderNameTextStyle,
          messageReceiptStyle:
              outgoingMessageBubbleStyle?.textBubbleStyle?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.textBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.message +
          MessageTypeConstants.image):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle?.imageBubbleStyle?.backgroundColor
              : incomingMessageBubbleStyle?.imageBubbleStyle?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle?.imageBubbleStyle?.border
              : incomingMessageBubbleStyle?.imageBubbleStyle?.border,
          borderRadius: isSent
              ? getSentTextMediaBorderRadiusGeometry(
                  message,
                  outgoingMessageBubbleStyle?.imageBubbleStyle?.borderRadius,
                  colorPalette,
                  typography,
                  spacing,
                )
              : incomingMessageBubbleStyle?.imageBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle:
              incomingMessageBubbleStyle?.imageBubbleStyle?.senderNameTextStyle,
          messageReceiptStyle:
              outgoingMessageBubbleStyle?.imageBubbleStyle?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.imageBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.message + MessageTypeConstants.file):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle?.fileBubbleStyle?.backgroundColor
              : incomingMessageBubbleStyle?.fileBubbleStyle?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle?.fileBubbleStyle?.border
              : incomingMessageBubbleStyle?.fileBubbleStyle?.border,
          borderRadius: isSent
              ? getSentTextMediaBorderRadiusGeometry(
                  message,
                  outgoingMessageBubbleStyle?.fileBubbleStyle?.borderRadius,
                  colorPalette,
                  typography,
                  spacing,
                )
              : incomingMessageBubbleStyle?.fileBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle:
              incomingMessageBubbleStyle?.fileBubbleStyle?.senderNameTextStyle,
          messageReceiptStyle:
              outgoingMessageBubbleStyle?.fileBubbleStyle?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.fileBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.message +
          MessageTypeConstants.video):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle?.videoBubbleStyle?.backgroundColor
              : incomingMessageBubbleStyle?.videoBubbleStyle?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle?.videoBubbleStyle?.border
              : incomingMessageBubbleStyle?.videoBubbleStyle?.border,
          borderRadius: isSent
              ? getSentTextMediaBorderRadiusGeometry(
                  message,
                  outgoingMessageBubbleStyle?.videoBubbleStyle?.borderRadius,
                  colorPalette,
                  typography,
                  spacing,
                )
              : incomingMessageBubbleStyle?.videoBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle:
              incomingMessageBubbleStyle?.videoBubbleStyle?.senderNameTextStyle,
          messageReceiptStyle:
              outgoingMessageBubbleStyle?.videoBubbleStyle?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.videoBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.message +
          MessageTypeConstants.audio):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.backgroundColor
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.border
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.border,
          borderRadius: isSent
              ? getSentTextMediaBorderRadiusGeometry(
                  message,
                  outgoingMessageBubbleStyle
                      ?.effectiveVoiceNoteBubbleStyle
                      ?.borderRadius,
                  colorPalette,
                  typography,
                  spacing,
                )
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle: incomingMessageBubbleStyle
              ?.effectiveVoiceNoteBubbleStyle
              ?.senderNameTextStyle,
          messageReceiptStyle: outgoingMessageBubbleStyle
              ?.effectiveVoiceNoteBubbleStyle
              ?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.effectiveVoiceNoteBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.custom +
          ExtensionType.extensionPoll):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle?.pollsBubbleStyle?.backgroundColor
              : incomingMessageBubbleStyle?.pollsBubbleStyle?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle?.pollsBubbleStyle?.border
              : incomingMessageBubbleStyle?.pollsBubbleStyle?.border,
          borderRadius: isSent
              ? outgoingMessageBubbleStyle?.pollsBubbleStyle?.borderRadius
              : incomingMessageBubbleStyle?.pollsBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle:
              incomingMessageBubbleStyle?.pollsBubbleStyle?.senderNameTextStyle,
          messageReceiptStyle:
              outgoingMessageBubbleStyle?.pollsBubbleStyle?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.pollsBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.custom + ExtensionType.document):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.backgroundColor
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.border
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.border,
          borderRadius: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.borderRadius
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle: incomingMessageBubbleStyle
              ?.collaborativeDocumentBubbleStyle
              ?.senderNameTextStyle,
          messageReceiptStyle: outgoingMessageBubbleStyle
              ?.collaborativeDocumentBubbleStyle
              ?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeDocumentBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.custom + ExtensionType.whiteboard):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.backgroundColor
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.backgroundColor,
          border: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.border
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.border,
          borderRadius: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.borderRadius
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle: incomingMessageBubbleStyle
              ?.collaborativeWhiteboardBubbleStyle
              ?.senderNameTextStyle,
          messageReceiptStyle: outgoingMessageBubbleStyle
              ?.collaborativeWhiteboardBubbleStyle
              ?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.collaborativeWhiteboardBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.custom + ExtensionType.sticker):
        messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
          backgroundColor:
              (isSent
                  ? outgoingMessageBubbleStyle
                        ?.stickerBubbleStyle
                        ?.backgroundColor
                  : incomingMessageBubbleStyle
                        ?.stickerBubbleStyle
                        ?.backgroundColor) ??
              colorPalette.transparent,
          border: isSent
              ? outgoingMessageBubbleStyle?.stickerBubbleStyle?.border
              : incomingMessageBubbleStyle?.stickerBubbleStyle?.border,
          borderRadius: isSent
              ? outgoingMessageBubbleStyle?.stickerBubbleStyle?.borderRadius
              : incomingMessageBubbleStyle?.stickerBubbleStyle?.borderRadius,
          threadedMessageIndicatorIconColor: isSent
              ? outgoingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.threadedMessageIndicatorIconColor
              : incomingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.threadedMessageIndicatorIconColor,
          messageBubbleAvatarStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleAvatarStyle
              : incomingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleAvatarStyle,
          senderNameTextStyle: incomingMessageBubbleStyle
              ?.stickerBubbleStyle
              ?.senderNameTextStyle,
          messageReceiptStyle: outgoingMessageBubbleStyle
              ?.stickerBubbleStyle
              ?.messageReceiptStyle,
          messageBubbleDateStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleDateStyle
              : incomingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleDateStyle,
          messageBubbleBackgroundImage: isSent
              ? outgoingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleBackgroundImage
              : incomingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.messageBubbleBackgroundImage,
          threadedMessageIndicatorTextStyle: isSent
              ? outgoingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.threadedMessageIndicatorTextStyle
              : incomingMessageBubbleStyle
                    ?.stickerBubbleStyle
                    ?.threadedMessageIndicatorTextStyle,
        );
        break;
      case const (MessageCategoryConstants.custom +
          MessageTypeConstants.meeting):
        CustomMessage msg = message as CustomMessage;
        String? callType;
        if (msg.data.containsKey('callType')) {
          callType = msg.data['callType'] as String?;
        }
        if (callType == CallTypeConstants.audioCall) {
          messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
            backgroundColor: isSent
                ? outgoingMessageBubbleStyle
                          ?.voiceCallBubbleStyle
                          ?.backgroundColor ??
                      colorPalette.primary
                : incomingMessageBubbleStyle
                          ?.voiceCallBubbleStyle
                          ?.backgroundColor ??
                      colorPalette.neutral300,
            border: isSent
                ? outgoingMessageBubbleStyle?.voiceCallBubbleStyle?.border
                : incomingMessageBubbleStyle?.voiceCallBubbleStyle?.border,
            borderRadius: isSent
                ? outgoingMessageBubbleStyle?.voiceCallBubbleStyle?.borderRadius
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.borderRadius,
            threadedMessageIndicatorIconColor: isSent
                ? outgoingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.threadedMessageIndicatorIconColor
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.threadedMessageIndicatorIconColor,
            messageBubbleAvatarStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleAvatarStyle
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleAvatarStyle,
            senderNameTextStyle: incomingMessageBubbleStyle
                ?.voiceCallBubbleStyle
                ?.senderNameTextStyle,
            messageReceiptStyle: outgoingMessageBubbleStyle
                ?.voiceCallBubbleStyle
                ?.messageReceiptStyle,
            messageBubbleDateStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleDateStyle
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleDateStyle,
            messageBubbleBackgroundImage: isSent
                ? outgoingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleBackgroundImage
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.messageBubbleBackgroundImage,
            threadedMessageIndicatorTextStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.threadedMessageIndicatorTextStyle
                : incomingMessageBubbleStyle
                      ?.voiceCallBubbleStyle
                      ?.threadedMessageIndicatorTextStyle,
          );
        } else {
          messageBubbleStyleData = ConvoKitMessageBubbleStyleData(
            backgroundColor: isSent
                ? outgoingMessageBubbleStyle
                          ?.videoCallBubbleStyle
                          ?.backgroundColor ??
                      colorPalette.primary
                : incomingMessageBubbleStyle
                          ?.videoCallBubbleStyle
                          ?.backgroundColor ??
                      colorPalette.neutral300,
            border: isSent
                ? outgoingMessageBubbleStyle?.videoCallBubbleStyle?.border
                : incomingMessageBubbleStyle?.videoCallBubbleStyle?.border,
            borderRadius: isSent
                ? outgoingMessageBubbleStyle?.videoCallBubbleStyle?.borderRadius
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.borderRadius,
            threadedMessageIndicatorIconColor: isSent
                ? outgoingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.threadedMessageIndicatorIconColor
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.threadedMessageIndicatorIconColor,
            messageBubbleAvatarStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleAvatarStyle
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleAvatarStyle,
            senderNameTextStyle: incomingMessageBubbleStyle
                ?.videoCallBubbleStyle
                ?.senderNameTextStyle,
            messageReceiptStyle: outgoingMessageBubbleStyle
                ?.videoCallBubbleStyle
                ?.messageReceiptStyle,
            messageBubbleDateStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleDateStyle
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleDateStyle,
            messageBubbleBackgroundImage: isSent
                ? outgoingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleBackgroundImage
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.messageBubbleBackgroundImage,
            threadedMessageIndicatorTextStyle: isSent
                ? outgoingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.threadedMessageIndicatorTextStyle
                : incomingMessageBubbleStyle
                      ?.videoCallBubbleStyle
                      ?.threadedMessageIndicatorTextStyle,
          );
        }
        break;
    }

    final defaultMessageBubbleStyleData = ConvoKitMessageBubbleStyleData(
      backgroundColor: isSent
          ? outgoingMessageBubbleStyle?.backgroundColor ?? colorPalette.primary
          : incomingMessageBubbleStyle?.backgroundColor ??
                colorPalette.neutral300,
      border: isSent
          ? outgoingMessageBubbleStyle?.border
          : incomingMessageBubbleStyle?.border,
      borderRadius: isSent
          ? outgoingMessageBubbleStyle?.borderRadius
          : incomingMessageBubbleStyle?.borderRadius,
      threadedMessageIndicatorIconColor: isSent
          ? outgoingMessageBubbleStyle?.threadedMessageIndicatorIconColor
          : incomingMessageBubbleStyle?.threadedMessageIndicatorIconColor,
      messageBubbleAvatarStyle: isSent
          ? outgoingMessageBubbleStyle?.messageBubbleAvatarStyle
          : incomingMessageBubbleStyle?.messageBubbleAvatarStyle,
      senderNameTextStyle: incomingMessageBubbleStyle?.senderNameTextStyle,
      messageReceiptStyle: outgoingMessageBubbleStyle?.messageReceiptStyle,
      messageBubbleDateStyle: isSent
          ? outgoingMessageBubbleStyle?.messageBubbleDateStyle
          : incomingMessageBubbleStyle?.messageBubbleDateStyle,
      messageBubbleBackgroundImage: isSent
          ? outgoingMessageBubbleStyle?.messageBubbleBackgroundImage
          : incomingMessageBubbleStyle?.messageBubbleBackgroundImage,
      threadedMessageIndicatorTextStyle: isSent
          ? outgoingMessageBubbleStyle?.threadedMessageIndicatorTextStyle
          : incomingMessageBubbleStyle?.threadedMessageIndicatorTextStyle,
    );

    return messageBubbleStyleData?.mergeIfNull(defaultMessageBubbleStyleData);
  }

  static AdditionalConfigurations? getAdditionalConfigurations(
    BuildContext context,
    ChatMessage message,
    List<CometChatTextFormatter>? formatters,
    CometChatIncomingMessageBubbleStyle? incomingMessageBubbleStyle2,
    CometChatOutgoingMessageBubbleStyle? outgoingMessageBubbleStyle2,
    ConvoKitActionBubbleStyle? actionBubbleStyle2,
  ) {
    AdditionalConfigurations? additionalConfigurations;
    final outgoingMessageBubbleStyle =
        ConvoKitThemeHelper.getTheme<CometChatOutgoingMessageBubbleStyle>(
          context: context,
          defaultTheme: CometChatOutgoingMessageBubbleStyle.of,
        ).merge(outgoingMessageBubbleStyle2);
    final incomingMessageBubbleStyle =
        ConvoKitThemeHelper.getTheme<CometChatIncomingMessageBubbleStyle>(
          context: context,
          defaultTheme: CometChatIncomingMessageBubbleStyle.of,
        ).merge(incomingMessageBubbleStyle2);
    final isSent =
        ConvoKitUIKit.loggedInUser != null &&
        message.sender.id == ConvoKitUIKit.loggedInUser!.id;

    final actionBubbleStyle =
        ConvoKitThemeHelper.getTheme<ConvoKitActionBubbleStyle>(
          context: context,
          defaultTheme: ConvoKitActionBubbleStyle.of,
        ).merge(actionBubbleStyle2);

    List<CometChatTextFormatter> textFormatters =
        BubbleUIBuilder.getTextFormatters(message, formatters ?? []);

    additionalConfigurations = AdditionalConfigurations(
      textFormatters: textFormatters,
      textBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.textBubbleStyle
                  : incomingMessageBubbleStyle.textBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      imageBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.imageBubbleStyle
                  : incomingMessageBubbleStyle.imageBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      fileBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.fileBubbleStyle
                  : incomingMessageBubbleStyle.fileBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      videoBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.videoBubbleStyle
                  : incomingMessageBubbleStyle.videoBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      audioBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.effectiveVoiceNoteBubbleStyle
                  : incomingMessageBubbleStyle.effectiveVoiceNoteBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      actionBubbleStyle: actionBubbleStyle,
      deletedBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.deletedBubbleStyle
                  : incomingMessageBubbleStyle.deletedBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      linkPreviewBubbleStyle: isSent
          ? outgoingMessageBubbleStyle.linkPreviewBubbleStyle
          : incomingMessageBubbleStyle.linkPreviewBubbleStyle,
      messageTranslationBubbleStyle: isSent
          ? outgoingMessageBubbleStyle.messageTranslationBubbleStyle
          : incomingMessageBubbleStyle.messageTranslationBubbleStyle,
      pollsBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.pollsBubbleStyle
                  : incomingMessageBubbleStyle.pollsBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      stickerBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.stickerBubbleStyle
                  : incomingMessageBubbleStyle.stickerBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      collaborativeDocumentBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.collaborativeDocumentBubbleStyle
                  : incomingMessageBubbleStyle.collaborativeDocumentBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      collaborativeWhiteboardBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle
                        .collaborativeWhiteboardBubbleStyle
                  : incomingMessageBubbleStyle
                        .collaborativeWhiteboardBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      voiceCallBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.voiceCallBubbleStyle
                  : incomingMessageBubbleStyle.voiceCallBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
      videoCallBubbleStyle:
          (isSent
                  ? outgoingMessageBubbleStyle.videoCallBubbleStyle
                  : incomingMessageBubbleStyle.videoCallBubbleStyle)
              ?.copyWith(
                border: Border.all(color: Colors.transparent, width: 0),
              ),
    );

    return additionalConfigurations;
  }

  static List<CometChatTextFormatter> getTextFormatters(
    ChatMessage message,
    List<CometChatTextFormatter> textFormatters,
  ) {
    if (message is TextMessage) {
      for (CometChatTextFormatter textFormatter in textFormatters) {
        textFormatter.message = message;
      }
    }
    return textFormatters;
  }

  // This method is used to get the border radius for sent text and media messages.
  // If the message is disapproved, it returns a specific border radius.
  static BorderRadiusGeometry? getSentTextMediaBorderRadiusGeometry(
    ChatMessage message,
    BorderRadiusGeometry? borderRadius,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  ) {
    final moderationUtil = ModerationCheckUtil.instance;
    final meta = message is CustomMessage ? message.data : null;
    if (meta != null &&
        (meta.containsValue(ErrorConstants.fileErrorCodeAndroid) ||
            meta.containsValue(ErrorConstants.fileErrorCodeIOS))) {
      return BorderRadius.only(
        topLeft: Radius.circular(spacing.radius4 ?? 16),
        topRight: Radius.circular(spacing.radius4 ?? 16),
      );
    }
    if (moderationUtil.hideModerationStatus == false &&
        ModerationCheckUtil.instance.isMessageDisapprovedFromModeration(
          message,
        )) {
      return BorderRadius.only(
        topLeft: Radius.circular(spacing.radius4 ?? 16),
        topRight: Radius.circular(spacing.radius4 ?? 16),
      );
    } else {
      return borderRadius;
    }
  }
}

///[ConvoKitMessageBubbleStyleData] is a model class which contains the style properties for the message bubble.
class ConvoKitMessageBubbleStyleData {
  ConvoKitMessageBubbleStyleData({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.messageBubbleDateStyle,
    this.messageBubbleAvatarStyle,
    this.messageBubbleBackgroundImage,
    this.threadedMessageIndicatorIconColor,
    this.threadedMessageIndicatorTextStyle,
    this.senderNameTextStyle,
    this.messageReceiptStyle,
    this.moderationBackgroundColor,
    this.moderationTextStyle,
    this.moderationIconTint,
    this.exceptionBackgroundColor,
    this.exceptionTextStyle,
    this.exceptionIconTint,
  });

  ///[messageBubbleBackgroundImage] provides background image to the message bubble of a received message
  DecorationImage? messageBubbleBackgroundImage;

  ///[backgroundColor] provides background color to the message bubble of a received message
  Color? backgroundColor;

  ///[border] provides border to the message bubble of a received message
  BoxBorder? border;

  ///[borderRadius] provides border radius to the message bubble of a received message
  BorderRadiusGeometry? borderRadius;

  ///[threadedMessageIndicatorTextStyle] provides text style to the threaded message indicator
  TextStyle? threadedMessageIndicatorTextStyle;

  ///[threadedMessageIndicatorIconColor] provides color to the threaded message icon
  Color? threadedMessageIndicatorIconColor;

  ///[messageBubbleAvatarStyle] provides style to the avatar of the senderConvoKitAvatarStyle? messageBubbleAvatarStyle;
  ConvoKitAvatarStyle? messageBubbleAvatarStyle;

  ///[messageBubbleDateStyle] provides style to the date of the message bubble
  ConvoKitDateStyle? messageBubbleDateStyle;

  ///[senderNameTextStyle] provides style to the sender name of the received message
  TextStyle? senderNameTextStyle;

  ///[messageReceiptStyle] provides style to the message receipt
  CometChatMessageReceiptStyle? messageReceiptStyle;

  ///[moderationBackgroundColor] provides background color to the moderated view
  final Color? moderationBackgroundColor;

  ///[moderationTextStyle] provides text style to the moderated view warning text
  final TextStyle? moderationTextStyle;

  ///[moderationIconTint] provides icon color for the moderated view warning icon
  final Color? moderationIconTint;

  ///[exceptionBackgroundColor] provides background color to the exception view
  final Color? exceptionBackgroundColor;

  ///[exceptionTextStyle] provides text style to the exception view warning text
  final TextStyle? exceptionTextStyle;

  ///[exceptionIconTint] provides icon color for the exception view warning icon
  final Color? exceptionIconTint;

  ConvoKitMessageBubbleStyleData copyWith({
    DecorationImage? messageBubbleBackgroundImage,
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    TextStyle? threadedMessageIndicatorTextStyle,
    Color? threadedMessageIndicatorIconColor,
    ConvoKitAvatarStyle? messageBubbleAvatarStyle,
    ConvoKitDateStyle? messageBubbleDateStyle,
    TextStyle? senderNameTextStyle,
    CometChatMessageReceiptStyle? messageReceiptStyle,
    Color? moderationBackgroundColor,
    TextStyle? moderationTextStyle,
    Color? moderationIconTint,
    Color? exceptionBackgroundColor,
    TextStyle? exceptionTextStyle,
    Color? exceptionIconTint,
  }) {
    return ConvoKitMessageBubbleStyleData(
      messageBubbleBackgroundImage:
          messageBubbleBackgroundImage ?? this.messageBubbleBackgroundImage,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      threadedMessageIndicatorTextStyle:
          threadedMessageIndicatorTextStyle ??
          this.threadedMessageIndicatorTextStyle,
      threadedMessageIndicatorIconColor:
          threadedMessageIndicatorIconColor ??
          this.threadedMessageIndicatorIconColor,
      messageBubbleAvatarStyle:
          messageBubbleAvatarStyle ?? this.messageBubbleAvatarStyle,
      messageBubbleDateStyle:
          messageBubbleDateStyle ?? this.messageBubbleDateStyle,
      senderNameTextStyle: senderNameTextStyle ?? this.senderNameTextStyle,
      messageReceiptStyle: messageReceiptStyle ?? this.messageReceiptStyle,
      moderationBackgroundColor:
          moderationBackgroundColor ?? this.moderationBackgroundColor,
      moderationTextStyle: moderationTextStyle ?? this.moderationTextStyle,
      moderationIconTint: moderationIconTint ?? this.moderationIconTint,
      exceptionBackgroundColor:
          exceptionBackgroundColor ?? this.exceptionBackgroundColor,
      exceptionTextStyle: exceptionTextStyle ?? this.exceptionTextStyle,
      exceptionIconTint: exceptionIconTint ?? this.exceptionIconTint,
    );
  }

  ConvoKitMessageBubbleStyleData merge(
    ConvoKitMessageBubbleStyleData? other,
  ) {
    if (other == null) return this;
    return copyWith(
      messageBubbleBackgroundImage: other.messageBubbleBackgroundImage,
      backgroundColor: other.backgroundColor,
      border: other.border,
      borderRadius: other.borderRadius,
      threadedMessageIndicatorTextStyle:
          other.threadedMessageIndicatorTextStyle,
      threadedMessageIndicatorIconColor:
          other.threadedMessageIndicatorIconColor,
      messageBubbleAvatarStyle: other.messageBubbleAvatarStyle,
      messageBubbleDateStyle: other.messageBubbleDateStyle,
      senderNameTextStyle: other.senderNameTextStyle,
      messageReceiptStyle: other.messageReceiptStyle,
      moderationBackgroundColor: other.moderationBackgroundColor,
      moderationTextStyle: other.moderationTextStyle,
      moderationIconTint: other.moderationIconTint,
      exceptionBackgroundColor: other.exceptionBackgroundColor,
      exceptionTextStyle: other.exceptionTextStyle,
      exceptionIconTint: other.exceptionIconTint,
    );
  }

  ConvoKitMessageBubbleStyleData mergeIfNull(
    ConvoKitMessageBubbleStyleData? other,
  ) {
    if (other == null) return this;
    return copyWith(
      messageBubbleBackgroundImage:
          messageBubbleBackgroundImage ?? other.messageBubbleBackgroundImage,
      backgroundColor: backgroundColor ?? other.backgroundColor,
      border: border ?? other.border,
      borderRadius: borderRadius ?? other.borderRadius,
      threadedMessageIndicatorTextStyle:
          threadedMessageIndicatorTextStyle ??
          other.threadedMessageIndicatorTextStyle,
      threadedMessageIndicatorIconColor:
          threadedMessageIndicatorIconColor ??
          other.threadedMessageIndicatorIconColor,
      messageBubbleAvatarStyle:
          messageBubbleAvatarStyle ?? other.messageBubbleAvatarStyle,
      messageBubbleDateStyle:
          messageBubbleDateStyle ?? other.messageBubbleDateStyle,
      senderNameTextStyle: senderNameTextStyle ?? other.senderNameTextStyle,
      messageReceiptStyle: messageReceiptStyle ?? other.messageReceiptStyle,
      moderationBackgroundColor:
          moderationBackgroundColor ?? other.moderationBackgroundColor,
      moderationTextStyle: moderationTextStyle ?? other.moderationTextStyle,
      moderationIconTint: moderationIconTint ?? other.moderationIconTint,
      exceptionBackgroundColor:
          exceptionBackgroundColor ?? other.exceptionBackgroundColor,
      exceptionTextStyle: exceptionTextStyle ?? other.exceptionTextStyle,
      exceptionIconTint: exceptionIconTint ?? other.exceptionIconTint,
    );
  }
}
