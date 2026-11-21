import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';

/// Offline User Info screen built on [ChatUser] and [ConvoKitScope].
class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key, required this.user});

  final ChatUser user;

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late ChatUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _toggleBlock() {
    final updated = SampleAppBackend.instance.backend.setUserBlocked(
      _user.id,
      blocked: !_user.isBlocked,
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  Future<void> _deleteConversation() async {
    final conv = SampleAppBackend.instance.backend.getConversationFor(
      userId: _user.id,
    );
    if (conv != null) {
      await ConvoKitScope.of(context).conversations.deleteConversation(conv.id);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'User Info',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConvoKitAvatar(
              name: _user.name,
              image: _user.avatarUrl,
              height: 80,
              width: 80,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user.presence.name,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(
              _user.isBlocked ? Icons.lock_open : Icons.block,
              color: palette.error,
            ),
            title: Text(
              _user.isBlocked ? 'Unblock User' : 'Block User',
              style: TextStyle(color: palette.error),
            ),
            onTap: _toggleBlock,
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: palette.error),
            title: Text(
              'Delete Conversation',
              style: TextStyle(color: palette.error),
            ),
            onTap: _deleteConversation,
          ),
        ],
      ),
    );
  }
}
