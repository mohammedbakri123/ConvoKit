import 'dart:convert';

import 'package:flutter/material.dart';

/// Theme mode for [ConvoKitCardView].
enum ConvoKitCardThemeMode { light, dark, auto }

/// Temporary alias preserving source compatibility for existing card callers
/// after removing `cometchat_cards`.
typedef CometChatCardThemeMode = ConvoKitCardThemeMode;

/// Paired light/dark hex color value for [ConvoKitCardThemeOverride].
class ConvoKitCardColorValue {
  final String light;
  final String dark;

  const ConvoKitCardColorValue({required this.light, required this.dark});
}

typedef CometChatCardColorValue = ConvoKitCardColorValue;

/// Theme color overrides for [ConvoKitCardView].
class ConvoKitCardThemeOverride {
  final ConvoKitCardColorValue? textColor;
  final ConvoKitCardColorValue? secondaryTextColor;
  final ConvoKitCardColorValue? backgroundColor;
  final ConvoKitCardColorValue? borderColor;
  final ConvoKitCardColorValue? dividerColor;
  final ConvoKitCardColorValue? buttonFilledBg;
  final ConvoKitCardColorValue? buttonFilledText;
  final ConvoKitCardColorValue? linkColor;

  const ConvoKitCardThemeOverride({
    this.textColor,
    this.secondaryTextColor,
    this.backgroundColor,
    this.borderColor,
    this.dividerColor,
    this.buttonFilledBg,
    this.buttonFilledText,
    this.linkColor,
  });
}

typedef CometChatCardThemeOverride = ConvoKitCardThemeOverride;

/// Sealed action hierarchy dispatched when a user taps a button inside
/// [ConvoKitCardView].
sealed class ConvoKitCardAction {
  final String type;

  const ConvoKitCardAction(this.type);

  factory ConvoKitCardAction.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'unknown';
    switch (type) {
      case 'openUrl':
        return ConvoKitCardOpenUrlAction(url: json['url']?.toString() ?? '');
      case 'copyToClipboard':
        return ConvoKitCardCopyToClipboardAction(
          value: json['value']?.toString() ?? '',
        );
      case 'downloadFile':
        return ConvoKitCardDownloadFileAction(
          url: json['url']?.toString() ?? '',
        );
      case 'sendMessage':
        return ConvoKitCardSendMessageAction(
          text: json['text']?.toString() ?? '',
          receiverUid: json['receiverUid']?.toString(),
          receiverGuid: json['receiverGuid']?.toString(),
        );
      case 'apiCall':
        return ConvoKitCardApiCallAction(
          url: json['url']?.toString() ?? '',
          method: json['method']?.toString() ?? 'POST',
        );
      case 'chatWithUser':
        return ConvoKitCardChatWithUserAction(
          uid: json['uid']?.toString() ?? '',
        );
      case 'chatWithGroup':
        return ConvoKitCardChatWithGroupAction(
          guid: json['guid']?.toString() ?? '',
        );
      case 'initiateCall':
        return const ConvoKitCardInitiateCallAction();
      case 'customCallback':
        return ConvoKitCardCustomCallbackAction(
          callbackId: json['callbackId']?.toString() ?? '',
          payload: json['payload'] is Map<String, dynamic>
              ? json['payload'] as Map<String, dynamic>
              : null,
        );
      default:
        return ConvoKitCardUnknownAction(type: type, raw: json);
    }
  }
}

final class ConvoKitCardOpenUrlAction extends ConvoKitCardAction {
  final String url;

  const ConvoKitCardOpenUrlAction({required this.url}) : super('openUrl');
}

final class ConvoKitCardCopyToClipboardAction extends ConvoKitCardAction {
  final String value;

  const ConvoKitCardCopyToClipboardAction({required this.value})
    : super('copyToClipboard');
}

final class ConvoKitCardDownloadFileAction extends ConvoKitCardAction {
  final String url;

  const ConvoKitCardDownloadFileAction({required this.url})
    : super('downloadFile');
}

final class ConvoKitCardSendMessageAction extends ConvoKitCardAction {
  final String text;
  final String? receiverUid;
  final String? receiverGuid;

  const ConvoKitCardSendMessageAction({
    required this.text,
    this.receiverUid,
    this.receiverGuid,
  }) : super('sendMessage');
}

