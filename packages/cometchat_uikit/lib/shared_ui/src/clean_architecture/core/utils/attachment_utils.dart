import 'package:convokit/src/core/models/models.dart';
import 'package:flutter/widgets.dart';

import '../../../../l10n/translations.dart';
import '../constants/ui_kit_constants.dart';

/// Attachments partitioned by [AttachmentKind].
class CategorizedAttachments {
  final List<ChatAttachment> images;
  final List<ChatAttachment> videos;
  final List<ChatAttachment> audios;
  final List<ChatAttachment> files;

  const CategorizedAttachments({
    this.images = const [],
    this.videos = const [],
    this.audios = const [],
    this.files = const [],
  });

  List<ChatAttachment> get media => [...images, ...videos];
  List<ChatAttachment> get audio => audios;

  bool get isEmpty =>
      images.isEmpty && videos.isEmpty && audios.isEmpty && files.isEmpty;

  int get totalCount =>
      images.length + videos.length + audios.length + files.length;

  List<ChatAttachment> get all => [...images, ...videos, ...audios, ...files];
}

/// Utility helpers for [ChatAttachment] and [MediaMessage].
class AttachmentUtils {
  AttachmentUtils._();

  static const Set<String> _imageExts = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'svg',
  };
  static const Set<String> _videoExts = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v',
  };
  static const Set<String> _audioExts = {
    'mp3', 'wav', 'aac', 'm4a', 'ogg', 'opus', 'flac', 'amr',
  };

  /// Returns all attachments belonging to [message].
  static List<ChatAttachment> attachmentsOf(ChatMessage message) {
    return switch (message) {
      MediaMessage m => switch (m.metadata?['attachments']) {
        List<ChatAttachment> list => list,
        List list => list.whereType<ChatAttachment>().toList(),
        _ => [m.attachment],
      },
      TextMessage _ => const [],
      CustomMessage _ => const [],
    };
  }

  static bool hasMultipleAttachments(ChatMessage message) =>
      attachmentsOf(message).length > 1;

  static String extensionOf(ChatAttachment attachment) {
    final name = attachment.name ?? '';
    if (name.contains('.')) {
      return name.split('.').last.toLowerCase();
    }
    return '';
  }

  static bool isGif(ChatAttachment attachment) {
    final mime = (attachment.mimeType ?? '').toLowerCase();
    return mime == 'image/gif' || extensionOf(attachment) == 'gif';
  }

  static bool isImage(ChatAttachment attachment) {
    if (attachment.kind == AttachmentKind.image) return true;
    final mime = (attachment.mimeType ?? '').toLowerCase();
    return mime.startsWith('image/') || _imageExts.contains(extensionOf(attachment));
  }

  static bool isVideo(ChatAttachment attachment) {
    if (isAudio(attachment)) return false;
    if (attachment.kind == AttachmentKind.video) return true;
    final mime = (attachment.mimeType ?? '').toLowerCase();
    return mime.startsWith('video/') || _videoExts.contains(extensionOf(attachment));
  }

  static bool isAudio(ChatAttachment attachment) {
    if (attachment.kind == AttachmentKind.audio) return true;
    final mime = (attachment.mimeType ?? '').toLowerCase();
    return mime.startsWith('audio/') || _audioExts.contains(extensionOf(attachment));
  }

  static bool isVisualMedia(ChatAttachment attachment) =>
      isImage(attachment) || isVideo(attachment);

  static bool isFile(ChatAttachment attachment) =>
      !isImage(attachment) && !isVideo(attachment) && !isAudio(attachment);

  static bool isNonPreviewableFile(ChatAttachment attachment) =>
      isFile(attachment);

  static String deriveType(
    ChatAttachment attachment, [
    String? fallbackType,
  ]) {
    final mime = (attachment.mimeType ?? '').toLowerCase();
    final ext = extensionOf(attachment);
    if (ext == 'ogg' || mime.startsWith('audio/') || _audioExts.contains(ext)) {
      return MessageTypeConstants.audio;
    }
    if (mime.startsWith('image/') || _imageExts.contains(ext)) {
      return MessageTypeConstants.image;
    }
    if (mime.startsWith('video/') || _videoExts.contains(ext)) {
      return MessageTypeConstants.video;
    }
    if (fallbackType != null && fallbackType.isNotEmpty) {
      return fallbackType;
    }
    return switch (attachment.kind) {
      AttachmentKind.image => MessageTypeConstants.image,
      AttachmentKind.video => MessageTypeConstants.video,
      AttachmentKind.audio => MessageTypeConstants.audio,
      AttachmentKind.file => MessageTypeConstants.file,
    };
  }

  static bool isImageOf(ChatAttachment attachment, [String? fallbackType]) =>
      deriveType(attachment, fallbackType) == MessageTypeConstants.image;

  static bool isVideoOf(ChatAttachment attachment, [String? fallbackType]) =>
      deriveType(attachment, fallbackType) == MessageTypeConstants.video;

  static bool isAudioOf(ChatAttachment attachment, [String? fallbackType]) =>
      deriveType(attachment, fallbackType) == MessageTypeConstants.audio;

  static CategorizedAttachments categorize(List<ChatAttachment> attachments) {
    final images = <ChatAttachment>[];
    final videos = <ChatAttachment>[];
    final audios = <ChatAttachment>[];
    final files = <ChatAttachment>[];
    for (final a in attachments) {
      switch (a.kind) {
        case AttachmentKind.image:
          images.add(a);
        case AttachmentKind.video:
          videos.add(a);
        case AttachmentKind.audio:
          audios.add(a);
        case AttachmentKind.file:
          files.add(a);
      }
    }
    return CategorizedAttachments(
      images: images,
      videos: videos,
      audios: audios,
      files: files,
    );
  }

  static String singularSubtitleFor(String messageType, BuildContext context) {
    final t = Translations.of(context);
    switch (messageType) {
      case MessageTypeConstants.image:
        return t.messageImage;
      case MessageTypeConstants.video:
        return t.messageVideo;
      case MessageTypeConstants.audio:
        return t.messageAudio;
      case MessageTypeConstants.file:
        return t.messageFile;
      default:
        return t.messageFile;
    }
  }

  static String previewSubtitleFor(ChatMessage message, BuildContext context) {
    if (message is MediaMessage) {
      final caption = message.caption?.trim();
      if (caption != null && caption.isNotEmpty) return caption;
      final name = message.attachment.name?.trim();
      if (name != null && name.isNotEmpty) return name;
      return singularSubtitleFor(deriveType(message.attachment), context);
    }
    return Translations.of(context).messageFile;
  }

  static String previewLabel(ChatAttachment attachment) {
    if (attachment.name != null && attachment.name!.isNotEmpty) {
      return attachment.name!;
    }
    return switch (attachment.kind) {
      AttachmentKind.image => 'Image',
      AttachmentKind.video => 'Video',
      AttachmentKind.audio => 'Audio',
      AttachmentKind.file => 'File',
    };
  }
}
