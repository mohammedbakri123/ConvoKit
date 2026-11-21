import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../../../core/constants/enums.dart';
import '../../../theme/colors/cometchat_color_palette.dart';
import '../../../theme/typography/cometchat_typography.dart';
import '../../../theme/spacing/cometchat_spacing.dart';

/// Callback for providing custom views for message bubble slots.
typedef BubbleViewProvider =
    Widget? Function(
      BuildContext context,
      ChatMessage message,
      BubbleAlignment alignment,
    );

/// Abstract factory for creating message bubble content widgets.
abstract class BubbleFactory<T extends ChatMessage> {
  Widget build(
    BuildContext context,
    T message,
    BubbleAlignment alignment, {
    ConvoKitColorPalette? colorPalette,
    ConvoKitTypography? typography,
    ConvoKitSpacing? spacing,
  });

  /// Returns the factory key for a given [ChatMessage] using exhaustive switch.
  static String getFactoryKey(ChatMessage message) {
    return switch (message) {
      TextMessage _ => 'message_text',
      MediaMessage m => switch (m.attachment.kind) {
        AttachmentKind.image => 'message_image',
        AttachmentKind.video => 'message_video',
        AttachmentKind.audio => 'message_audio',
        AttachmentKind.file => 'message_file',
      },
      CustomMessage c =>
        c.kind == 'deleted' ? 'deleted' : 'custom_${c.kind}',
    };
  }

  static String createKey(String category, String type) => '${category}_$type';
}
