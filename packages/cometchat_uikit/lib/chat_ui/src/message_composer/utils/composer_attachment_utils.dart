import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../shared_ui/cometchat_uikit_shared.dart';

/// Utility class for message composer attachment options.
/// These methods are only used by the composer.
class ComposerAttachmentUtils {
  static ConvoKitMessageComposerAction takePhotoOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: MessageTypeConstants.takePhoto,
      title: Translations.of(context).camera,
      icon: Icon(
        Icons.photo_camera,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        size: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction attachPhoto(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: MessageTypeConstants.attachPhoto,
      title: Translations.of(context).attachImage,
      icon: Icon(
        Icons.image,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        size: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction attachVideo(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: MessageTypeConstants.attachVideo,
      title: Translations.of(context).attachVideo,
      icon: Icon(
        Icons.videocam_rounded,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        size: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction audioAttachmentOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: MessageTypeConstants.audio,
      title: Translations.of(context).attachAudio,
      icon: Icon(
        Icons.play_circle,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        size: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction fileAttachmentOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: MessageTypeConstants.file,
      title: Translations.of(context).attachDocument,
      icon: Icon(
        Icons.description,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        size: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction collaborativeDocumentOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: ExtensionType.document,
      title: Translations.of(context).collaborativeDocument,
      icon: Image.asset(
        AssetConstants.collaborativeDocumentFilled,
        package: UIConstants.packageName,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        height: 24,
        width: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction collaborativeWhiteboardOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: ExtensionType.whiteboard,
      title: Translations.of(context).collaborativeWhiteboard,
      icon: Image.asset(
        AssetConstants.collaborativeWhiteBoardFilled,
        package: UIConstants.packageName,
        colorBlendMode: BlendMode.srcATop,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        height: 24,
        width: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static ConvoKitMessageComposerAction pollsOption(
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    CometChatAttachmentOptionSheetStyle? style,
  ) {
    return ConvoKitMessageComposerAction(
      id: ExtensionType.extensionPoll,
      title: Translations.of(context).poll,
      icon: Image.asset(
        AssetConstants.polls,
        package: UIConstants.packageName,
        color: style?.iconColor ?? colorPalette.iconHighlight,
        height: 24,
        width: 24,
      ),
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: TextStyle(
          color: style?.titleColor,
          fontSize: typography.heading4?.regular?.fontSize,
          fontWeight: typography.heading4?.regular?.fontWeight,
          fontFamily: typography.heading4?.regular?.fontFamily,
        ).merge(style?.titleTextStyle),
        backgroundColor: style?.backgroundColor,
        borderRadius: style?.borderRadius,
        border: style?.border,
        titleColor: style?.titleColor,
        iconColor: style?.iconColor,
      ),
    );
  }

  static List<ConvoKitMessageComposerAction> getAttachmentOptions(
    BuildContext context,
    Map<String, dynamic>? id,
    AdditionalConfigurations? additionalConfigurations,
  ) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final style = additionalConfigurations?.attachmentOptionSheetStyle;
    List<ConvoKitMessageComposerAction> actions = [];

    if (additionalConfigurations?.hideTakPhotoOption != true && !kIsWeb) {
      actions.add(takePhotoOption(context, colorPalette, typography, style));
    }
    if (additionalConfigurations?.hideImageAttachmentOption != true) {
      actions.add(attachPhoto(context, colorPalette, typography, style));
    }
    if (additionalConfigurations?.hideVideoAttachmentOption != true) {
      actions.add(attachVideo(context, colorPalette, typography, style));
    }
    if (additionalConfigurations?.hideAudioAttachmentOption != true) {
      actions.add(
        audioAttachmentOption(context, colorPalette, typography, style),
      );
    }
    if (additionalConfigurations?.hideFileAttachmentOption != true) {
      actions.add(
        fileAttachmentOption(context, colorPalette, typography, style),
      );
    }
    if (additionalConfigurations?.hideCollaborativeDocumentOption != true) {
      actions.add(
        collaborativeDocumentOption(context, colorPalette, typography, style),
      );
    }
    if (additionalConfigurations?.hideCollaborativeWhiteboardOption != true) {
      actions.add(
        collaborativeWhiteboardOption(context, colorPalette, typography, style),
      );
    }
    if (additionalConfigurations?.hidePollsOption != true) {
      actions.add(pollsOption(context, colorPalette, typography, style));
    }
    return actions;
  }

  static String getMessageTypeToSubtitle(
    String messageType,
    BuildContext context,
  ) {
    switch (messageType) {
      case MessageTypeConstants.text:
        return Translations.of(context).text;
      case MessageTypeConstants.image:
        return Translations.of(context).messageImage;
      case MessageTypeConstants.video:
        return Translations.of(context).messageVideo;
      case MessageTypeConstants.file:
        return Translations.of(context).messageFile;
      case MessageTypeConstants.audio:
        return Translations.of(context).messageAudio;
      case ExtensionType.extensionPoll:
        return Translations.of(context).poll;
      case ExtensionType.document:
        return Translations.of(context).collaborativeDocument;
      case ExtensionType.whiteboard:
        return Translations.of(context).collaborativeWhiteboard;
      case ExtensionType.sticker:
        return Translations.of(context).customMessageSticker;
      default:
        return messageType;
    }
  }
}
