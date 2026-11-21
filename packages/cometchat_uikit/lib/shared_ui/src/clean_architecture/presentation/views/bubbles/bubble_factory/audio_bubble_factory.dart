import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../../../core/constants/enums.dart';
import '../../../theme/colors/cometchat_color_palette.dart';
import '../../../theme/typography/cometchat_typography.dart';
import '../../../theme/spacing/cometchat_spacing.dart';
import '../audio_bubble/cometchat_audio_player.dart';
import '../audio_bubble/cometchat_voice_note_bubble_style.dart';
import 'bubble_factory.dart';

/// Factory for creating audio message bubbles.
class AudioBubbleFactory extends BubbleFactory<MediaMessage> {
  final CometChatVoiceNoteBubbleStyle? style;
  final Icon? playIcon;
  final Icon? pauseIcon;

  AudioBubbleFactory({this.style, this.playIcon, this.pauseIcon});

  @override
  Widget build(
    BuildContext context,
    MediaMessage message,
    BubbleAlignment alignment, {
    ConvoKitColorPalette? colorPalette,
    ConvoKitTypography? typography,
    ConvoKitSpacing? spacing,
  }) {
    return CometChatAudioPlayer(
      audioUrl: message.attachment.url ?? message.attachment.localPath,
      title: message.attachment.name,
      style: style,
      playIcon: playIcon,
      pauseIcon: pauseIcon,
      alignment: alignment,
      id: int.tryParse(message.id ?? ''),
      colorPalette: colorPalette,
      typography: typography,
      spacing: spacing,
    );
  }
}
