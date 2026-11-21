import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';
import 'package:sample_app/screens/group_info_screen.dart';
import 'package:sample_app/screens/thread_screen.dart';
import 'package:sample_app/screens/user_info_screen.dart';

/// Offline chat screen combining [ConvoKitMessageHeader],
/// [ConvoKitMessageList], and [ConvoKitMessageComposer] over [ConvoKitScope].
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.user,
    this.group,
    this.conversationId,
    this.goToMessageId,
    this.showBackButton = true,
  }) : assert(
         user != null || group != null,
         'Either user or group must be provided',
       );

  final ChatUser? user;
  final ChatGroup? group;
  final String? conversationId;
  final String? goToMessageId;
  final bool showBackButton;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _resolveConversationId(BuildContext context) {
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      return widget.conversationId!;
    }
    final conv = SampleAppBackend.instance.backend.getConversationFor(
      userId: widget.user?.id,
      groupId: widget.group?.id,
    );
    if (conv != null) return conv.id;
    final meId = ConvoKitScope.of(context).session.currentUser?.id ?? 'me';
    if (widget.user != null) {
      return 'conv_${meId}_${widget.user!.id}';
    }
    return 'conv_group_${widget.group!.id}';
  }

  void _openInfo(BuildContext context) {
    if (widget.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserInfoScreen(user: widget.user!),
        ),
      );
    } else if (widget.group != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupInfoScreen(group: widget.group!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final conversationId = _resolveConversationId(context);

    return Scaffold(
      backgroundColor: palette.background1,
      resizeToAvoidBottomInset: true,
      appBar: ConvoKitMessageHeader(
        user: widget.user,
        group: widget.group,
        conversationId: conversationId,
        showBackButton: widget.showBackButton,
        onBack: () => Navigator.maybePop(context),
        trailingView: (user, group, context) => [
          IconButton(
            tooltip: 'Info',
            icon: Icon(Icons.info_outline, color: palette.iconPrimary),
            onPressed: () => _openInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ConvoKitMessageList(
              conversationId: conversationId,
              user: widget.user,
              group: widget.group,
              onThreadRepliesClick: (message, context, {template}) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThreadScreen(
                      user: widget.user,
                      group: widget.group,
                      message: message,
                      template: template,
                    ),
                  ),
                );
              },
              textFormatters: [
                CometChatMentionsFormatter(
                  user: widget.user,
                  group: widget.group,
                ),
                MarkdownTextFormatter(),
                CometChatUrlFormatter(),
                CometChatPhoneNumberFormatter(),
                CometChatEmailFormatter(),
              ],
            ),
          ),
          ConvoKitMessageComposer(
            conversationId: conversationId,
            user: widget.user,
            group: widget.group,
            textFormatters: [
              CometChatMentionsFormatter(
                user: widget.user,
                group: widget.group,
              ),
              MarkdownTextFormatter(),
              CometChatUrlFormatter(),
              CometChatPhoneNumberFormatter(),
              CometChatEmailFormatter(),
            ],
          ),
        ],
      ),
    );
  }
}
