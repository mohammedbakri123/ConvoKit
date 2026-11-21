import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';

/// Utility helpers for the message composer.
class ComposerUtils {
  ComposerUtils._();

  /// Returns a small icon widget representing the media type of [message],
  /// or null for plain text or custom messages.
  static Widget? getReplyIcon(
    ChatMessage message,
    BuildContext context,
    Color? color,
  ) {
    if (message is! MediaMessage) return null;

    final icon = switch (message.attachment.kind) {
      AttachmentKind.image => Icons.image_outlined,
      AttachmentKind.video => Icons.videocam_outlined,
      AttachmentKind.audio => Icons.mic_outlined,
      AttachmentKind.file => Icons.insert_drive_file_outlined,
    };

    return Icon(icon, size: 14, color: color);
  }
}
