import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_tokens.dart';

/// Modal bottom-sheet wrapper mounting the library's [CometChatCreatePoll]
/// widget with concentric 28px sheet radii, semantic tonal surfaces, and
/// visible form helper guidance.
class CreatePollSheet extends StatelessWidget {
  const CreatePollSheet({
    super.key,
    required this.conversationId,
    this.user,
    this.group,
    this.quotedMessage,
    this.title,
  });

  final String conversationId;
  final ChatUser? user;
  final ChatGroup? group;
  final ChatMessage? quotedMessage;
  final String? title;

  /// Presents [CreatePollSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String conversationId,
    ChatUser? user,
    ChatGroup? group,
    ChatMessage? quotedMessage,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: CreatePollSheet(
          conversationId: conversationId,
          user: user,
          group: group,
          quotedMessage: quotedMessage,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final colorScheme = Theme.of(context).colorScheme;
    const sheetRadius = BorderRadius.vertical(
      top: Radius.circular(ShowcaseTokens.radiusSheet),
    );

    return ClipRRect(
      borderRadius: sheetRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: sheetRadius,
        ),
        child: Column(
          children: <Widget>[
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: ShowcaseTokens.spaceMd,
                  bottom: ShowcaseTokens.spaceXs,
                ),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderDark,
                    borderRadius: BorderRadius.circular(
                      ShowcaseTokens.radiusFullPill,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ShowcaseTokens.spaceLg,
                vertical: ShowcaseTokens.spaceXs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter a question and at least two answer options.',
                  style: ShowcaseTypography.rowSubtitle.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: CometChatCreatePoll(
                title: title,
                conversationId: conversationId,
                user: user?.id,
                group: group?.id,
                userObject: user,
                groupObject: group,
                quotedMessage: quotedMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
