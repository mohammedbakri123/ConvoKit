import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/app_credentials_screen.dart';
import 'package:sample_app/screens/create_group_screen.dart';
import 'package:sample_app/screens/login_screen.dart';
import 'package:sample_app/screens/messages_screen.dart';

/// Offline Home screen with Chats, Users, Groups, Search, and Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _openConversation(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(
          user: conversation.peer,
          group: conversation.group,
          conversationId: conversation.id,
        ),
      ),
    );
  }

  void _openUserChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(user: user),
      ),
    );
  }

  void _openGroupChat(ChatGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(group: group),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Search')),
          body: CometChatSearch(
            onBack: () => Navigator.pop(context),
            onUserClicked: _openUserChat,
          ),
        ),
      ),
    );
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

  Widget _buildMenuButton(ConvoKitColorPalette palette) {
    final user = ConvoKitScope.of(context).session.currentUser;
    return PopupMenuButton<String>(
      icon: ConvoKitAvatar(
        name: user?.name ?? 'User',
        image: user?.avatarUrl,
        height: 32,
        width: 32,
      ),
      onSelected: (value) {
        switch (value) {
          case 'search':
            _openSearch();
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppCredentialsScreen()),
            );
          case 'logout':
            _logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user?.name ?? 'Signed Out'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'search', child: Text('Search Users')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuItem(value: 'logout', child: Text('Log Out')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    final pages = <Widget>[
      ConvoKitConversations(
        onItemTap: _openConversation,
        textFormatters: [
          CometChatMentionsFormatter(),
          MarkdownTextFormatter(),
          CometChatUrlFormatter(),
          CometChatPhoneNumberFormatter(),
          CometChatEmailFormatter(),
        ],
        appBarOptions: (_) => [
          IconButton(
            tooltip: 'Search',
            icon: Icon(Icons.search, color: palette.iconPrimary),
            onPressed: _openSearch,
          ),
          _buildMenuButton(palette),
        ],
      ),
      ConvoKitUsers(
        showBackButton: false,
        onItemTap: (_, user) => _openUserChat(user),
      ),
      ConvoKitGroups(
        showBackButton: false,
        onItemTap: (_, group) => _openGroupChat(group),
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
    ];

    return Scaffold(
      backgroundColor: palette.background1,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}
