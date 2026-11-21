import 'dart:async';

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import 'message_info_sheet.dart';

/// Threaded conversation view mounting [ConvoKitThreadedHeader],
/// full-bleed [ConvoKitMessageList] (threaded replies with bubble tails &
/// spring entry motion), and floating glass pill [ConvoKitMessageComposer].
class ThreadScreen extends StatelessWidget {
  const ThreadScreen({
    super.key,
    required this.conversationId,
    required this.parentMessage,
    this.user,
    this.group,
    this.initialReplyCount = 0,
  });

  static const double _composerClearance = 92.0;

  final String conversationId;
  final ChatMessage parentMessage;
  final ChatUser? user;
  final ChatGroup? group;
  final int initialReplyCount;

  String get _parentMessageId => parentMessage.id ?? parentMessage.localId;

  void _handleMessageTap(BuildContext context, ChatMessage message) {
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

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    final listStyle = ShowcaseTheme.messageListStyle(context);
    final bottomListClearance =
        MediaQuery.paddingOf(context).bottom + _composerClearance;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: listStyle.backgroundColor ?? palette.background3,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: palette.iconHighlight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thread',
          style: ShowcaseTypography.compactTitle.copyWith(
            color: palette.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(ShowcaseTokens.glassBorderWidth),
          child: Container(
            height: ShowcaseTokens.glassBorderWidth,
            color: palette.borderLight,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          ConvoKitThreadedHeader(
            parentMessage: parentMessage,
            user: user,
            group: group,
            initialReplyCount: initialReplyCount,
            style: ConvoKitThreadedHeaderStyle(
              bubbleContainerBackGroundColor: listStyle.backgroundColor,
              countContainerBackGroundColor: colorScheme.surfaceContainerLow,
              countTextColor: palette.textSecondary,
              outgoingMessageBubbleStyle: listStyle.outgoingMessageBubbleStyle,
              incomingMessageBubbleStyle: listStyle.incomingMessageBubbleStyle,
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: ConvoKitMessageList(
                    conversationId: conversationId,
                    user: user,
                    group: group,
                    parentMessageId: _parentMessageId,
                    hideReplies: false,
                    style: listStyle,
                    listPadding: EdgeInsets.fromLTRB(
                      ShowcaseTokens.spaceMd,
                      ShowcaseTokens.spaceSm,
                      ShowcaseTokens.spaceMd,
                      bottomListClearance,
                    ),
                    onMessageTap: (msg) => _handleMessageTap(context, msg),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ConvoKitMessageComposer(
                    conversationId: conversationId,
                    user: user,
                    group: group,
                    parentMessageId: _parentMessageId,
                    useInlineAudioRecorder: true,
                    enableRichTextFormatting: true,
                    messageComposerStyle: ShowcaseTheme.messageComposerStyle(
                      context,
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
}
