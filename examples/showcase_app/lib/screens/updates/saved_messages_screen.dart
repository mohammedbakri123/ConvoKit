import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../backend/studio_backend.dart';
import '../../backend/studio_seed_data.dart';
import '../../theme/showcase_tokens.dart';
import '../chat/chat_screen.dart';

/// Screen mounting the library's [ConvoKitSavedMessages] widget backed by
/// the offline [StudioBackend] saved-messages collection.
class SavedMessagesScreen extends StatelessWidget {
  const SavedMessagesScreen({
    super.key,
    this.backend,
    this.initialMessages,
    this.onItemTap,
  });

  /// Optional [StudioBackend] used to load and unsave bookmarked messages.
  final StudioBackend? backend;

  /// Optional explicit initial messages list (overrides [backend] lookup).
  final List<ChatMessage>? initialMessages;

  /// Optional override invoked when a saved message row is tapped.
  final void Function(ChatMessage message)? onItemTap;

  Future<void> _openMessageConversation(
    BuildContext context,
    ChatMessage message,
  ) async {
    if (onItemTap != null) {
      onItemTap!(message);
      return;
    }
    final kit = ConvoKitScope.maybeOf(context);
    if (kit == null) return;
    final result = await kit.conversations.getConversation(
      message.conversationId,
    );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (conversation) {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(
                conversationId: conversation.id,
                user: conversation.peer,
                group: conversation.group,
              ),
            ),
          ),
        );
      },
      onFailure: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final messages =
        initialMessages ??
        backend?.messages.getSavedMessages() ??
        StudioSeedData.create().savedMessages;

    return SafeArea(
      top: false,
      child: ConvoKitSavedMessages(
        initialMessages: messages,
        title: 'Saved Messages',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
        backButton: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          constraints: const BoxConstraints(
            minWidth: ShowcaseTokens.minTouchTarget,
            minHeight: ShowcaseTokens.minTouchTarget,
          ),
          style: IconButton.styleFrom(
            minimumSize: ShowcaseTokens.minTouchTargetSize,
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const StadiumBorder(),
          ),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.primary,
          ),
        ),
        style: ConvoKitSavedMessagesStyle(
          backgroundColor: palette.background1 ?? colorScheme.surface,
          appBarColor: colorScheme.surfaceContainerLow,
          titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
            color: colorScheme.onSurface,
          ),
          itemTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
            color: colorScheme.onSurface,
          ),
          itemSubtitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          itemContextTextStyle: ShowcaseTypography.timestamp.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
          itemDateTextStyle: ShowcaseTypography.timestamp.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          iconColor: colorScheme.primary,
          unsaveIconColor: colorScheme.error,
          separatorColor: colorScheme.outlineVariant,
        ),
        onUnsave: (message) async {
          backend?.messages.toggleSaveMessage(message);
        },
        onItemTap: (message) {
          unawaited(_openMessageConversation(context, message));
        },
      ),
    );
  }
}
