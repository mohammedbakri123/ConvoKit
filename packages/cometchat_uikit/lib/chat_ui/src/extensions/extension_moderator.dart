import '../../../convokit_uikit.dart';
import '../../../shared_ui/src/logging/cometchat_log.dart';

/// [ExtensionModerator] scans for extension payloads embedded inside a
/// [ChatMessage] (e.g. inside [CustomMessage.data]).
class ExtensionModerator {
  static Map<String, Map>? extensionCheck(ChatMessage message) {
    final Map<String, dynamic>? metadata =
        message is CustomMessage ? message.data : null;
    if (metadata == null) return null;

    final Map<String, Map<String, dynamic>> extensionMap = {};
    try {
      final injectedObject = metadata['@injected'];
      if (injectedObject is Map &&
          injectedObject.containsKey(ExtensionConstants.extensions)) {
        final extensionsObject = injectedObject[ExtensionConstants.extensions];
        if (extensionsObject is Map) {
          const keys = [
            ExtensionConstants.smartReply,
            ExtensionConstants.messageTranslation,
            ExtensionConstants.profanityFilter,
            ExtensionConstants.imageModeration,
            ExtensionConstants.thumbnailGeneration,
            ExtensionConstants.sentimentalAnalysis,
            ExtensionConstants.polls,
            ExtensionConstants.reactions,
            ExtensionConstants.whiteboard,
            ExtensionConstants.document,
            ExtensionConstants.dataMasking,
            ExtensionConstants.linkPreview,
          ];
          for (final key in keys) {
            final value = extensionsObject[key];
            if (value is Map) {
              extensionMap[key] = Map<String, dynamic>.from(value);
            }
          }
        }
      }
      return extensionMap;
    } catch (e, stack) {
      ccLog('$stack');
    }
    return null;
  }
}
