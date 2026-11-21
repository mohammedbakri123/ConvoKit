import 'package:convokit/src/core/models/models.dart';
import 'package:flutter/material.dart';

// Import all necessary dependencies
import '../constants/ui_kit_constants.dart';
import '../constants/asset_constants.dart';
import 'attachment_utils.dart';
import '../../data/models/cometchat_option.dart';
import '../../presentation/theme/theme/cometchat_theme_helper.dart';
import '../../presentation/theme/colors/cometchat_color_palette.dart';
import '../../presentation/formatters/mentions/cometchat_mentions_formatter.dart';
import '../../../../l10n/translations.dart';

///[ConversationUtils] is an Utility class that helps to
///the last message for any conversation and also
///provides the default action to execute on a conversation
class ConversationUtils {
  /// Get default options for a conversation
  ///
  /// **Deprecated**: This method previously required a controller parameter.
  /// Use [getDefaultOptionsWithCallback] instead to provide custom delete action.
  @Deprecated(
    'Use getDefaultOptionsWithCallback instead. '
    'See CONVERSATIONS_MIGRATION_GUIDE.md for migration instructions.',
  )
  static List<CometChatOption>? getDefaultOptions(
    ChatConversation conversation,
    dynamic controller,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
  ) {
    return getDefaultOptionsWithCallback(
      conversation: conversation,
      context: context,
      colorPalette: colorPalette,
      onDelete: null,
    );
  }

  /// Get default options for a conversation with custom delete callback
  ///
  /// This is the new recommended way to get default conversation options.
  /// Provide a custom [onDelete] callback to handle deletion.
  static List<CometChatOption>? getDefaultOptionsWithCallback({
    required ChatConversation conversation,
    required BuildContext context,
    required ConvoKitColorPalette colorPalette,
    required Function(ChatConversation)? onDelete,
  }) {
    return [
      CometChatOption(
        id: ConversationOptionConstants.delete,
        icon: AssetConstants.delete,
        packageName: UIConstants.packageName,
        backgroundColor: colorPalette.background1,
        iconTint: colorPalette.error,
        title: Translations.of(context).delete,
        onClick: () {
          if (onDelete != null) {
            onDelete(conversation);
          }
        },
      ),
    ];
  }

  static String _messageTypeOf(ChatMessage message) {
    return switch (message) {
      TextMessage _ => MessageTypeConstants.text,
      MediaMessage m => switch (m.attachment.kind) {
        AttachmentKind.image => MessageTypeConstants.image,
        AttachmentKind.video => MessageTypeConstants.video,
        AttachmentKind.audio => MessageTypeConstants.audio,
        AttachmentKind.file => MessageTypeConstants.file,
      },
      CustomMessage c => c.kind,
    };
  }

  static String _messageCategoryOf(ChatMessage message) {
    return switch (message) {
      TextMessage _ => MessageCategoryConstants.message,
      MediaMessage _ => MessageCategoryConstants.message,
      CustomMessage c => c.kind == MessageTypeConstants.card
          ? MessageCategoryConstants.card
          : MessageCategoryConstants.custom,
    };
  }

