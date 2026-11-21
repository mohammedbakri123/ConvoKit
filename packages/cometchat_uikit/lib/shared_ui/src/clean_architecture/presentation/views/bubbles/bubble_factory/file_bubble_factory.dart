import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../../../core/constants/enums.dart';
import '../../../theme/colors/cometchat_color_palette.dart';
import '../../../theme/typography/cometchat_typography.dart';
import '../../../theme/spacing/cometchat_spacing.dart';
import '../file_bubble/cometchat_file_bubble.dart';
import '../file_bubble/cometchat_file_bubble_style.dart';
import 'bubble_factory.dart';

/// Factory for creating file message bubbles.
class FileBubbleFactory extends BubbleFactory<MediaMessage> {
  final Icon? downloadIcon;
  final CometChatFileBubbleStyle? style;

  FileBubbleFactory({this.style, this.downloadIcon});

  String? _extractExtension(String? fileName) {
    if (fileName == null || !fileName.contains('.')) return null;
    return fileName.split('.').last;
  }

  @override
  Widget build(
    BuildContext context,
    MediaMessage message,
    BubbleAlignment alignment, {
    ConvoKitColorPalette? colorPalette,
    ConvoKitTypography? typography,
    ConvoKitSpacing? spacing,
  }) {
    final att = message.attachment;
    return CometChatFileBubble(
      fileUrl: att.url ?? att.localPath,
      title: att.name,
      fileMimeType: att.mimeType,
      fileExtension: _extractExtension(att.name),
      fileSize: att.sizeBytes,
      style: style,
      alignment: alignment,
      id: int.tryParse(message.id ?? ''),
      dateTime: message.createdAt,
      downloadIcon: downloadIcon,
    );
  }
}
