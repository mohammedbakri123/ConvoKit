import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Floating-island pinned messages screen powered by [ConvoKitPinnedMessages].
class BluePinnedMessagesScreen extends StatefulWidget {
  const BluePinnedMessagesScreen({
    super.key,
    required this.backend,
    required this.conversationId,
    this.user,
    this.group,
  });

  final BlueInMemoryBackend backend;
  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;

  @override
  State<BluePinnedMessagesScreen> createState() =>
      _BluePinnedMessagesScreenState();
}

class _BluePinnedMessagesScreenState extends State<BluePinnedMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final pinned = widget.backend.pinnedMessagesFor(widget.conversationId);
    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: const Text('Pinned Messages'),
      ),
      body: FloatingIslandCard(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 18),
        radius: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ConvoKitPinnedMessages(
            conversationId: widget.conversationId,
            user: widget.user,
            group: widget.group,
            hideHeader: true,
            initialMessages: pinned,
            onUnpin: (message) async {
              setState(() => widget.backend.unpinMessage(message));
            },
            onItemTap: (message) {
              Navigator.of(context).pop(message);
            },
            style: const ConvoKitPinnedMessagesStyle(
              backgroundColor: BlueMessengerColors.islandSurface,
              appBarColor: BlueMessengerColors.islandSurface,
              iconColor: BlueMessengerColors.royalBlue,
              unpinIconColor: BlueMessengerColors.deepBlue,
              separatorColor: BlueMessengerColors.islandBorder,
              titleTextStyle: TextStyle(
                color: BlueMessengerColors.deepBlue,
                fontWeight: FontWeight.w700,
              ),
              itemTitleTextStyle: TextStyle(
                color: BlueMessengerColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              itemSubtitleTextStyle: TextStyle(
                color: BlueMessengerColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
