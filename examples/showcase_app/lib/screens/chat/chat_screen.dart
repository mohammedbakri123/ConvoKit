import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../backend/studio_message_repository.dart';
import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../directory/group_members_screen.dart';
import '../search/search_screen.dart';
import 'create_poll_sheet.dart';
import 'message_info_sheet.dart';
import 'pinned_messages_sheet.dart';
import 'thread_screen.dart';

/// Core conversation screen mounting a full-bleed [ConvoKitMessageList]
/// behind a frosted glass [ConvoKitMessageHeader] (`blurSigma: 24`) and a
/// floating glass pill [ConvoKitMessageComposer] (`blurSigma: 24`, radius `28`).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.user,
    this.group,
    this.onInfoTap,
    this.onSearchTap,
  }) : assert(
         user != null || group != null,
         'ChatScreen requires either user or group.',
       ),
       assert(
         user == null || group == null,
         'ChatScreen cannot receive both user and group.',
       );

  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;
  final VoidCallback? onInfoTap;
  final VoidCallback? onSearchTap;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const double _headerHeight = 65.0;
  static const double _composerClearance = 92.0;

  final ConvoKitMessageListController _messageListController =
      ConvoKitMessageListController();
  ChatMessage? _replyMessage;

  List<CometChatMessageTemplate> _buildLibraryTemplates(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    return <CometChatMessageTemplate>[
      CometChatMessageTemplate(
        category: MessageCategoryConstants.message,
        type: MessageTypeConstants.audio,
        contentView: (
          message,
          ctx,
          alignment, {
          AdditionalConfigurations? additionalConfigurations,
        }) {
          if (message is MediaMessage &&
              CometChatVoiceNoteBubble.isVoiceNote(message)) {
            return CometChatVoiceNoteBubble(
              audioUrl: message.attachment.url,
              title: message.attachment.name,
              muid: message.localId,
              metadata: message.metadata,
              alignment: alignment,
              colorPalette: palette,
            );
          }
          return null;
        },
      ),
    ];
  }

  void _openPinnedMessages() {
    final messagesRepo = ConvoKitScope.of(context).messages;
    final pinned = messagesRepo is StudioMessageRepository
        ? messagesRepo.getPinnedMessages(widget.conversationId)
        : const <ChatMessage>[];

    unawaited(
      PinnedMessagesSheet.show(
        context,
        conversationId: widget.conversationId,
        user: widget.user,
        group: widget.group,
        initialMessages: pinned,
        onItemTap: (message) {
          Navigator.of(context).pop();
          unawaited(
            _messageListController.jumpToMessage(
              message.id ?? message.localId,
            ),
          );
        },
        onUnpin: (message) async {
          if (messagesRepo is StudioMessageRepository) {
            messagesRepo.togglePinMessage(message);
          }
        },
      ),
    );
  }

  void _handleInfoTap() {
    if (widget.onInfoTap != null) {
      widget.onInfoTap!();
      return;
    }
    if (widget.group != null) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupMembersScreen(group: widget.group!),
          ),
        ),
      );
      return;
    }
    final peer = widget.user;
    if (peer != null) {
      _showContactInfoSheet(peer);
    }
  }

  void _showContactInfoSheet(ChatUser peer) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    final presenceLabel = switch (peer.presence) {
      UserPresence.online => 'Online',
      UserPresence.away => 'Away',
      UserPresence.offline => 'Offline',
      UserPresence.unknown => 'Offline',
    };

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ShowcaseTokens.radiusSheet),
          ),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            key: const Key('contact_info_sheet'),
            padding: const EdgeInsets.fromLTRB(
              ShowcaseTokens.spaceLg,
              ShowcaseTokens.spaceMd,
              ShowcaseTokens.spaceLg,
              ShowcaseTokens.spaceXl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExcludeSemantics(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(
                        bottom: ShowcaseTokens.spaceMd,
                      ),
                      decoration: BoxDecoration(
                        color: palette.borderDark,
                        borderRadius: BorderRadius.circular(
                          ShowcaseTokens.radiusFullPill,
                        ),
                      ),
                    ),
                  ),
                ),
                ConvoKitListItem(
                  id: peer.id,
                  avatarName: peer.name,
                  avatarURL: peer.avatarUrl,
                  avatarStyle: ShowcaseTheme.avatarStyle(sheetContext),
                  title: peer.name,
                  subtitleView: Text(
                    presenceLabel,
                    style: ShowcaseTypography.rowSubtitle.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  statusIndicatorColor: peer.presence == UserPresence.online
                      ? palette.primary
                      : null,
                  statusIndicatorStyle: ShowcaseTheme.statusIndicatorStyle(
                    sheetContext,
                    ringColor: colorScheme.surfaceContainerLow,
                  ),
                  hideSeparator: true,
                ),
                const SizedBox(height: ShowcaseTokens.spaceSm),
                ListTile(
                  key: const Key('contact_info_search_action'),
                  minTileHeight: ShowcaseTokens.minTouchTarget,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ShowcaseTokens.radiusNestedCard,
                    ),
                  ),
                  leading: Icon(
                    Icons.search_rounded,
                    color: palette.iconHighlight,
                  ),
                  title: Text(
                    'Search people',
                    style: ShowcaseTypography.rowTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleSearchTap();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSearchTap() {
    if (widget.onSearchTap != null) {
      widget.onSearchTap!();
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SearchScreen(
            user: widget.user,
            group: widget.group,
          ),
        ),
      ),
    );
  }

  void _openThread(
    ChatMessage message,
    BuildContext ctx, {
    CometChatMessageTemplate? template,
  }) {
    final messagesRepo = ConvoKitScope.of(context).messages;
    final parentId = message.id ?? message.localId;
    final replyCount = messagesRepo is StudioMessageRepository
        ? messagesRepo.getThreadReplies(widget.conversationId, parentId).length
        : 0;

    unawaited(
      Navigator.of(ctx).push(
        MaterialPageRoute<void>(
          builder: (_) => ThreadScreen(
            conversationId: widget.conversationId,
            parentMessage: message,
            user: widget.user,
            group: widget.group,
            initialReplyCount: replyCount,
          ),
        ),
      ),
    );
  }

  void _handleMessageTap(ChatMessage message) {
    if (message is MediaMessage && _isViewableMedia(message.attachment.kind)) {
      unawaited(
        CometChatMediaViewer.open(
          context,
          <ChatAttachment>[message.attachment],
        ),
      );
      return;
    }
    unawaited(MessageInfoSheet.show(context, message: message));
  }

  bool _isViewableMedia(AttachmentKind kind) {
    return kind == AttachmentKind.image ||
        kind == AttachmentKind.video ||
        kind == AttachmentKind.audio;
  }

  List<ConvoKitMessageComposerAction> _buildAttachmentOptions(
    BuildContext ctx,
    ChatUser? user,
    ChatGroup? group,
    Map<String, dynamic>? id,
  ) {
    final palette = ConvoKitThemeHelper.getColorPalette(ctx);
    return <ConvoKitMessageComposerAction>[
      ConvoKitMessageComposerAction(
        id: 'create_poll',
        title: 'Create Poll',
        icon: Icon(
          Icons.poll_outlined,
          color: palette.iconHighlight,
        ),
        onItemClick: (actionContext, actionUser, actionGroup) {
          unawaited(
            CreatePollSheet.show(
              actionContext,
              conversationId: widget.conversationId,
              user: actionUser ?? widget.user,
              group: actionGroup ?? widget.group,
              quotedMessage: _replyMessage,
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final listStyle = ShowcaseTheme.messageListStyle(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final topListClearance =
        mediaPadding.top + _headerHeight + ShowcaseTokens.spaceMd;
    final bottomListClearance =
        mediaPadding.bottom +
        _composerClearance +
        (_replyMessage != null ? 56.0 : 0.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: listStyle.backgroundColor,
      appBar: ConvoKitMessageHeader(
        user: widget.user,
        group: widget.group,
        conversationId: widget.conversationId,
        height: _headerHeight,
        showBackButton: true,
        pinnedMessagesVisibility: true,
        onPinnedMessagesTap: _openPinnedMessages,
        onHeaderTap: _handleInfoTap,
        onInfoTap: _handleInfoTap,
        onSearchTap: _handleSearchTap,
        messageHeaderStyle: ShowcaseTheme.messageHeaderStyle(context),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ConvoKitMessageList(
              conversationId: widget.conversationId,
              user: widget.user,
              group: widget.group,
              controller: _messageListController,
              style: listStyle,
              listPadding: EdgeInsets.fromLTRB(
                ShowcaseTokens.spaceMd,
                topListClearance,
                ShowcaseTokens.spaceMd,
                bottomListClearance,
              ),
              addTemplate: _buildLibraryTemplates(context),
              onThreadRepliesClick: _openThread,
              onMessageTap: _handleMessageTap,
              onReplyMessage: (message) {
                setState(() => _replyMessage = message);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ConvoKitMessageComposer(
              conversationId: widget.conversationId,
              user: widget.user,
              group: widget.group,
              replyMessage: _replyMessage,
              onClearReply: () {
                setState(() => _replyMessage = null);
              },
              useInlineAudioRecorder: true,
              enableRichTextFormatting: true,
              attachmentOptions: _buildAttachmentOptions,
              messageComposerStyle: ShowcaseTheme.messageComposerStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
