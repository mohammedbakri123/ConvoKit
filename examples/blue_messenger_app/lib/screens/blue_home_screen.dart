import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';
import 'blue_chat_screen.dart';
import 'blue_extensions_screen.dart';
import 'blue_group_members_screen.dart';
import 'blue_saved_messages_screen.dart';
import 'blue_search_screen.dart';

/// Main Blue Messenger shell with a detached floating pill bottom navigation
/// bar (Chats, Contacts, Groups, Updates, Calls), floating search pill,
/// floating island cards, and library-only ConvoKit views.
class BlueHomeScreen extends StatefulWidget {
  const BlueHomeScreen({super.key, required this.backend});

  final BlueInMemoryBackend backend;

  @override
  State<BlueHomeScreen> createState() => _BlueHomeScreenState();
}

class _BlueHomeScreenState extends State<BlueHomeScreen> {
  static const List<String> _filters = ['All', 'Unread', 'Groups'];
  static const List<String> _tabTitles = [
    'Blue Messenger',
    'Contacts',
    'Groups',
    'Updates',
    'Calls',
  ];

  int _selectedTab = 0;
  String _selectedFilter = 'All';
  String _callMode = 'voice';
  DateTime? _scheduledSlot;

  void _openConversation(BuildContext context, ChatConversation conversation) {
    final kit = ConvoKitScope.of(context);
    if (conversation.unreadCount > 0) {
      unawaited(kit.conversations.markAsRead(conversation.id));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueChatScreen(
          backend: widget.backend,
          conversationId: conversation.id,
          user: conversation.peer,
          group: conversation.group,
        ),
      ),
    );
  }

  void _openUserChat(BuildContext context, ChatUser user) {
    final existing = widget.backend.getConversationFor(userId: user.id);
    final meId = ConvoKitScope.of(context).session.currentUser?.id ?? 'me';
    final conversationId = existing?.id ?? 'conv_${meId}_${user.id}';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueChatScreen(
          backend: widget.backend,
          conversationId: conversationId,
          user: user,
        ),
      ),
    );
  }

  void _openGroupChat(BuildContext context, ChatGroup group) {
    final existing = widget.backend.getConversationFor(groupId: group.id);
    final conversationId = existing?.id ?? 'conv_${group.id}';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueChatScreen(
          backend: widget.backend,
          conversationId: conversationId,
          group: group,
        ),
      ),
    );
  }

  void _openGroupMembers(BuildContext context, ChatGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueGroupMembersScreen(
          group: group,
          backend: widget.backend,
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueSearchScreen(
          onUserSelected: (user) => _openUserChat(context, user),
        ),
      ),
    );
  }

  void _openSavedMessages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueSavedMessagesScreen(backend: widget.backend),
      ),
    );
  }

  void _openExtensions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueExtensionsScreen(backend: widget.backend),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            for (final label in _filters) ...[
              ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedFilter == label
                        ? BlueMessengerColors.deepBlue
                        : BlueMessengerColors.textSecondary,
                  ),
                ),
                selected: _selectedFilter == label,
                showCheckmark: false,
                selectedColor: BlueMessengerColors.activeChipFill,
                backgroundColor: BlueMessengerColors.islandSurface,
                side: const BorderSide(color: BlueMessengerColors.islandBorder),
                shape: const StadiumBorder(),
                onSelected: (_) => setState(() => _selectedFilter = label),
              ),
              const SizedBox(width: 8),
            ],
            ActionChip(
              avatar: const Icon(
                Icons.bookmark_rounded,
                size: 16,
                color: BlueMessengerColors.deepBlue,
              ),
              label: const Text(
                'Saved',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BlueMessengerColors.deepBlue,
                ),
              ),
              backgroundColor: BlueMessengerColors.chipFill,
              side: const BorderSide(color: BlueMessengerColors.islandBorder),
              shape: const StadiumBorder(),
              onPressed: () => _openSavedMessages(context),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: CHATS (ConvoKitConversations inside floating island)
  Widget _buildChatsTab(BuildContext context) {
    return Column(
      children: [
        FloatingSearchPill(
          onTap: () => _openSearch(context),
          trailing: ConvoKitBadge(
            count: widget.backend.totalUnreadCount,
            style: const ConvoKitBadgeStyle(
              backgroundColor: BlueMessengerColors.royalBlue,
              textColor: Colors.white,
            ),
          ),
        ),
        _buildFilterRow(context),
        Expanded(
          child: FloatingIslandCard(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 96),
            radius: 28,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ConvoKitConversations(
                hideAppbar: true,
                usersStatusVisibility: true,
                receiptsVisibility: true,
                listPadding: const EdgeInsets.only(bottom: 96),
                leadingView: (_, conversation) {
                  final isOnline =
                      conversation.peer?.presence == UserPresence.online;
                  final isPrivateGroup =
                      conversation.group?.type == GroupType.private;
                  final name =
                      conversation.peer?.name ?? conversation.group?.name ?? '';
                  final avatarUrl = conversation.peer?.avatarUrl ??
                      conversation.group?.avatarUrl;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ConvoKitAvatar(
                        image: avatarUrl,
                        name: name,
                        width: 48,
                        height: 48,
                        style: const ConvoKitAvatarStyle(
                          backgroundColor: BlueMessengerColors.deepBlue,
                          placeHolderTextColor: Colors.white,
                        ),
                      ),
                      if (isOnline || isPrivateGroup)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: ConvoKitStatusIndicator(
                            height: 14,
                            width: 14,
                            style: ConvoKitStatusIndicatorStyle(
                              backgroundColor: BlueMessengerColors.royalBlue,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            backgroundImage: isPrivateGroup
                                ? const Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  );
                },
                readIcon: const Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: BlueMessengerColors.skyBlue,
                ),
                deliveredIcon: const Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: BlueMessengerColors.textSecondary,
                ),
                sentIcon: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: BlueMessengerColors.textSecondary,
                ),
                onItemTap: (conversation) =>
                    _openConversation(context, conversation),
                conversationsStyle: ConvoKitConversationsStyle(
                  backgroundColor: BlueMessengerColors.islandSurface,
                  avatarStyle: const ConvoKitAvatarStyle(
                    backgroundColor: BlueMessengerColors.deepBlue,
                    placeHolderTextColor: Colors.white,
                  ),
                  statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
                    backgroundColor: BlueMessengerColors.royalBlue,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  badgeStyle: const ConvoKitBadgeStyle(
                    backgroundColor: BlueMessengerColors.royalBlue,
                    textColor: Colors.white,
                    textStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  itemTitleTextColor: BlueMessengerColors.textPrimary,
                  itemSubtitleTextColor: BlueMessengerColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: CONTACTS (ConvoKitUsers inside floating island)
  Widget _buildContactsTab(BuildContext context) {
    return FloatingIslandCard(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 96),
      radius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ConvoKitUsers(
          hideAppbar: true,
          usersStatusVisibility: true,
          searchPlaceholder: 'Search contacts...',
          onItemTap: (ctx, user) => _openUserChat(ctx, user),
          usersStyle: ConvoKitUsersStyle(
            backgroundColor: BlueMessengerColors.islandSurface,
            searchBackgroundColor: BlueMessengerColors.chipFill,
            searchBorderRadius: BorderRadius.circular(24),
            searchIconColor: BlueMessengerColors.deepBlue,
            itemTitleTextColor: BlueMessengerColors.textPrimary,
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
    );
  }

  // TAB 2: GROUPS (ConvoKitGroups inside floating island)
  Widget _buildGroupsTab(BuildContext context) {
    return Column(
      children: [
        const FloatingIslandCard(
          margin: EdgeInsets.fromLTRB(14, 6, 14, 6),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          radius: 20,
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: BlueMessengerColors.deepBlue,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap a group to chat · Long-press to manage members & roles',
                  style: TextStyle(
                    fontSize: 12,
                    color: BlueMessengerColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FloatingIslandCard(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 96),
            radius: 28,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ConvoKitGroups(
                hideAppbar: true,
                groupTypeVisibility: true,
                searchPlaceholder: 'Search groups...',
                onItemTap: (ctx, group) => _openGroupChat(ctx, group),
                onItemLongPress: (ctx, group) => _openGroupMembers(ctx, group),
                groupsStyle: ConvoKitGroupsStyle(
                  backgroundColor: BlueMessengerColors.islandSurface,
                  searchBackgroundColor: BlueMessengerColors.chipFill,
                  searchBorderRadius: BorderRadius.circular(24),
                  searchIconColor: BlueMessengerColors.deepBlue,
                  itemTitleTextColor: BlueMessengerColors.textPrimary,
                  itemSubtitleTextColor: BlueMessengerColors.textSecondary,
                  avatarStyle: const ConvoKitAvatarStyle(
                    backgroundColor: BlueMessengerColors.royalBlue,
                    placeHolderTextColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: UPDATES / STATUS (Library cards + list items + Extensions launcher)
  Widget _buildUpdatesTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloatingIslandCard(
            child: CometChatCard(
              title: 'My Status',
              avatarName: widget.backend.currentUser.name,
              subtitleView: const Text(
                'Share a floating blue update with your contacts',
                style: TextStyle(color: BlueMessengerColors.textSecondary),
              ),
              bottomView: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: BlueMessengerColors.deepBlue,
                    ),
                    onPressed: () => _openExtensions(context),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Extensions & Bubbles'),
                  ),
                ],
              ),
            ),
          ),
          const SectionSeparator(
            text: 'Recent Status Updates',
            dividerColor: BlueMessengerColors.islandBorder,
            textStyle: TextStyle(
              color: BlueMessengerColors.deepBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final status in widget.backend.statusUpdates)
            FloatingIslandCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openUserChat(context, status.user),
                child: ConvoKitListItem(
                  avatarName: status.user.name,
                  title: status.user.name,
                  statusIndicatorColor: status.user.presence == UserPresence.online
                      ? BlueMessengerColors.royalBlue
                      : BlueMessengerColors.textTertiary,
                  avatarStyle: const ConvoKitAvatarStyle(
                    backgroundColor: BlueMessengerColors.deepBlue,
                    placeHolderTextColor: Colors.white,
                  ),
                  subtitleView: Text(
                    status.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BlueMessengerColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  tailView: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ConvoKitDate(
                        date: status.postedAt,
                        pattern: DateTimePattern.timeFormat,
                      ),
                      if (status.unseenCount > 0) ...[
                        const SizedBox(height: 4),
                        ConvoKitBadge(
                          count: status.unseenCount,
                          style: const ConvoKitBadgeStyle(
                            backgroundColor: BlueMessengerColors.royalBlue,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          FloatingIslandCard(
            child: ConvoKitCardView(
              cardJson:
                  '{"type":"card","title":"ConvoKit Channel Update","subtitle":"Blue Messenger Showcase","body":[{"type":"text","text":"All ConvoKit UI components are live and styled in cobalt blue."}]}',
              onAction: (_) => _openExtensions(context),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: CALLS (Library list items + receipts + call scheduler with SingleSelect & TimeSlotSelector)
  Widget _buildCallsTab(BuildContext context) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day, 9, 0);
    final dayEnd = DateTime(today.year, today.month, today.day, 17, 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionSeparator(
            text: 'Recent Calls',
            dividerColor: BlueMessengerColors.islandBorder,
            textStyle: TextStyle(
              color: BlueMessengerColors.deepBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final call in widget.backend.callRecords)
            FloatingIslandCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openUserChat(context, call.peer),
                child: ConvoKitListItem(
                  avatarName: call.peer.name,
                  title: call.peer.name,
                  avatarStyle: const ConvoKitAvatarStyle(
                    backgroundColor: BlueMessengerColors.deepBlue,
                    placeHolderTextColor: Colors.white,
                  ),
                  subtitleView: Row(
                    children: [
                      Icon(
                        call.isMissed
                            ? Icons.call_missed_rounded
                            : (call.isOutgoing
                                ? Icons.call_made_rounded
                                : Icons.call_received_rounded),
                        size: 15,
                        color: call.isMissed
                            ? BlueMessengerColors.errorRed
                            : BlueMessengerColors.royalBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        call.durationLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: call.isMissed
                              ? BlueMessengerColors.errorRed
                              : BlueMessengerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  tailView: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConvoKitDate(
                        date: call.timestamp,
                        pattern: DateTimePattern.timeFormat,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        call.isVideo
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        color: BlueMessengerColors.deepBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SectionSeparator(
            text: 'Schedule a Call',
            dividerColor: BlueMessengerColors.islandBorder,
            textStyle: TextStyle(
              color: BlueMessengerColors.deepBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          FloatingIslandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CometChatSingleSelect(
                  selectedValue: _callMode,
                  options: [
                    OptionElement(value: 'voice', label: 'Voice Call'),
                    OptionElement(value: 'video', label: 'Video Call'),
                  ],
                  optionBackground: BlueMessengerColors.chipFill,
                  selectedOptionBackground: BlueMessengerColors.deepBlue,
                  optionTextStyle: const TextStyle(
                    color: BlueMessengerColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedOptionsTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (value) => setState(() => _callMode = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: CometChatTimeSlotSelector(
                    selectedDay: today,
                    from: dayStart,
                    to: dayEnd,
                    duration: const Duration(minutes: 60),
                    onSelection: (slot) {
                      setState(() => _scheduledSlot = slot);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: BlueMessengerColors.deepBlue,
                          content: Text(
                            'Scheduled $_callMode call at ${slot.hour}:${slot.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_scheduledSlot != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Next scheduled $_callMode slot selected.',
                      style: const TextStyle(
                        color: BlueMessengerColors.royalBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChatsTab = _selectedTab == 0;
    final unread = widget.backend.totalUnreadCount;

    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BlueMessengerColors.deepBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(_tabTitles[_selectedTab]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Saved messages',
            icon: const Icon(
              Icons.bookmark_outline_rounded,
              color: BlueMessengerColors.deepBlue,
            ),
            onPressed: () => _openSavedMessages(context),
          ),
          IconButton(
            tooltip: 'Extensions & Bubbles',
            icon: const Icon(
              Icons.widgets_outlined,
              color: BlueMessengerColors.deepBlue,
            ),
            onPressed: () => _openExtensions(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: BlueMessengerColors.deepBlue,
            ),
            onSelected: (value) {
              if (value == 'saved') {
                _openSavedMessages(context);
              } else if (value == 'extensions') {
                _openExtensions(context);
              } else if (value == 'members') {
                _openGroupMembers(context, widget.backend.designGroup);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'saved',
                child: Text('Saved Messages'),
              ),
              PopupMenuItem(
                value: 'members',
                child: Text('Manage Group Members'),
              ),
              PopupMenuItem(
                value: 'extensions',
                child: Text('Extensions & Bubbles'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildChatsTab(context),
              _buildContactsTab(context),
              _buildGroupsTab(context),
              _buildUpdatesTab(context),
              _buildCallsTab(context),
            ],
          ),
          if (isChatsTab)
            Positioned(
              right: 20,
              bottom: 104,
              child: FloatingActionButton(
                key: const Key('blue_new_chat_fab'),
                tooltip: 'New chat',
                backgroundColor: BlueMessengerColors.deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  side: BorderSide.none,
                ),
                onPressed: () => _openSearch(context),
                child: const Icon(Icons.edit_rounded),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNavBar(
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              destinations: [
                FloatingNavDestination(
                  label: 'Chats',
                  icon: Icons.chat_bubble_outline_rounded,
                  selectedIcon: Icons.chat_bubble_rounded,
                  badgeCount: unread,
                ),
                const FloatingNavDestination(
                  label: 'Contacts',
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                ),
                const FloatingNavDestination(
                  label: 'Groups',
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups_rounded,
                ),
                const FloatingNavDestination(
                  label: 'Updates',
                  icon: Icons.donut_large_outlined,
                  selectedIcon: Icons.donut_large_rounded,
                ),
                const FloatingNavDestination(
                  label: 'Calls',
                  icon: Icons.call_outlined,
                  selectedIcon: Icons.call_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
