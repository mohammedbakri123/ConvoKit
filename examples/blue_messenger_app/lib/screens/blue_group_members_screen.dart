import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Floating-island group members screen powered by [ConvoKitGroupMembers] and
/// [ConvoKitChangeScope] (opened when tapping any member).
class BlueGroupMembersScreen extends StatefulWidget {
  const BlueGroupMembersScreen({
    super.key,
    required this.group,
    required this.backend,
  });

  final ChatGroup group;
  final BlueInMemoryBackend backend;

  @override
  State<BlueGroupMembersScreen> createState() => _BlueGroupMembersScreenState();
}

class _BlueGroupMembersScreenState extends State<BlueGroupMembersScreen> {
  void _openChangeScopeSheet(BuildContext context, ChatMember member) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          child: Container(
            decoration: BlueIslandDecorations.floatingPill(radius: 28),
            padding: const EdgeInsets.all(16),
            child: ConvoKitChangeScope(
              group: widget.group,
              member: member,
              onSave: (group, target, newScope, oldScope) async {
                final mappedRole = switch (newScope.toLowerCase()) {
                  'admin' => GroupRole.admin,
                  'moderator' => GroupRole.admin,
                  _ => GroupRole.member,
                };
                widget.backend.updateMemberRole(
                  group.id,
                  target.user.id,
                  mappedRole,
                );
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      backgroundColor: BlueMessengerColors.deepBlue,
                      content: Text(
                        'Updated ${target.user.name} role to $newScope',
                      ),
                    ),
                  );
                  setState(() {});
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: Text('${widget.group.name} Members'),
      ),
      body: Column(
        children: [
          FloatingIslandCard(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            padding: const EdgeInsets.all(14),
            child: CometChatQuickView(
              title: widget.group.name,
              subtitle:
                  '${widget.group.description ?? 'Group chat'} · Tap any member to change scope',
            ),
          ),
          Expanded(
            child: FloatingIslandCard(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 16),
              radius: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ConvoKitGroupMembers(
                  group: widget.group,
                  hideAppbar: true,
                  usersStatusVisibility: true,
                  onItemTap: (member) =>
                      _openChangeScopeSheet(context, member),
                  style: ConvoKitGroupMembersStyle(
                    backgroundColor: BlueMessengerColors.islandSurface,
                    searchBackground: BlueMessengerColors.chipFill,
                    searchBorderRadius: BorderRadius.circular(24),
                    searchIconColor: BlueMessengerColors.deepBlue,
                    onlineStatusColor: BlueMessengerColors.royalBlue,
                    avatarStyle: const ConvoKitAvatarStyle(
                      backgroundColor: BlueMessengerColors.deepBlue,
                      placeHolderTextColor: Colors.white,
                    ),
                    statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
                      backgroundColor: BlueMessengerColors.royalBlue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
