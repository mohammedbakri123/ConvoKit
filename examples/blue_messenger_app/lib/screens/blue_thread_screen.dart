import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Threaded conversation screen combining [ConvoKitThreadedHeader],
/// [CometChatReactions], [ConvoKitMessageList], and a floating
/// [ConvoKitMessageComposer].
class BlueThreadScreen extends StatefulWidget {
  const BlueThreadScreen({
    super.key,
    required this.backend,
    required this.conversationId,
    required this.parentMessage,
    this.user,
    this.group,
  });

  final BlueInMemoryBackend backend;
  final String conversationId;
  final ChatMessage parentMessage;
  final ChatUser? user;
  final ChatGroup? group;

  @override
  State<BlueThreadScreen> createState() => _BlueThreadScreenState();
}

class _BlueThreadScreenState extends State<BlueThreadScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

  @override
  Widget build(BuildContext context) {
    final reactions = widget.backend.reactionsFor(widget.parentMessage.localId);
    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: const Text('Thread'),
      ),
      body: Column(
        children: [
          FloatingIslandCard(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            padding: const EdgeInsets.all(10),
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConvoKitThreadedHeader(
                  parentMessage: widget.parentMessage,
                  loggedInUser: widget.backend.currentUser,
                  user: widget.user,
                  group: widget.group,
                  initialReplyCount: 2,
                  style: const ConvoKitThreadedHeaderStyle(
                    bubbleContainerBackGroundColor:
                        BlueMessengerColors.islandSurface,
                    countTextColor: BlueMessengerColors.deepBlue,
                    countContainerBackGroundColor:
                        BlueMessengerColors.chipFill,
                  ),
                ),
                if (reactions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CometChatReactions(
                    reactionList: reactions,
                    alignment: BubbleAlignment.left,
                    onReactionTap: (emoji) {
                      if (emoji != null) {
                        setState(() {
                          widget.backend.toggleReaction(
                            widget.parentMessage.localId,
                            emoji,
                          );
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ConvoKitMessageList(
              conversationId: '${widget.conversationId}_thread',
              user: widget.user,
              group: widget.group,
              scrollController: _scrollController,
              onLoad: (_) => _scrollToBottom(),
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
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
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
                ),
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
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
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BlueIslandDecorations.floatingPill(radius: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ConvoKitMessageComposer(
                  conversationId: '${widget.conversationId}_thread',
                  user: widget.user,
                  group: widget.group,
                  placeholderText: 'Reply in thread...',
                  onSendButtonTap: (_, _, _) => _scrollToBottom(),
                  sendButtonIcon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  messageComposerStyle: ConvoKitMessageComposerStyle(
                    backgroundColor: BlueMessengerColors.islandSurface,
                    filledColor: BlueMessengerColors.chipFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: BlueMessengerColors.islandBorder,
                    ),
                    textColor: BlueMessengerColors.textPrimary,
                    placeHolderTextColor: BlueMessengerColors.textSecondary,
                    sendButtonIconBackgroundColor:
                        BlueMessengerColors.royalBlue,
                    sendButtonIconColor: Colors.white,
                    secondaryButtonIconColor: BlueMessengerColors.deepBlue,
                    auxiliaryButtonIconColor: BlueMessengerColors.deepBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
