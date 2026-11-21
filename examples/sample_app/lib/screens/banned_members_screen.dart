import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';

/// Offline Banned Members screen backed by [InMemoryChatBackend].
class BannedMembersScreen extends StatefulWidget {
  const BannedMembersScreen({super.key, required this.group});

  final ChatGroup group;

  @override
  State<BannedMembersScreen> createState() => _BannedMembersScreenState();
}

class _BannedMembersScreenState extends State<BannedMembersScreen> {
  List<ChatUser> _bannedMembers = [];

  @override
  void initState() {
    super.initState();
    _loadBanned();
  }

  void _loadBanned() {
    setState(() {
      _bannedMembers =
          SampleAppBackend.instance.backend.bannedMembersFor(widget.group.id);
    });
  }

  void _unban(ChatUser user) {
    SampleAppBackend.instance.backend.unbanGroupMember(
      widget.group.id,
      user.id,
    );
    _loadBanned();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Banned Members',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: _bannedMembers.isEmpty
          ? Center(
              child: Text(
                'No banned members',
                style: TextStyle(color: palette.textSecondary),
              ),
            )
          : ListView.builder(
              itemCount: _bannedMembers.length,
              itemBuilder: (context, index) {
                final member = _bannedMembers[index];
                return ListTile(
                  title: Text(member.name),
                  trailing: TextButton(
                    onPressed: () => _unban(member),
                    child: const Text('Unban'),
                  ),
                );
              },
            ),
    );
  }
}
