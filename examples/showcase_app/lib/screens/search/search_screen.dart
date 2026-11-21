import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../chat/chat_screen.dart';

/// User search screen mounting [CometChatSearch], reachable from the Chats
/// search bar and the Chat header search action.
///
/// Configures a full-pill search bar (`BorderRadius.circular(24)`) on
/// `surfaceContainerHigh`, clear inline helper and empty states, emphasized
/// section headers, `>=44x44` navigation/clear targets, and predictable back
/// navigation.
class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    this.user,
    this.group,
  });

  /// Optional active user context when launched from a direct [ChatScreen].
  final ChatUser? user;

  /// Optional active group context when launched from a group [ChatScreen].
  final ChatGroup? group;

  Future<String> _resolveDirectConversationId(
    BuildContext context,
    ChatUser clickedUser,
  ) async {
    final kit = ConvoKitScope.maybeOf(context);
    if (kit != null) {
      final result = await kit.conversations.listConversations(limit: 100);
      final existing = result.fold<String?>(
        onSuccess: (page) {
          for (final conv in page.items) {
            if (conv.peer?.id == clickedUser.id) {
              return conv.id;
            }
          }
          return null;
        },
        onFailure: (_) => null,
      );
      if (existing != null) return existing;
    }
    return 'conv_dm_${clickedUser.id}';
  }

  Future<void> _openDirectChat(
    BuildContext context,
    ChatUser clickedUser,
  ) async {
    final conversationId = await _resolveDirectConversationId(
      context,
      clickedUser,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          user: clickedUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contextLabel = user?.name ?? group?.name;

    return CometChatSearch(
      user: user,
      group: group,
      searchStyle: ShowcaseTheme.searchStyle(context),
      onBack: () => Navigator.of(context).maybePop(),
      searchBackIcon: SizedBox(
        width: ShowcaseTokens.minTouchTarget,
        height: ShowcaseTokens.minTouchTarget,
        child: Center(
          child: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.primary,
          ),
        ),
      ),
      searchClearIcon: SizedBox(
        width: ShowcaseTokens.minTouchTarget,
        height: ShowcaseTokens.minTouchTarget,
        child: Center(
          child: Icon(
            Icons.close_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      initialStateView: (ctx) => _SearchStatusState(
        key: const Key('search_initial_helper_state'),
        icon: Icons.person_search_rounded,
        title: contextLabel != null
            ? 'Search teammates from $contextLabel'
            : 'Find people in Atelier Studio',
        helperText:
            'Type a teammate name or handle above to jump straight into a direct chat.',
      ),
      emptyStateView: (ctx) => const _SearchStatusState(
        key: Key('search_empty_state'),
        icon: Icons.search_off_rounded,
        title: 'No matching teammates',
        helperText:
            'Check the spelling or try searching by first name (for example, Tariq, Claire, or Priya).',
      ),
      onUserClicked: (clickedUser) =>
          unawaited(_openDirectChat(context, clickedUser)),
    );
  }
}

class _SearchStatusState extends StatelessWidget {
  const _SearchStatusState({
    super.key,
    required this.icon,
    required this.title,
    required this.helperText,
  });

  final IconData icon;
  final String title;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ShowcaseTokens.space2Xl,
          vertical: ShowcaseTokens.space2Xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(
                    ShowcaseTokens.radiusNestedCard,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: ShowcaseTokens.spaceLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ShowcaseTypography.compactTitle.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: ShowcaseTokens.spaceSm),
            Text(
              helperText,
              textAlign: TextAlign.center,
              style: ShowcaseTypography.rowSubtitle.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
