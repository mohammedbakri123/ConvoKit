import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import 'blue_group_members_screen.dart';
import 'blue_pinned_messages_screen.dart';
import 'blue_saved_messages_screen.dart';
import 'blue_search_screen.dart';
import 'blue_thread_screen.dart';

/// Blue Messenger chat screen composed exclusively from ConvoKit library
/// widgets (no custom `messageBuilder`, no hand-rolled bubbles):
/// - Floating [ConvoKitMessageHeader]
/// - [ConvoKitMessageList] (default library renderer + formatters)
/// - [ConvoKitMessagePreview] (when replying)
/// - Floating [ConvoKitMessageComposer] (inline audio recorder, rich text
///   toolbar, mentions, emoji/sticker/poll sheets)
/// - [CometchatMessageOptionSheet], [CometChatMessageInformation],
///   [CometChatReactionList], [MessageTranslationBubble], [CometChatCreatePoll],
///   [ConvoKitEmojiKeyboard], [CometChatStickerKeyboard].
class BlueChatScreen extends StatefulWidget {
  const BlueChatScreen({
    super.key,
    required this.backend,
    required this.conversationId,
    this.user,
    this.group,
  }) : assert(
         user != null || group != null,
         'Either user or group must be provided',
       );

  final BlueInMemoryBackend backend;
  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;

  @override
  State<BlueChatScreen> createState() => _BlueChatScreenState();
}

