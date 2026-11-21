import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'join_protected_group_screen.dart';
import 'messages_screen.dart';

/// Offline Contacts / New Chat picker — two tabs: Users and Groups.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onUserTap(ChatUser user) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'messages'),
        builder: (_) => MessagesScreen(user: user),
      ),
    );
  }

  void _onGroupTap(ChatGroup group) {
    if (group.type == GroupType.passwordProtected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JoinProtectedGroupScreen(
            group: group,
            onGroupJoined: (joined) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'messages'),
                  builder: (_) => MessagesScreen(group: joined),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'messages'),
        builder: (_) => MessagesScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'New Chat',
          style: TextStyle(color: palette.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ConvoKitUsers(showBackButton: false, onItemTap: (_, user) => _onUserTap(user)),
          ConvoKitGroups(showBackButton: false, onItemTap: (_, group) => _onGroupTap(group)),
        ],
      ),
    );
  }
}
