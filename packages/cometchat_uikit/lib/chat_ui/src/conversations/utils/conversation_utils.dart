import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';

/// Utility class for conversation-related operations.
class ConversationUtils {
  /// Gets the conversation title (peer name or group name).
  static String getConversationTitle(ChatConversation conversation) {
    if (conversation.peer != null) {
      return conversation.peer!.name;
    }
    if (conversation.group != null) {
      return conversation.group!.name;
    }
    return conversation.id;
  }

  /// Gets the conversation avatar URL (peer avatar or group avatar).
  static String? getConversationAvatar(ChatConversation conversation) {
    if (conversation.peer != null) {
      return conversation.peer!.avatarUrl;
    }
    if (conversation.group != null) {
      return conversation.group!.avatarUrl;
    }
    return null;
  }

  /// Gets the last message text with appropriate formatting.
  static String getLastMessageText(BuildContext context, ChatMessage? message) {
    if (message == null) {
      return Translations.of(context).tapToStartConversation;
    }

    return switch (message) {
      TextMessage t => t.text,
      MediaMessage m => _getMediaMessageText(context, m),
      CustomMessage c => _getCustomMessageText(context, c),
    };
  }

  /// Gets the message type icon for display in subtitle.
  static IconData? getMessageTypeIcon(ChatMessage? message) {
    if (message == null) return null;

    if (message.repliedTo != null) {
      return Icons.forum_outlined;
    }

    return switch (message) {
      TextMessage _ => null,
      MediaMessage m => switch (m.attachment.kind) {
        AttachmentKind.image => Icons.image_outlined,
        AttachmentKind.video => Icons.videocam_outlined,
        AttachmentKind.audio => Icons.audiotrack_outlined,
        AttachmentKind.file => Icons.insert_drive_file_outlined,
      },
      CustomMessage c => switch (c.kind) {
        'extension_poll' => Icons.poll_outlined,
        'extension_sticker' => Icons.sticky_note_2_outlined,
        _ => Icons.extension_outlined,
      },
    };
  }

  static String _getMediaMessageText(
    BuildContext context,
    MediaMessage message,
  ) {
    if (message.caption != null && message.caption!.trim().isNotEmpty) {
      return message.caption!;
    }
    final t = Translations.of(context);
    return switch (message.attachment.kind) {
      AttachmentKind.image => t.messageImage,
      AttachmentKind.video => t.messageVideo,
      AttachmentKind.audio => t.messageAudio,
      AttachmentKind.file => t.messageFile,
    };
  }

  static String _getCustomMessageText(
    BuildContext context,
    CustomMessage message,
  ) {
    final t = Translations.of(context);
    if (message.kind == 'extension_poll') {
      return t.customMessagePoll;
    }
    if (message.kind == 'extension_sticker') {
      return t.customMessageSticker;
    }
    final text = message.data['text'] ?? message.data['message'];
    if (text is String && text.isNotEmpty) {
      return text;
    }
    return message.kind.isNotEmpty ? message.kind : t.customMessage;
  }
}
