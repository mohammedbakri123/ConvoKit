import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../theme/whatsapp_theme.dart';
import 'whatsapp_chat_screen.dart';

/// Modern 2024+ Android WhatsApp home screen with a white app bar, bold green
/// "WhatsApp" title, search bar, pill filter chips (All / Unread / Groups),
/// [ConvoKitConversations] for the chats list, a bottom navigation bar
/// (Chats / Updates / Communities / Calls), and a green new-chat FAB.
class WhatsAppHomeScreen extends StatefulWidget {
  const WhatsAppHomeScreen({super.key});

  @override
  State<WhatsAppHomeScreen> createState() => _WhatsAppHomeScreenState();
}

class _WhatsAppHomeScreenState extends State<WhatsAppHomeScreen> {
  static const List<String> _filters = <String>['All', 'Unread', 'Groups'];
  static const List<String> _tabTitles = <String>[
    'WhatsApp',
    'Updates',
    'Communities',
    'Calls',
  ];

  int _selectedTab = 0;
  String _selectedFilter = 'All';

  void _openConversation(BuildContext context, ChatConversation conversation) {
    final kit = ConvoKitScope.of(context);
    if (conversation.unreadCount > 0) {
      unawaited(kit.conversations.markAsRead(conversation.id));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WhatsAppChatScreen(
          conversationId: conversation.id,
          user: conversation.peer,
          group: conversation.group,
        ),
      ),
    );
  }

  void _openUserChat(BuildContext context, ChatUser user) {
    final meId = ConvoKitScope.of(context).session.currentUser?.id ?? 'me';
    final conversationId = 'conv_${meId}_${user.id}';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            WhatsAppChatScreen(conversationId: conversationId, user: user),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (searchContext) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: WhatsAppColors.textPrimary,
            title: const Text(
              'Search Contacts',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: WhatsAppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: CometChatSearch(
            onBack: () => Navigator.of(searchContext).pop(),
            onUserClicked: (user) {
              Navigator.of(searchContext).pop();
              _openUserChat(context, user);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: WhatsAppColors.chipFill,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('whatsapp_search_bar'),
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openSearch(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: WhatsAppColors.mutedIcon,
                ),
                SizedBox(width: 10),
                Text(
                  'Search...',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: WhatsAppColors.subtitleGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filters[index];
          final selected = _selectedFilter == label;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? WhatsAppColors.darkGreen
                    : WhatsAppColors.mutedIcon,
              ),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: WhatsAppColors.activeChipFill,
            backgroundColor: WhatsAppColors.chipFill,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            onSelected: (_) => setState(() => _selectedFilter = label),
          );
        },
      ),
    );
  }

  Widget _buildChatsTab(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        _buildFilterChips(),
        Expanded(
          child: ConvoKitConversations(
            hideAppbar: true,
            usersStatusVisibility: true,
            receiptsVisibility: true,
            listPadding: const EdgeInsets.only(bottom: 96),
            onItemTap: (conversation) =>
                _openConversation(context, conversation),
            conversationsStyle: ConvoKitConversationsStyle(
              backgroundColor: Colors.white,
              avatarStyle: const ConvoKitAvatarStyle(
                backgroundColor: WhatsAppColors.darkGreen,
                placeHolderTextColor: Colors.white,
              ),
              statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
                backgroundColor: WhatsAppColors.brandGreen,
                border: Border.all(color: Colors.white, width: 2),
              ),
              badgeStyle: const ConvoKitBadgeStyle(
                backgroundColor: WhatsAppColors.brandGreen,
                textColor: Colors.white,
                textStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              itemTitleTextColor: WhatsAppColors.textPrimary,
              itemSubtitleTextColor: WhatsAppColors.subtitleGrey,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChatsTab = _selectedTab == 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _tabTitles[_selectedTab],
          style: TextStyle(
            fontFamily: 'Roboto',
            color: isChatsTab
                ? WhatsAppColors.darkGreen
                : WhatsAppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Camera',
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: WhatsAppColors.textPrimary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera (offline demo)')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: WhatsAppColors.textPrimary,
            ),
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value (offline demo)')),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'New group', child: Text('New group')),
              PopupMenuItem(
                value: 'Starred messages',
                child: Text('Starred messages'),
              ),
              PopupMenuItem(value: 'Settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildChatsTab(context),
          const _PlaceholderTab(
            icon: Icons.donut_large_rounded,
            title: 'Updates',
            subtitle: 'Status updates and channels will appear here.',
          ),
          const _PlaceholderTab(
            icon: Icons.groups_rounded,
            title: 'Communities',
            subtitle: 'Stay connected with your communities here.',
          ),
          const _PlaceholderTab(
            icon: Icons.call_rounded,
            title: 'Calls',
            subtitle: 'Your recent voice and video calls will appear here.',
          ),
        ],
      ),
      floatingActionButton: isChatsTab
          ? FloatingActionButton(
              key: const Key('whatsapp_new_chat_fab'),
              tooltip: 'New chat',
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide.none,
              ),
              onPressed: () => _openSearch(context),
              child: const Icon(Icons.add_comment_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Communities',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded),
            label: 'Calls',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: WhatsAppColors.activeChipFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: WhatsAppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WhatsAppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: WhatsAppColors.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
