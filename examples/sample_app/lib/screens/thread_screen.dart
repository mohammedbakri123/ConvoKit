import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// Offline thread screen built on [ConvoKitThreadedHeader],
/// [ConvoKitMessageList], and [ConvoKitMessageComposer] via [ConvoKitScope].
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    this.user,
    this.group,
    required this.message,
    this.template,
    this.goToMessageId,
    this.hideAppBar = false,
  });

  final ChatUser? user;
  final ChatGroup? group;
  final ChatMessage message;
  final CometChatMessageTemplate? template;
  final String? goToMessageId;
  final bool hideAppBar;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  @override
  Widget build(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final loggedInUser = ConvoKitScope.of(context).session.currentUser;

    return Scaffold(
      backgroundColor: colorPalette.background1,
      resizeToAvoidBottomInset: true,
      appBar: widget.hideAppBar
          ? null
          : ConvoKitMessageHeader(
              user: widget.user,
              group: widget.group,
              conversationId: widget.message.conversationId,
              onBack: () => Navigator.pop(context),
              listItemView: (group, user, context) {
                final name = group?.name ?? user?.name ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.of(context).thread,
                      style: TextStyle(
                        color: colorPalette.textPrimary,
                        fontSize: typography.heading2?.bold?.fontSize ?? 18,
                        fontWeight: typography.heading2?.bold?.fontWeight ??
                            FontWeight.bold,
                      ),
                    ),
                    if (name.isNotEmpty)
                      Text(
                        name,
                        style: TextStyle(
                          color: colorPalette.textSecondary,
                          fontSize:
                              typography.caption1?.regular?.fontSize ?? 12,
                        ),
                      ),
                  ],
                );
              },
            ),
      body: Column(
        children: [
          ConvoKitThreadedHeader(
            parentMessage: widget.message,
            loggedInUser: loggedInUser,
            user: widget.user,
            group: widget.group,
            template: widget.template,
            textFormatters: [
              CometChatMentionsFormatter(user: widget.user, group: widget.group),
              MarkdownTextFormatter(),
              CometChatUrlFormatter(),
              CometChatPhoneNumberFormatter(),
              CometChatEmailFormatter(),
            ],
          ),
          Expanded(
            child: ConvoKitMessageList(
              conversationId: widget.message.conversationId,
              user: widget.user,
              group: widget.group,
              textFormatters: [
                CometChatMentionsFormatter(user: widget.user, group: widget.group),
                MarkdownTextFormatter(),
                CometChatUrlFormatter(),
                CometChatPhoneNumberFormatter(),
                CometChatEmailFormatter(),
              ],
            ),
          ),
          ConvoKitMessageComposer(
            conversationId: widget.message.conversationId,
            user: widget.user,
            group: widget.group,
            textFormatters: [
              CometChatMentionsFormatter(user: widget.user, group: widget.group),
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
