import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';
import '../../widgets/floating_glass_tab_bar.dart';
import '../chat/chat_screen.dart';
import '../directory/people_groups_screen.dart';
import '../search/search_screen.dart';

/// Primary Chats tab mounting [ConvoKitConversations] full-bleed beneath
/// [CollapsingGlassHeader] and [FloatingGlassTabBar].
class ChatsTab extends StatefulWidget {
  const ChatsTab({
    super.key,
    this.onComposeTap,
    this.onSearchTap,
    this.onConversationTap,
    this.headerActions,
  });

  /// Callback for the compose/directory button in the glass header capsule.
  final VoidCallback? onComposeTap;

  /// Callback for tapping the read-only search bar in [ConvoKitConversations].
  final VoidCallback? onSearchTap;

  /// Optional override when a conversation item is tapped.
  final void Function(ChatConversation conversation)? onConversationTap;

  /// Optional extra glass header actions grouped after the compose button
  /// (e.g., the Light/Dark theme toggle from [ShowcaseShell]).
  final List<GlassHeaderAction>? headerActions;

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposeTap(BuildContext context) {
    if (widget.onComposeTap != null) {
      widget.onComposeTap!();
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PeopleGroupsScreen(),
        ),
      ),
    );
  }

  void _handleSearchTap(BuildContext context) {
    if (widget.onSearchTap != null) {
      widget.onSearchTap!();
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SearchScreen(),
        ),
      ),
    );
  }

  void _handleConversationTap(
    BuildContext context,
    ChatConversation conversation,
  ) {
    if (widget.onConversationTap != null) {
      widget.onConversationTap!(conversation);
      return;
    }
    if (conversation.unreadCount > 0) {
      final kit = ConvoKitScope.maybeOf(context);
      if (kit != null) {
        unawaited(kit.conversations.markAsRead(conversation.id));
      }
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            user: conversation.peer,
            group: conversation.group,
            onSearchTap: widget.onSearchTap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final topClearance = CollapsingGlassHeader.topClearance(context);
    final bottomClearance = FloatingGlassTabBar.bottomClearance(context);

    final actions = <GlassHeaderAction>[
      GlassHeaderAction(
        key: const Key('chats_compose_button'),
        icon: Icons.edit_square,
        tooltip: 'New chat',
        onPressed: () => _handleComposeTap(context),
      ),
      ...?widget.headerActions,
    ];

    return Scaffold(
      backgroundColor: palette.background1,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ConvoKitConversations(
              hideAppbar: true,
              hideSearch: false,
              searchReadOnly: true,
              scrollController: _scrollController,
              searchPadding: EdgeInsets.fromLTRB(
                ShowcaseTokens.spaceLg,
                topClearance,
                ShowcaseTokens.spaceLg,
                ShowcaseTokens.spaceSm,
              ),
              listPadding: EdgeInsets.only(
                top: ShowcaseTokens.spaceXs,
                bottom: bottomClearance,
              ),
              onSearchTap: () => _handleSearchTap(context),
              receiptsVisibility: true,
              usersStatusVisibility: true,
              conversationsStyle: ShowcaseTheme.conversationsStyle(context),
              onItemTap: (conversation) =>
                  _handleConversationTap(context, conversation),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollapsingGlassHeader(
              title: 'Chats',
              scrollController: _scrollController,
              actions: actions,
            ),
          ),
        ],
      ),
    );
  }
}
