import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../theme/whatsapp_theme.dart';

/// Modern WhatsApp chat screen composed exclusively from ConvoKit library
/// widgets: [ConvoKitMessageHeader], [ConvoKitMessageList] (default row
/// builder), and [ConvoKitMessageComposer].
class WhatsAppChatScreen extends StatelessWidget {
  const WhatsAppChatScreen({
    super.key,
    required this.conversationId,
    this.user,
    this.group,
  }) : assert(
         user != null || group != null,
         'Either user or group must be provided',
       );

  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WhatsAppColors.chatBackground,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          color: Colors.white,
          child: ConvoKitMessageHeader(
            user: user,
            group: group,
            conversationId: conversationId,
            showBackButton: true,
            onBack: () => Navigator.of(context).maybePop(),
            usersStatusVisibility: true,
            messageHeaderStyle: ConvoKitMessageHeaderStyle(
              backgroundColor: Colors.white,
              titleTextColor: WhatsAppColors.textPrimary,
              subtitleTextColor: WhatsAppColors.subtitleGrey,
              backIconColor: WhatsAppColors.textPrimary,
              backIcon: const Icon(
                Icons.arrow_back,
                color: WhatsAppColors.textPrimary,
              ),
              onlineStatusColor: WhatsAppColors.brandGreen,
              avatarStyle: const ConvoKitAvatarStyle(
                backgroundColor: WhatsAppColors.darkGreen,
                placeHolderTextColor: Colors.white,
              ),
              statusIndicatorStyle: ConvoKitStatusIndicatorStyle(
                backgroundColor: WhatsAppColors.brandGreen,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            trailingView: (_, _, _) => [
              IconButton(
                tooltip: 'Video call',
                icon: const Icon(
                  Icons.videocam_outlined,
                  color: WhatsAppColors.textPrimary,
                ),
                onPressed: () {},
              ),
              IconButton(
                tooltip: 'Voice call',
                icon: const Icon(
                  Icons.call_outlined,
                  color: WhatsAppColors.textPrimary,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ConvoKitMessageList(
              conversationId: conversationId,
              user: user,
              group: group,
              readIcon: const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: WhatsAppColors.readTickBlue,
              ),
              deliveredIcon: const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: WhatsAppColors.subtitleGrey,
              ),
              sentIcon: const Icon(
                Icons.check_rounded,
                size: 16,
                color: WhatsAppColors.subtitleGrey,
              ),
              style: const ConvoKitMessageListStyle(
                backgroundColor: WhatsAppColors.chatBackground,
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  backgroundColor: WhatsAppColors.outgoingBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  textBubbleStyle: CometChatTextBubbleStyle(
                    textStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color: WhatsAppColors.textPrimary,
                    ),
                  ),
                  messageBubbleDateStyle: ConvoKitDateStyle(
                    textStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: WhatsAppColors.subtitleGrey,
                    ),
                  ),
                ),
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  backgroundColor: WhatsAppColors.incomingBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  textBubbleStyle: CometChatTextBubbleStyle(
                    textStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color: WhatsAppColors.textPrimary,
                    ),
                  ),
                  messageBubbleDateStyle: ConvoKitDateStyle(
                    textStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: WhatsAppColors.subtitleGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ConvoKitMessageComposer(
            conversationId: conversationId,
            user: user,
            group: group,
            placeholderText: 'Message',
            attachmentIcon: const Icon(
              Icons.attach_file_rounded,
              color: WhatsAppColors.mutedIcon,
            ),
            voiceRecordingIcon: const Icon(
              Icons.mic_rounded,
              color: WhatsAppColors.mutedIcon,
            ),
            sendButtonIcon: const Icon(
              Icons.send_rounded,
              size: 18,
              color: Colors.white,
            ),
            messageComposerStyle: ConvoKitMessageComposerStyle(
              backgroundColor: WhatsAppColors.chatBackground,
              filledColor: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDADADA)),
              textColor: WhatsAppColors.textPrimary,
              placeHolderTextColor: WhatsAppColors.subtitleGrey,
              sendButtonIconBackgroundColor: WhatsAppColors.brandGreen,
              sendButtonIconColor: Colors.white,
              secondaryButtonIconColor: WhatsAppColors.mutedIcon,
              auxiliaryButtonIconColor: WhatsAppColors.mutedIcon,
            ),
          ),
        ],
      ),
    );
  }
}
