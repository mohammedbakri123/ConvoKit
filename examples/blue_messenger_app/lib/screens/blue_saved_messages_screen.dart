import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Floating-island saved / starred messages screen powered by
/// [ConvoKitSavedMessages].
class BlueSavedMessagesScreen extends StatefulWidget {
  const BlueSavedMessagesScreen({
    super.key,
    required this.backend,
    this.onMessageTap,
  });

  final BlueInMemoryBackend backend;
  final ValueChanged<ChatMessage>? onMessageTap;

  @override
  State<BlueSavedMessagesScreen> createState() =>
      _BlueSavedMessagesScreenState();
}

class _BlueSavedMessagesScreenState extends State<BlueSavedMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: const Text('Saved Messages'),
      ),
      body: FloatingIslandCard(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 18),
        radius: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ConvoKitSavedMessages(
            hideAppbar: true,
            initialMessages: widget.backend.savedMessages,
            onUnsave: (message) async {
              setState(() => widget.backend.unsaveMessage(message));
            },
            onItemTap: (message) {
              widget.onMessageTap?.call(message);
              Navigator.of(context).pop(message);
            },
            style: const ConvoKitSavedMessagesStyle(
              backgroundColor: BlueMessengerColors.islandSurface,
              appBarColor: BlueMessengerColors.islandSurface,
              iconColor: BlueMessengerColors.royalBlue,
              unsaveIconColor: BlueMessengerColors.deepBlue,
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
