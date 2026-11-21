import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_tokens.dart';

/// Modal bottom-sheet wrapper mounting the library's [ConvoKitPinnedMessages]
/// widget styled with concentric 28px sheet radii and semantic tonal surfaces.
class PinnedMessagesSheet extends StatelessWidget {
  const PinnedMessagesSheet({
    super.key,
    required this.conversationId,
    this.user,
    this.group,
    this.initialMessages = const <ChatMessage>[],
    this.onItemTap,
    this.onUnpin,
    this.title,
  });

  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;
  final List<ChatMessage> initialMessages;
  final void Function(ChatMessage message)? onItemTap;
  final Future<void> Function(ChatMessage message)? onUnpin;
  final String? title;

  /// Presents [PinnedMessagesSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String conversationId,
    ChatUser? user,
    ChatGroup? group,
    List<ChatMessage> initialMessages = const <ChatMessage>[],
    void Function(ChatMessage message)? onItemTap,
    Future<void> Function(ChatMessage message)? onUnpin,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.75,
        child: PinnedMessagesSheet(
          conversationId: conversationId,
          user: user,
          group: group,
          initialMessages: initialMessages,
          onItemTap: onItemTap,
          onUnpin: onUnpin,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    const sheetRadius = BorderRadius.vertical(
      top: Radius.circular(ShowcaseTokens.radiusSheet),
    );

    return ClipRRect(
      borderRadius: sheetRadius,
      child: ConvoKitPinnedMessages(
        conversationId: conversationId,
        user: user,
        group: group,
        initialMessages: initialMessages,
        onItemTap: onItemTap,
        onUnpin: onUnpin,
        title: title,
        style: ConvoKitPinnedMessagesStyle(
          backgroundColor: colorScheme.surfaceContainerLow,
          appBarColor: colorScheme.surfaceContainerLow,
          titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          itemTitleTextStyle: ShowcaseTypography.rowTitle.copyWith(
            color: palette.textPrimary,
          ),
          itemSubtitleTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
            color: palette.textSecondary,
          ),
          itemDateTextStyle: ShowcaseTypography.timestamp.copyWith(
            color: palette.textSecondary,
          ),
          iconColor: palette.iconHighlight,
          unpinIconColor: palette.error,
          separatorColor: palette.borderLight,
          borderRadius: sheetRadius,
        ),
      ),
    );
  }
}
