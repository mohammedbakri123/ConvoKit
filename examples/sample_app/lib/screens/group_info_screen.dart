import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/add_members_screen.dart';
import 'package:sample_app/screens/banned_members_screen.dart';
import 'package:sample_app/screens/transfer_ownership_screen.dart';

/// Offline Group Info screen built on [ChatGroup], [ConvoKitGroupMembers],
/// and [ConvoKitScope].
class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.group});

  final ChatGroup group;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late ChatGroup _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  Future<void> _refreshGroup() async {
    final groupsRepo = ConvoKitScope.of(context).groups;
    if (groupsRepo == null) return;
    final res = await groupsRepo.getGroup(_group.id);
    if (!mounted) return;
    res.fold(
      onSuccess: (g) => setState(() => _group = g),
      onFailure: (_) {},
    );
  }

  Future<void> _leaveGroup() async {
    final groupsRepo = ConvoKitScope.of(context).groups;
    if (groupsRepo != null) {
      await groupsRepo.leaveGroup(_group.id);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _deleteGroup() {
    SampleAppBackend.instance.backend.deleteGroup(_group.id);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Group Info',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConvoKitAvatar(
              name: _group.name,
              image: _group.avatarUrl,
              height: 80,
              width: 80,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _group.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_group.description != null && _group.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _group.description!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text('View Members (${_group.memberCount})'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConvoKitGroupMembers(group: _group),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_outlined),
            title: const Text('Add Members'),
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMembersScreen(group: _group),
                ),
              );
              if (added == true) {
                await _refreshGroup();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Banned Members'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BannedMembersScreen(group: _group),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Transfer Ownership'),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TransferOwnershipScreen(group: _group),
                ),
              );
              if (changed == true) {
                await _refreshGroup();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: palette.error),
            title: Text('Leave Group', style: TextStyle(color: palette.error)),
            onTap: _leaveGroup,
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: palette.error),
            title: Text('Delete Group', style: TextStyle(color: palette.error)),
            onTap: _deleteGroup,
          ),
        ],
      ),
    );
  }
}