final class ConvoKitCardApiCallAction extends ConvoKitCardAction {
  final String url;
  final String method;

  const ConvoKitCardApiCallAction({required this.url, this.method = 'POST'})
    : super('apiCall');
}

final class ConvoKitCardChatWithUserAction extends ConvoKitCardAction {
  final String uid;

  const ConvoKitCardChatWithUserAction({required this.uid})
    : super('chatWithUser');
}

final class ConvoKitCardChatWithGroupAction extends ConvoKitCardAction {
  final String guid;

  const ConvoKitCardChatWithGroupAction({required this.guid})
    : super('chatWithGroup');
}

final class ConvoKitCardInitiateCallAction extends ConvoKitCardAction {
  const ConvoKitCardInitiateCallAction() : super('initiateCall');
}

final class ConvoKitCardCustomCallbackAction extends ConvoKitCardAction {
  final String callbackId;
  final Map<String, dynamic>? payload;

  const ConvoKitCardCustomCallbackAction({
    required this.callbackId,
    this.payload,
  }) : super('customCallback');
}

final class ConvoKitCardUnknownAction extends ConvoKitCardAction {
  final Map<String, dynamic>? raw;

  const ConvoKitCardUnknownAction({String type = 'unknown', this.raw})
    : super(type);
}

typedef CometChatCardAction = ConvoKitCardAction;
typedef CometChatCardOpenUrlAction = ConvoKitCardOpenUrlAction;
typedef CometChatCardCopyToClipboardAction = ConvoKitCardCopyToClipboardAction;
typedef CometChatCardDownloadFileAction = ConvoKitCardDownloadFileAction;
typedef CometChatCardSendMessageAction = ConvoKitCardSendMessageAction;
typedef CometChatCardApiCallAction = ConvoKitCardApiCallAction;
typedef CometChatCardChatWithUserAction = ConvoKitCardChatWithUserAction;
typedef CometChatCardChatWithGroupAction = ConvoKitCardChatWithGroupAction;
typedef CometChatCardInitiateCallAction = ConvoKitCardInitiateCallAction;
typedef CometChatCardCustomCallbackAction = ConvoKitCardCustomCallbackAction;
typedef CometChatCardUnknownAction = ConvoKitCardUnknownAction;

/// Event emitted when a user activates an action element inside
/// [ConvoKitCardView].
class ConvoKitCardActionEvent {
  final String elementId;
  final ConvoKitCardAction action;

  const ConvoKitCardActionEvent({
    required this.elementId,
    required this.action,
  });
}

typedef CometChatCardActionEvent = ConvoKitCardActionEvent;

/// Pure-Flutter fallback card renderer replacing `CometChatCardView` from
/// `cometchat_cards`.
///
/// Parses the JSON card schema (`body`, `style`, `title`, `fallbackText`) and
/// renders text, divider, column/row containers, and interactive action buttons
/// without any external card SDK dependency.
class ConvoKitCardView extends StatelessWidget {
  final String cardJson;
  final ConvoKitCardThemeMode themeMode;
  final ConvoKitCardThemeOverride? themeOverride;
  final void Function(ConvoKitCardActionEvent action)? onAction;

  const ConvoKitCardView({
    super.key,
    required this.cardJson,
    this.themeMode = ConvoKitCardThemeMode.auto,
    this.themeOverride,
    this.onAction,
  });

