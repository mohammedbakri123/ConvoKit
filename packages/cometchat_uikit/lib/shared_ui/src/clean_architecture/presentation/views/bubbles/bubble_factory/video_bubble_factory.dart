import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../../../core/constants/enums.dart';
import '../../../theme/colors/cometchat_color_palette.dart';
import '../../../theme/typography/cometchat_typography.dart';
import '../../../theme/spacing/cometchat_spacing.dart';
import '../video_bubble/cometchat_video_bubble.dart';
import '../video_bubble/cometchat_video_bubble_style.dart';
import 'bubble_factory.dart';

/// Factory for creating video message bubbles.
class VideoBubbleFactory extends BubbleFactory<MediaMessage> {
  @Deprecated(
    'Has no effect. For the colour shown while a thumbnail loads, use CometChatVideosBubbleStyle.placeholderColor. Will be removed in 7.0.0.',
  )
  final String? placeHolderImage;

  @Deprecated(
    'Has no effect. For the colour shown while a thumbnail loads, use CometChatVideosBubbleStyle.placeholderColor. Will be removed in 7.0.0.',
  )
  final String? placeHolderImagePackageName;

  final CometChatVideoBubbleStyle? style;
  final Icon? playIcon;
  final Function()? onClick;

  VideoBubbleFactory({
    this.style,
    this.playIcon,
    this.onClick,
    this.placeHolderImage,
    this.placeHolderImagePackageName,
  });

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
    return CometChatVideoBubble(
      videoUrl: att.url ?? att.localPath,
      thumbnailUrl: att.thumbnailUrl,
      style: style,
      playIcon: playIcon,
      onClick: onClick,
    );
  }
}