  static String getLastCustomMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    if (conversation.lastMessage is CustomMessage) {
      CustomMessage customMessage = conversation.lastMessage as CustomMessage;
      String messageType = customMessage.kind;
      String subtitle = '';

      switch (messageType) {
        case ExtensionType.sticker:
          subtitle = Translations.of(context).customMessageSticker;
          break;
        case ExtensionType.document:
          subtitle = Translations.of(context).customMessageDocument;
          break;
        case ExtensionType.whiteboard:
          subtitle = Translations.of(context).customMessageWhiteboard;
          break;
        case ExtensionType.extensionPoll:
          subtitle = Translations.of(context).customMessagePoll;
          break;
        case MessageTypeConstants.meeting:
          subtitle = _getGroupCallSubtitle(customMessage, context);
          break;
        default:
          subtitle = messageType;
          break;
      }
      return subtitle;
    } else {
      return "";
    }
  }

  /// Returns the subtitle text for a group call (meeting) message.
  /// If initiated by the logged-in user: "You've initiated a group call"
  /// If initiated by someone else: "{Name} has initiated a group call"
  static String _getGroupCallSubtitle(
    ChatMessage message,
    BuildContext context,
  ) {
    if (message.sender.id.isEmpty) {
      return Translations.of(context).youInitiatedGroupCall;
    } else {
      return "${message.sender.name} ${Translations.of(context).initiatedGroupCall}";
    }
  }

  /// Strips markdown syntax from text so conversation subtitles show plain text.
  /// Handles: bold, italic, strikethrough, inline code, code blocks,
  /// blockquotes, bullet lists, ordered lists, and headings.
  static String stripMarkdownSyntax(String text) {
    String result = text;
    // Code blocks (``` ... ```)
    result = result.replaceAll(RegExp(r'```[^\n]*\n?'), '');
    // Inline code (`code`)
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
    // Bold+italic (***text*** or ___text___)
    result = result.replaceAllMapped(RegExp(r'\*{3}(.+?)\*{3}'), (m) => m[1]!);
    result = result.replaceAllMapped(RegExp(r'_{3}(.+?)_{3}'), (m) => m[1]!);
    // Bold (**text** or __text__)
    result = result.replaceAllMapped(RegExp(r'\*{2}(.+?)\*{2}'), (m) => m[1]!);
    result = result.replaceAllMapped(RegExp(r'_{2}(.+?)_{2}'), (m) => m[1]!);
    // Italic (*text* or _text_)
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
    result = result.replaceAllMapped(
      RegExp(r'(?<=\s|^)_(.+?)_(?=\s|$)'),
      (m) => m[1]!,
    );
    // Strikethrough (~~text~~)
    result = result.replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m[1]!);
    // Blockquote (>> or > at line start)
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)>{1,2}\s?', multiLine: true),
      (m) => m[1]!,
    );
    // Headings (# ## ### etc.)
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)#{1,6}\s+', multiLine: true),
      (m) => m[1]!,
    );
    // Unordered list markers (- or * at line start)
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)[*\-]\s+', multiLine: true),
      (m) => m[1]!,
    );
    // Ordered list markers (1. 2. etc.)
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)\d+\.\s+', multiLine: true),
      (m) => m[1]!,
    );
    return result.trim();
  }

  static String getLastMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    ChatMessage message = conversation.lastMessage!;
    String messageType = _messageTypeOf(message);
    String subtitle;

    switch (messageType) {
      case MessageTypeConstants.text:
        subtitle = (message as TextMessage).text;
        final mentioned = CometChatMentionsFormatter.getMentionedUsersFor(message);
        if (mentioned.isNotEmpty) {
          subtitle = CometChatMentionsFormatter.getTextWithMentions(
            message.text,
            mentioned,
          );
        }
        // Strip markdown syntax so subtitle shows plain text
        subtitle = stripMarkdownSyntax(subtitle);
        // Truncate long URLs in the subtitle for better display
        subtitle = _truncateUrlsInText(subtitle);
        break;
      // image / video / file: caption → "{count} Images/…" → filename → label,
      // exactly matching the search list (AttachmentUtils.previewSubtitleFor).
      case MessageTypeConstants.image:
      case MessageTypeConstants.video:
      case MessageTypeConstants.file:
        subtitle = AttachmentUtils.previewSubtitleFor(message, context);
        break;
      case MessageTypeConstants.audio:
        // A voice note (single, un-captioned, recording filename) keeps the
        // friendly "Audio" label instead of showing a timestamped filename;
        // picked audio files use the search-style preview (caption / count).
        final isVoiceNote =
            message is MediaMessage &&
            (message.caption?.trim().isEmpty ?? true) &&
            AttachmentUtils.attachmentsOf(message).length == 1 &&
            message.attachment.name != null &&
            _isVoiceNoteName(message.attachment.name!);
        subtitle = isVoiceNote
            ? Translations.of(context).messageAudio
            : AttachmentUtils.previewSubtitleFor(message, context);
        break;
      default:
        subtitle = messageType;
    }
    return subtitle;
  }

  /// Heuristic: treat recordings produced by the composer as voice notes so
  /// the subtitle shows "Audio" rather than a timestamped filename.
  static bool _isVoiceNoteName(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.startsWith('audio-recording') ||
        lower.startsWith('voice-recording') ||
        lower.startsWith('recording') ||
        lower.startsWith('voicenote');
  }

  /// Truncates long URLs in text to make them more readable in conversation subtitles.
  ///
  /// URLs longer than [maxUrlLength] characters are shortened to show the domain
  /// and a truncated path (e.g., "https://example.com/very/long/path..." becomes
  /// "example.com/very/lo...").
  static String _truncateUrlsInText(String text, {int maxUrlLength = 30}) {
    // Regular expression to match URLs
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

    return text.replaceAllMapped(urlRegex, (match) {
      final url = match.group(0)!;
      if (url.length <= maxUrlLength) {
        return url;
      }

      // Try to parse the URL to extract domain
      try {
        final uri = Uri.parse(url);
        final domain = uri.host;
        final path = uri.path;

        // If just the domain fits, show domain + truncated path
        if (domain.length < maxUrlLength - 3) {
          final remainingLength =
              maxUrlLength - domain.length - 3; // -3 for "..."
          if (path.isNotEmpty && remainingLength > 0) {
            final truncatedPath = path.length > remainingLength
                ? '${path.substring(0, remainingLength)}...'
                : path;
            return '$domain$truncatedPath';
          }
          return '$domain...';
        }

        // Domain itself is too long, truncate it
        return '${domain.substring(0, maxUrlLength - 3)}...';
      } catch (e) {
        // If URL parsing fails, just truncate the raw URL
        return '${url.substring(0, maxUrlLength - 3)}...';
      }
    });
  }

  static String getLastInteractiveMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    ChatMessage message = conversation.lastMessage!;
    String messageType = _messageTypeOf(message);
    String subtitle;
    switch (messageType) {
      case MessageTypeConstants.form:
        subtitle = Translations.of(context).formMessage;
        break;
      case MessageTypeConstants.card:
        subtitle = Translations.of(context).cardMessage;
        break;
      case MessageTypeConstants.scheduler:
        subtitle = Translations.of(context).schedulerMessage;
        break;
      default:
        subtitle = messageType;
    }
    return subtitle;
  }

  static String getLastActionMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    ChatMessage message = conversation.lastMessage!;
    String subtitle;

    if (_messageTypeOf(message) == MessageTypeConstants.groupActions) {
      subtitle = message is TextMessage
          ? message.text
          : (message is CustomMessage
                ? (message.data['message'] as String? ?? '')
                : '');
    } else {
      subtitle = _messageTypeOf(message);
    }

    return subtitle;
  }

  static String getLastCallMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    final msg = conversation.lastMessage;
    if (msg == null) return '';
    return _messageTypeOf(msg);
  }

  static String getLastConversationMessage(
    ChatConversation conversation,
    BuildContext context,
  ) {
    String? messageCategory = conversation.lastMessage != null ? _messageCategoryOf(conversation.lastMessage!) : null;
    String subtitle;
    switch (messageCategory) {
      case MessageCategoryConstants.message:
        subtitle = getLastMessage(conversation, context);
        break;
      case MessageCategoryConstants.custom:
        subtitle = getLastCustomMessage(conversation, context);
        break;
      case MessageCategoryConstants.action:
        subtitle = getLastActionMessage(conversation, context);
        break;
      case MessageCategoryConstants.call:
        subtitle = getLastCallMessage(conversation, context);
        break;
      case MessageCategoryConstants.interactive:
        //TODO: appropriate implement interactive message subtitle
        // subtitle = getLastInteractiveMessage(conversation, context);
        subtitle = Translations.of(context).unsupportedMessageType;
        break;
      case MessageCategoryConstants.card:
        final msg = conversation.lastMessage;
        final cardText = msg is CustomMessage ? msg.data['text'] as String? : null;
        subtitle = (cardText != null && cardText.isNotEmpty)
            ? cardText
            : Translations.of(context).cardMessage;
        break;
      default:
        subtitle = conversation.lastMessage != null
            ? _messageTypeOf(conversation.lastMessage!)
            : '';
        break;
    }

    return subtitle;
  }

  // return icon widget to be shown in the prefix to the last message

  static Widget getLastConversationIcon(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    String? messageCategory = conversation.lastMessage != null ? _messageCategoryOf(conversation.lastMessage!) : null;
    Widget subtitle;
    switch (messageCategory) {
      case MessageCategoryConstants.message:
        subtitle = getLastMessageWidget(conversation, context, iconColor);
        break;
      case MessageCategoryConstants.custom:
        subtitle = getLastCustomWidget(conversation, context, iconColor);
        break;
      // case MessageCategoryConstants.action:
      //   subtitle = getLastActionMessage(conversation, context);
      //   break;
      case MessageCategoryConstants.call:
        subtitle = getLastCallWidget(conversation, context, iconColor);
        break;
      case MessageCategoryConstants.interactive:
        // subtitle = getLastInteractiveWidget(conversation, context);
        subtitle = Icon(Icons.block, color: iconColor, size: 16);
        break;
      default:
        subtitle = const SizedBox();
        break;
    }

    return subtitle;
  }

  static Widget getLastMessageWidget(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    ChatMessage message = conversation.lastMessage!;
    String messageType = _messageTypeOf(message);
    Widget subtitle;

    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);

    switch (messageType) {
      case MessageTypeConstants.text:
        subtitle = _getLastTextMessageWidget(conversation, context, iconColor);
        break;
      case MessageTypeConstants.image:
        subtitle = Icon(
          Icons.photo,
          color: iconColor ?? colorPalette.iconSecondary,
          size: 16,
        );
        break;
      case MessageTypeConstants.video:
        subtitle = Icon(
          Icons.videocam,
          color: iconColor ?? colorPalette.iconSecondary,
          size: 16,
        );
        break;
      case MessageTypeConstants.file:
        subtitle = _getFileIconWidget(message, iconColor, colorPalette);
        break;
      case MessageTypeConstants.audio:
        subtitle = _getAudioIconWidget(message, iconColor, colorPalette);
        break;
      default:
        subtitle = const SizedBox();
    }
    return subtitle;
  }

  /// Returns a file-type-specific icon based on the attachment's extension
  /// or MIME type. Falls back to the generic document icon when no
  /// attachment information is available.
  static Widget _getFileIconWidget(
    ChatMessage message,
    Color? iconColor,
    ConvoKitColorPalette colorPalette,
  ) {
    const size = 16.0;
    final color = iconColor ?? colorPalette.iconSecondary;

    IconData icon = Icons.description;

    if (message is MediaMessage) {
      final ext = AttachmentUtils.extensionOf(message.attachment).toLowerCase();
      final mime = (message.attachment.mimeType ?? '').toLowerCase();

      if (ext == 'pdf' || mime == 'application/pdf') {
        icon = Icons.picture_as_pdf;
      } else if (ext == 'doc' ||
          ext == 'docx' ||
          mime.contains('word') ||
          mime.contains('msword') ||
          mime.contains('officedocument.wordprocessing')) {
        icon = Icons.article;
      } else if (ext == 'xls' ||
          ext == 'xlsx' ||
          ext == 'csv' ||
          mime.contains('excel') ||
          mime.contains('spreadsheet') ||
          mime == 'text/csv') {
        icon = Icons.table_chart;
      } else if (ext == 'ppt' ||
          ext == 'pptx' ||
          mime.contains('powerpoint') ||
          mime.contains('presentation')) {
        icon = Icons.slideshow;
      } else if (ext == 'zip' ||
          ext == 'rar' ||
          ext == '7z' ||
          ext == 'tar' ||
          ext == 'gz' ||
          mime.contains('zip') ||
          mime.contains('compressed') ||
          mime.contains('x-tar') ||
          mime.contains('gzip')) {
        icon = Icons.folder_zip;
      } else if (ext == 'txt' ||
          ext == 'md' ||
          ext == 'log' ||
          mime.startsWith('text/')) {
        icon = Icons.text_snippet;
      } else if (mime.startsWith('image/')) {
        icon = Icons.photo;
      } else if (mime.startsWith('video/')) {
        icon = Icons.videocam;
      } else if (mime.startsWith('audio/')) {
        icon = Icons.audiotrack;
      }
    }

    return Icon(icon, color: color, size: size);
  }

  /// Returns an audio icon that distinguishes voice notes (mic) from music
  /// or other audio files (audiotrack), using the attachment's file name
  /// and extension as hints.
  static Widget _getAudioIconWidget(
    ChatMessage message,
    Color? iconColor,
    ConvoKitColorPalette colorPalette,
  ) {
    const size = 16.0;
    final color = iconColor ?? colorPalette.iconSecondary;

    IconData icon = Icons.mic;

    if (message is MediaMessage) {
      final fileName = message.attachment.name ?? '';
      final ext = AttachmentUtils.extensionOf(message.attachment).toLowerCase();
      const musicExtensions = {
        'mp3',
        'wav',
        'm4a',
        'aac',
        'ogg',
        'flac',
        'wma',
      };

      // Only switch to music icon when the attachment clearly isn't a
      // composer-generated voice recording.
      if (musicExtensions.contains(ext) && !_isVoiceNoteName(fileName)) {
        icon = Icons.audiotrack;
      }
    }

    return Icon(icon, color: color, size: size);
  }

  static Widget _getLastTextMessageWidget(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    ChatMessage message = conversation.lastMessage!;
    if (message is CustomMessage && _checkForLinks(message.data)) {
      return Icon(
        Icons.link,
        color: iconColor ?? colorPalette.iconSecondary,
        size: 16,
      );
    } else {
      return const SizedBox();
    }
  }

  static bool _checkForLinks(Map<String, dynamic> metadata) {
    // Check if the metadata contains the '@injected' key
    if (metadata.containsKey('@injected')) {
      final injected = metadata['@injected'];

      // Check if 'extensions' exists within 'injected'
      if (injected is Map && injected['extensions'] is Map) {
        final extensions = injected['extensions'] as Map;

        // Check if 'link-preview' exists within 'extensions'
        if (extensions['link-preview'] is Map) {
          final linkPreview = extensions['link-preview'] as Map;

          // Check if 'links' exists within 'link-preview'
          if (linkPreview['links'] is List) {
            final links = linkPreview['links'] as List;

            // Return true if the list of links is not empty
            return links.isNotEmpty;
          }
        }
      }
    }

    // Return false if no links were found
    return false;
  }

  static Widget getLastCustomWidget(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    ChatMessage message = conversation.lastMessage!;
    String messageType = _messageTypeOf(message);
    Widget subtitle;

    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);

    switch (messageType) {
      case ExtensionType.extensionPoll:
        subtitle = Icon(
          Icons.bar_chart,
          color: iconColor ?? colorPalette.iconSecondary,
          size: 16,
        );
        break;
      case ExtensionType.document:
        subtitle = Image.asset(
          AssetConstants.collaborativeDocumentFilled,
          package: UIConstants.packageName,
          color: iconColor ?? colorPalette.iconSecondary,
          height: 16,
          width: 16,
        );
        break;
      case ExtensionType.sticker:
        subtitle = Image.asset(
          AssetConstants.stickerFilled,
          package: UIConstants.packageName,
          color: iconColor ?? colorPalette.iconSecondary,
          height: 16,
          width: 16,
        );
        break;
      case ExtensionType.whiteboard:
        subtitle = Image.asset(
          AssetConstants.collaborativeWhiteBoardFilled,
          package: UIConstants.packageName,
          color: iconColor ?? colorPalette.iconSecondary,
          height: 16,
          width: 16,
        );
        break;
      case MessageTypeConstants.meeting:
        subtitle = Icon(
          Icons.videocam,
          color: iconColor ?? colorPalette.iconSecondary,
          size: 16,
        );
        break;
      default:
        subtitle = const SizedBox();
    }
    return subtitle;
  }

  static Widget getLastCallWidget(
    ChatConversation conversation,
    BuildContext context,
    Color? iconColor,
  ) {
    return const SizedBox();
  }
}