class _BlueChatScreenState extends State<BlueChatScreen> {
  ChatMessage? _replyingTo;
  late final ScrollController _scrollController;
  late final List<CometChatTextFormatter> _formatters;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _formatters = [
      CometChatMentionsFormatter(
        user: widget.user,
        group: widget.group,
        mentionAllLabel: 'Notify All',
      ),
      CometChatUrlFormatter(),
      CometChatEmailFormatter(),
      CometChatPhoneNumberFormatter(),
      MarkdownTextFormatter(),
    ];
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({int remainingPasses = 2}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if ((_scrollController.offset - maxExtent).abs() > 0.5) {
        _scrollController.jumpTo(maxExtent);
        if (remainingPasses > 1) {
          _scrollToBottom(remainingPasses: remainingPasses - 1);
        }
      }
    });
  }

  void _openPinnedMessages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BluePinnedMessagesScreen(
          backend: widget.backend,
          conversationId: widget.conversationId,
          user: widget.user,
          group: widget.group,
        ),
      ),
    );
  }

  void _openSavedMessages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueSavedMessagesScreen(backend: widget.backend),
      ),
    );
  }

  void _openGroupMembers() {
    final grp = widget.group;
    if (grp == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueGroupMembersScreen(
          group: grp,
          backend: widget.backend,
        ),
      ),
    );
  }

  void _openContactInfoSheet() {
    if (widget.group != null) {
      _openGroupMembers();
      return;
    }
    final peer = widget.user!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          padding: const EdgeInsets.all(16),
          child: CometChatCard(
            title: peer.name,
            avatarName: peer.name,
            subtitleView: Text(
              'Presence: ${peer.presence.name} · Blue Messenger',
              style: const TextStyle(color: BlueMessengerColors.textSecondary),
            ),
            bottomView: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openPinnedMessages();
                  },
                  icon: const Icon(Icons.push_pin_outlined),
                  label: const Text('Pinned'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openSavedMessages();
                  },
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  label: const Text('Saved'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openThread(ChatMessage message) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueThreadScreen(
          backend: widget.backend,
          conversationId: widget.conversationId,
          parentMessage: message,
          user: widget.user,
          group: widget.group,
        ),
      ),
    );
  }

  void _openMessageInfo(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 48, 14, 18),
        child: Container(
          height: 460,
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          clipBehavior: Clip.antiAlias,
          child: CometChatMessageInformation(
            message: message,
            title: 'Message Details',
            textFormatters: _formatters,
          ),
        ),
      ),
    );
  }

  void _openReactionListSheet(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          height: 320,
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          padding: const EdgeInsets.all(12),
          child: CometChatReactionList(
            message: message,
            emptyStateText: 'Tap a quick reaction on any message to add one.',
          ),
        ),
      ),
    );
  }

  void _openTranslationSheet(ChatMessage message) {
    final original = switch (message) {
      TextMessage t => t.text,
      MediaMessage m => m.caption ?? m.attachment.name ?? 'Media message',
      CustomMessage c => (c.data['text'] as String?) ?? c.kind,
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message Translation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BlueMessengerColors.deepBlue,
                ),
              ),
              const SizedBox(height: 12),
              MessageTranslationBubble(
                alignment: BubbleAlignment.left,
                translatedText: '[Translated · ES] $original',
                child: Text(
                  original,
                  style: const TextStyle(
                    color: BlueMessengerColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMessageOptionsSheet(ChatMessage message) {
    final isPinned = widget.backend.isPinned(message);
    final isSaved = widget.backend.isSaved(message);
    final kit = ConvoKitScope.of(context);

    showModalBottomSheet<ActionItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          child: Container(
            decoration: BlueIslandDecorations.floatingPill(radius: 28),
            clipBehavior: Clip.antiAlias,
            child: CometchatMessageOptionSheet(
              messageObject: message,
              favoriteReactions: const ['💙', '👍', '🔥', '🎉', '🙌', '✨'],
              onReactionTap: (msg, emoji) {
                if (emoji == null) return;
                widget.backend.toggleReaction(msg.localId, emoji);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: BlueMessengerColors.deepBlue,
                    content: Text('Reacted with $emoji'),
                  ),
                );
              },
              onAddReactionIconTap: (_) {
                Navigator.of(sheetContext).pop();
                _openEmojiSheet();
              },
              actionItems: [
                ActionItem(
                  id: 'reply',
                  title: 'Reply',
                  icon: const Icon(
                    Icons.reply_rounded,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    setState(() => _replyingTo = message);
                  },
                ),
                ActionItem(
                  id: 'thread',
                  title: 'Reply in Thread',
                  icon: const Icon(
                    Icons.forum_outlined,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    _openThread(message);
                  },
                ),
                ActionItem(
                  id: 'info',
                  title: 'Message Info',
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    _openMessageInfo(message);
                  },
                ),
                ActionItem(
                  id: 'reactions',
                  title: 'View Reactions',
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    _openReactionListSheet(message);
                  },
                ),
                ActionItem(
                  id: 'pin',
                  title: isPinned ? 'Unpin Message' : 'Pin Message',
                  icon: const Icon(
                    Icons.push_pin_outlined,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    widget.backend.togglePin(message);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: BlueMessengerColors.deepBlue,
                        content: Text(
                          isPinned ? 'Unpinned message' : 'Pinned message',
                        ),
                      ),
                    );
                  },
                ),
                ActionItem(
                  id: 'save',
                  title: isSaved ? 'Remove from Saved' : 'Save Message',
                  icon: const Icon(
                    Icons.bookmark_outline_rounded,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    widget.backend.toggleSave(message);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: BlueMessengerColors.deepBlue,
                        content: Text(
                          isSaved
                              ? 'Removed from Saved Messages'
                              : 'Saved to Saved Messages',
                        ),
                      ),
                    );
                  },
                ),
                ActionItem(
                  id: 'translate',
                  title: 'Translate',
                  icon: const Icon(
                    Icons.translate_rounded,
                    color: BlueMessengerColors.deepBlue,
                  ),
                  onItemClick: () {
                    _openTranslationSheet(message);
                  },
                ),
                ActionItem(
                  id: 'delete',
                  title: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: BlueMessengerColors.errorRed,
                  ),
                  onItemClick: () async {
                    await kit.messages.deleteMessage(
                      message.id ?? message.localId,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((selected) async {
      if (!mounted || selected == null) return;
      final callback = selected.onItemClick;
      if (callback is Future<void> Function()) {
        await callback();
      } else if (callback is void Function()) {
        callback();
      }
    });
  }

  void _openCreatePoll() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 48, 14, 18),
        child: Container(
          height: 520,
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          clipBehavior: Clip.antiAlias,
          child: CometChatCreatePoll(
            title: 'Create Blue Poll',
            user: widget.user?.id,
            group: widget.group?.id,
            userObject: widget.user,
            groupObject: widget.group,
          ),
        ),
      ),
    );
  }

  void _openEmojiSheet() {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          height: 360,
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          clipBehavior: Clip.antiAlias,
          child: ConvoKitEmojiKeyboard(colorPalette: palette),
        ),
      ),
    );
  }

  void _openStickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          height: 320,
          decoration: BlueIslandDecorations.floatingPill(radius: 28),
          clipBehavior: Clip.antiAlias,
          child: CometChatStickerKeyboard(
            onStickerTap: (sticker) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: BlueMessengerColors.deepBlue,
                  content: Text('Sticker selected (offline demo)'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _previewSubtitleFor(ChatMessage message) {
    return switch (message) {
      TextMessage t => t.text,
      MediaMessage m => m.caption ?? m.attachment.name ?? m.attachment.kind.name,
      CustomMessage c => (c.data['question'] as String?) ?? c.kind,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Floating-island Message Header
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BlueIslandDecorations.floatingPill(radius: 26),
              clipBehavior: Clip.antiAlias,
              child: ConvoKitMessageHeader(
                user: widget.user,
                group: widget.group,
                conversationId: widget.conversationId,
                showBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
                usersStatusVisibility: true,
                pinnedMessagesVisibility: true,
                onPinnedMessagesTap: _openPinnedMessages,
                onInfoTap: _openContactInfoSheet,
                onHeaderTap: _openContactInfoSheet,
                onSearchTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlueSearchScreen(
                        onUserSelected: (selected) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => BlueChatScreen(
                                backend: widget.backend,
                                conversationId:
                                    'conv_${widget.backend.currentUser.id}_${selected.id}',
                                user: selected,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                messageHeaderStyle: ConvoKitMessageHeaderStyle(
                  backgroundColor: BlueMessengerColors.islandSurface,
                  titleTextColor: BlueMessengerColors.textPrimary,
                  subtitleTextColor: BlueMessengerColors.textSecondary,
                  backIconColor: BlueMessengerColors.deepBlue,
                  backIcon: const Icon(
                    Icons.arrow_back_rounded,
                    color: BlueMessengerColors.deepBlue,
                  ),
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
                trailingView: (_, _, _) => [
                  IconButton(
                    tooltip: 'Pinned messages',
                    icon: const Icon(
                      Icons.push_pin_outlined,
                      size: 20,
                      color: BlueMessengerColors.deepBlue,
                    ),
                    onPressed: _openPinnedMessages,
                  ),
                  IconButton(
                    tooltip: 'Create poll',
                    icon: const Icon(
                      Icons.poll_outlined,
                      size: 20,
                      color: BlueMessengerColors.deepBlue,
                    ),
                    onPressed: _openCreatePoll,
                  ),
                  if (widget.group != null)
                    IconButton(
                      tooltip: 'Group members',
                      icon: const Icon(
                        Icons.group_outlined,
                        size: 20,
                        color: BlueMessengerColors.deepBlue,
                      ),
                      onPressed: _openGroupMembers,
                    ),
                ],
              ),
            ),

            // Library Message List (NO custom messageBuilder)
            Expanded(
              child: ConvoKitMessageList(
                conversationId: widget.conversationId,
                user: widget.user,
                group: widget.group,
                scrollController: _scrollController,
                onLoad: (_) => _scrollToBottom(),
                textFormatters: _formatters,
                onReplyMessage: (msg) => setState(() => _replyingTo = msg),
                onThreadRepliesClick: (msg, _, {template}) => _openThread(msg),
                onMessageTap: _openMessageInfo,
                onMessageLongPress: _openMessageOptionsSheet,
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
                style: const ConvoKitMessageListStyle(
                  backgroundColor: BlueMessengerColors.canvasBackground,
                  outgoingMessageBubbleStyle:
                      CometChatOutgoingMessageBubbleStyle(
                    backgroundColor: BlueMessengerColors.outgoingBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    textBubbleStyle: CometChatTextBubbleStyle(
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        color: BlueMessengerColors.textPrimary,
                      ),
                    ),
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: BlueMessengerColors.textSecondary,
                      ),
                    ),
                  ),
                  incomingMessageBubbleStyle:
                      CometChatIncomingMessageBubbleStyle(
                    backgroundColor: BlueMessengerColors.incomingBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    textBubbleStyle: CometChatTextBubbleStyle(
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        color: BlueMessengerColors.textPrimary,
                      ),
                    ),
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: BlueMessengerColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Optional floating reply preview
            if (_replyingTo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Container(
                  decoration: BlueIslandDecorations.island(radius: 20),
                  clipBehavior: Clip.antiAlias,
                  child: ConvoKitMessagePreview(
                    messagePreviewTitle: 'Replying to ${_replyingTo!.sender.name}',
                    messagePreviewSubtitle: _previewSubtitleFor(_replyingTo!),
                    message: _replyingTo,
                    onCloseClick: () => setState(() => _replyingTo = null),
                  ),
                ),
              ),

            // Floating-island Composer Bar
            Container(
              key: const Key('blue_floating_composer_island'),
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BlueIslandDecorations.floatingPill(radius: 28),
              clipBehavior: Clip.antiAlias,
              child: ConvoKitMessageComposer(
                conversationId: widget.conversationId,
                user: widget.user,
                group: widget.group,
                placeholderText: 'Message...',
                onSendButtonTap: (_, _, _) => _scrollToBottom(),
                useInlineAudioRecorder: true,
                enableRichTextFormatting: true,
                showRichTextFormattingOptions: true,
                textFormatters: _formatters,
                attachmentIcon: const Icon(
                  Icons.attach_file_rounded,
                  color: BlueMessengerColors.deepBlue,
                ),
                voiceRecordingIcon: const Icon(
                  Icons.mic_rounded,
                  color: BlueMessengerColors.deepBlue,
                ),
                sendButtonIcon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                auxiliaryButtonView: (_, _, _, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Emoji keyboard',
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        size: 20,
                        color: BlueMessengerColors.deepBlue,
                      ),
                      onPressed: _openEmojiSheet,
                    ),
                    IconButton(
                      tooltip: 'Stickers',
                      icon: const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 20,
                        color: BlueMessengerColors.deepBlue,
                      ),
                      onPressed: _openStickerSheet,
                    ),
                  ],
                ),
                messageComposerStyle: ConvoKitMessageComposerStyle(
                  backgroundColor: BlueMessengerColors.islandSurface,
                  filledColor: BlueMessengerColors.chipFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BlueMessengerColors.islandBorder),
                  textColor: BlueMessengerColors.textPrimary,
                  placeHolderTextColor: BlueMessengerColors.textSecondary,
                  sendButtonIconBackgroundColor: BlueMessengerColors.royalBlue,
                  sendButtonIconColor: Colors.white,
                  secondaryButtonIconColor: BlueMessengerColors.deepBlue,
                  auxiliaryButtonIconColor: BlueMessengerColors.deepBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
