import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/app_credentials_screen.dart';
import 'package:sample_app/screens/create_group_screen.dart';
import 'package:sample_app/screens/login_screen.dart';
import 'package:sample_app/screens/messages_screen.dart';

/// Offline split-pane Home screen for web and desktop viewports.
class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  int _selectedTab = 0;
  ChatUser? _selectedUser;
  ChatGroup? _selectedGroup;
  String? _selectedConversationId;

  void _selectConversation(ChatConversation conversation) {
    setState(() {
      _selectedUser = conversation.peer;
      _selectedGroup = conversation.group;
      _selectedConversationId = conversation.id;
    });
  }

  void _selectUser(ChatUser user) {
    setState(() {
      _selectedUser = user;
      _selectedGroup = null;
      _selectedConversationId = null;
    });
  }

  void _selectGroup(ChatGroup group) {
    setState(() {
      _selectedUser = null;
      _selectedGroup = group;
      _selectedConversationId = null;
    });
  }

  Future<void> _logout() async {
    await SampleAppBackend.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    final sidebarContent = switch (_selectedTab) {
      0 => ConvoKitConversations(
        onItemTap: _selectConversation,
        appBarOptions: (_) => [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings_outlined, color: palette.iconPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppCredentialsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: Icon(Icons.logout, color: palette.iconPrimary),
            onPressed: _logout,
          ),
        ],
      ),
      1 => ConvoKitUsers(showBackButton: false, onItemTap: (_, user) => _selectUser(user)),
      2 => ConvoKitGroups(
        showBackButton: false,
        onItemTap: (_, group) => _selectGroup(group),
        appBarOptions: (_) => [
          IconButton(
            tooltip: 'Create Group',
            icon: Icon(Icons.group_add_outlined, color: palette.iconPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      _ => CometChatSearch(onUserClicked: _selectUser),
    };

    return Scaffold(
      backgroundColor: palette.background1,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedTab,
            onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chats'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Groups'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          SizedBox(width: 340, child: sidebarContent),
          const VerticalDivider(width: 1),
          Expanded(
            child: (_selectedUser == null && _selectedGroup == null)
                ? Center(
                    child: Text(
                      'Select a conversation to start chatting offline',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                  )
                : MessagesScreen(
                    key: ValueKey(
                      _selectedConversationId ??
                          _selectedUser?.id ??
                          _selectedGroup?.id,
                    ),
                    user: _selectedUser,
                    group: _selectedGroup,
                    conversationId: _selectedConversationId,
                    showBackButton: false,
                  ),
          ),
        ],
      ),
    );
  }
}
