import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../shared_ui/convokit_uikit_shared.dart';
import '../../../../shared_ui/src/views/no_intrinsic_card_wrapper.dart';

/// Content view widget for developer card messages (category: "card").
///
/// Renders the raw card schema via the pure-Flutter [ConvoKitCardView]
/// fallback renderer. Mirrors the notification-feed card rendering pattern.
///
/// Handles:
/// - Normal render: getCard() → jsonEncode → ConvoKitCardView
/// - Null/empty card: shows getFallbackText() → getText() → "Card Message"
/// - Deleted message: handled at the template level (not here)
class CometChatCardBubble extends StatelessWidget {
  const CometChatCardBubble({
    super.key,
    required this.message,
    this.onCardAction,
    this.themeMode,
    this.themeOverride,
  });

  /// The [CardMessage] from the SDK (category: "card").
  final CustomMessage message;

  /// Callback when the user taps an action within the card.
  /// Fires alongside the [ConvoKitUIEvents.ccCardActionClicked] event.
  final void Function(CustomMessage message, ConvoKitCardActionEvent action)?
  onCardAction;

  /// Theme mode for the card renderer.
  /// If null, auto-detected from the current [Brightness].
  final ConvoKitCardThemeMode? themeMode;

  /// Theme override for the card renderer.
  final ConvoKitCardThemeOverride? themeOverride;

  @override
  Widget build(BuildContext context) {
    final rawCard = message.data['card'];
    final cardData = rawCard is Map<String, dynamic> ? rawCard : null;

    // If card payload is null/empty, show fallback text
    if (cardData == null || cardData.isEmpty) {
      return _buildFallbackView(context);
    }

    // Resolve theme mode from platform brightness if not provided
    final resolvedThemeMode = themeMode ?? _resolveThemeMode(context);

    final String cardJson = jsonEncode(cardData);

    final cardWidth = MediaQuery.sizeOf(context).width * 0.65;

    return NoIntrinsicCardWrapper(
      width: cardWidth,
      child: ConvoKitCardView(
        cardJson: cardJson,
        themeMode: resolvedThemeMode,
        themeOverride: themeOverride,
        onAction: (ConvoKitCardActionEvent action) {
          // Fire the callback prop (for apps using the bubble directly)
          onCardAction?.call(message, action);

          // Emit the UI event (for global subscription — covers nested agent cards too)
          ConvoKitUIEvents.ccCardActionClicked(message, action);
        },
      ),
    );
  }

  /// Fallback view when getCard() is null/empty.
  /// Shows getFallbackText() → getText() → "Card Message".
  Widget _buildFallbackView(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);

    final fallbackText =
        (message.data['fallbackText'] as String?) ??
        (message.data['text'] as String?) ??
        Translations.of(context).cardMessage;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        fallbackText,
        style: TextStyle(
          color: colorPalette.textPrimary,
          fontWeight: typography.body?.regular?.fontWeight,
          fontSize: typography.body?.regular?.fontSize,
          fontFamily: typography.body?.regular?.fontFamily,
        ),
      ),
    );
  }

  /// Resolves theme mode from the platform brightness.
  ConvoKitCardThemeMode _resolveThemeMode(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ConvoKitCardThemeMode.dark
        : ConvoKitCardThemeMode.light;
  }
}