  bool _isDark(BuildContext context) {
    switch (themeMode) {
      case ConvoKitCardThemeMode.dark:
        return true;
      case ConvoKitCardThemeMode.light:
        return false;
      case ConvoKitCardThemeMode.auto:
        return Theme.of(context).brightness == Brightness.dark;
    }
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '').trim();
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      return value != null ? Color(value) : null;
    }
    if (cleaned.length == 8) {
      final value = int.tryParse(cleaned, radix: 16);
      return value != null ? Color(value) : null;
    }
    return null;
  }

  Color? _resolveOverrideColor(ConvoKitCardColorValue? value, bool isDark) {
    if (value == null) return null;
    return _parseHexColor(isDark ? value.dark : value.light);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(cardJson);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      data = null;
    }

    final textColor =
        _resolveOverrideColor(themeOverride?.textColor, isDark) ??
        (isDark ? Colors.white : Colors.black87);
    final bgColor =
        _resolveOverrideColor(themeOverride?.backgroundColor, isDark) ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final borderColor =
        _resolveOverrideColor(themeOverride?.borderColor, isDark) ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final dividerColor =
        _resolveOverrideColor(themeOverride?.dividerColor, isDark) ??
        borderColor;
    final buttonBg =
        _resolveOverrideColor(themeOverride?.buttonFilledBg, isDark) ??
        Theme.of(context).colorScheme.primary;
    final buttonFg =
        _resolveOverrideColor(themeOverride?.buttonFilledText, isDark) ??
        Colors.white;

    if (data == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(cardJson, style: TextStyle(color: textColor)),
      );
    }

    final styleMap = data['style'] is Map<String, dynamic>
        ? data['style'] as Map<String, dynamic>
        : null;
    final borderRadius =
        (styleMap?['borderRadius'] as num?)?.toDouble() ?? 8.0;
    final borderWidth = (styleMap?['borderWidth'] as num?)?.toDouble() ?? 0.5;
    final resolvedBorderColor =
        _parseHexColor(styleMap?['borderColor']?.toString()) ?? borderColor;
    final resolvedBgColor =
        _parseHexColor(styleMap?['background']?.toString()) ?? bgColor;

    final body = data['body'];
    final children = <Widget>[];
    if (body is List) {
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          final widget = _buildElement(
            context,
            item,
            textColor: textColor,
            dividerColor: dividerColor,
            buttonBg: buttonBg,
            buttonFg: buttonFg,
          );
          if (widget != null) {
            children.add(widget);
          }
        }
      }
    }

    if (children.isEmpty) {
      final fallback =
          data['title']?.toString() ??
          data['fallbackText']?.toString() ??
          data['text']?.toString() ??
          'Card';
      children.add(Text(fallback, style: TextStyle(color: textColor)));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: resolvedBorderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget? _buildElement(
    BuildContext context,
    Map<String, dynamic> element, {
    required Color textColor,
    required Color dividerColor,
    required Color buttonBg,
    required Color buttonFg,
  }) {
    final type = element['type']?.toString();
    switch (type) {
      case 'text':
        final content = element['content']?.toString() ?? '';
        final variant = element['variant']?.toString();
        final isHeading =
            variant == 'heading1' ||
            variant == 'heading2' ||
            variant == 'heading3';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            content,
            style: TextStyle(
              color: textColor,
              fontSize: variant == 'heading1'
                  ? 18
                  : (variant == 'heading2' ? 16 : 14),
              fontWeight: isHeading ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      case 'divider':
        return Divider(color: dividerColor, height: 12);
      case 'button':
        final label = element['label']?.toString() ?? 'Action';
        final elementId = element['id']?.toString() ?? '';
        final rawAction = element['action'];
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBg,
              foregroundColor: buttonFg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              final actionMap = rawAction is Map<String, dynamic>
                  ? rawAction
                  : const <String, dynamic>{};
              onAction?.call(
                ConvoKitCardActionEvent(
                  elementId: elementId,
                  action: ConvoKitCardAction.fromJson(actionMap),
                ),
              );
            },
            child: Text(label),
          ),
        );
      case 'column':
        final items = element['items'] ?? element['children'];
        if (items is! List) return null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: items
              .whereType<Map<String, dynamic>>()
              .map(
                (child) => _buildElement(
                  context,
                  child,
                  textColor: textColor,
                  dividerColor: dividerColor,
                  buttonBg: buttonBg,
                  buttonFg: buttonFg,
                ),
              )
              .whereType<Widget>()
              .toList(),
        );
      case 'row':
        final items = element['items'] ?? element['children'];
        if (items is! List) return null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: items
              .whereType<Map<String, dynamic>>()
              .map(
                (child) => _buildElement(
                  context,
                  child,
                  textColor: textColor,
                  dividerColor: dividerColor,
                  buttonBg: buttonBg,
                  buttonFg: buttonFg,
                ),
              )
              .whereType<Widget>()
              .toList(),
        );
      default:
        final title =
            element['title']?.toString() ??
            element['content']?.toString() ??
            element['text']?.toString();
        if (title != null && title.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(title, style: TextStyle(color: textColor)),
          );
        }
        return null;
    }
  }
}
