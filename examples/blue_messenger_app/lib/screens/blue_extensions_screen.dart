import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../data/blue_in_memory_backend.dart';
import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Interactive floating-island showcase screen covering all ConvoKit extensions,
/// media/voice/action/deleted bubbles, reactions, rich text toolbar, inline
/// audio recorder, cards, utility primitives, and Core lightweight views
/// ([ConversationsView] & [MessageListView]).
class BlueExtensionsScreen extends StatefulWidget {
  const BlueExtensionsScreen({super.key, required this.backend});

  final BlueInMemoryBackend backend;

  @override
  State<BlueExtensionsScreen> createState() => _BlueExtensionsScreenState();
}

class _BlueExtensionsScreenState extends State<BlueExtensionsScreen> {
  final Set<FormatType> _activeFormats = {FormatType.bold};
  late List<PollOptions> _pollOptions;
  late List<Map<String, dynamic>> _sampleReactions;
  late final MediaMessage _sampleFileMessage;
  late final MediaMessage _sampleVideoMessage;
  late final MediaMessage _sampleImageMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pollOptions = [
      PollOptions(
        id: '1',
        optionText: 'Cobalt Floating Islands',
        voteCount: 4,
        votersUid: const ['me', 'user_maya', 'user_daniel', 'user_sara'],
        voters: [
          widget.backend.currentUser,
          widget.backend.maya,
          widget.backend.daniel,
          widget.backend.sara,
        ],
      ),
      PollOptions(
        id: '2',
        optionText: 'Royal Blue Glass Cards',
        voteCount: 2,
        votersUid: const ['user_leo', 'user_hana'],
        voters: [widget.backend.leo, widget.backend.hana],
      ),
    ];
    _sampleReactions = [
      {'reaction': '💙', 'count': 6, 'reactedByMe': true},
      {'reaction': '🚀', 'count': 3, 'reactedByMe': false},
      {'reaction': '✨', 'count': 2, 'reactedByMe': true},
    ];
    _sampleFileMessage = MediaMessage(
      id: 'showcase_file_1',
      localId: 'local_showcase_file_1',
      conversationId: 'conv_me_user_maya',
      sender: widget.backend.maya,
      createdAt: now,
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_showcase_file_1',
        remoteId: 'rem_showcase_file_1',
        kind: AttachmentKind.file,
        url: 'offline://Blue_Messenger_Architecture.pdf',
        state: AttachmentState.uploaded,
        mimeType: 'application/pdf',
        sizeBytes: 428000,
        name: 'Blue_Messenger_Architecture.pdf',
      ),
      caption: '428 KB · PDF',
    );
    _sampleVideoMessage = MediaMessage(
      id: 'showcase_video_1',
      localId: 'local_showcase_video_1',
      conversationId: 'conv_me_user_maya',
      sender: widget.backend.sara,
      createdAt: now,
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_showcase_video_1',
        remoteId: 'rem_showcase_video_1',
        kind: AttachmentKind.video,
        url: 'offline://floating_island_prototype.mp4',
        state: AttachmentState.uploaded,
        mimeType: 'video/mp4',
        sizeBytes: 2450000,
        name: 'floating_island_prototype.mp4',
      ),
      caption: 'Floating island prototype walkthrough',
    );
    _sampleImageMessage = MediaMessage(
      id: 'showcase_image_1',
      localId: 'local_showcase_image_1',
      conversationId: 'conv_me_user_maya',
      sender: widget.backend.maya,
      createdAt: now,
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_showcase_image_1',
        remoteId: 'rem_showcase_image_1',
        kind: AttachmentKind.image,
        url: 'offline://blue_messenger_palette.png',
        state: AttachmentState.uploaded,
        mimeType: 'image/png',
        sizeBytes: 184000,
        name: 'blue_messenger_palette.png',
      ),
      caption: 'Blue Messenger palette preview',
    );
  }

  void _votePoll(String voteId) {
    setState(() {
      _pollOptions = _pollOptions.map((opt) {
        if (opt.id == voteId) {
          return PollOptions(
            id: opt.id,
            optionText: opt.optionText,
            voteCount: opt.voteCount + 1,
            votersUid: [...opt.votersUid, 'me'],
            voters: [...opt.voters, widget.backend.currentUser],
          );
        }
        return opt;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: const Text('Extensions & Bubbles'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Marquee announcement banner
            const FloatingIslandCard(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                height: 24,
                child: CometChatMarquee(
                  text: 'Blue Messenger · 100% ConvoKit Library',
                  style: TextStyle(
                    color: BlueMessengerColors.deepBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SectionSeparator(
                text: 'Polls & Interactive Extensions',
                dividerColor: BlueMessengerColors.islandBorder,
                textStyle: TextStyle(
                  color: BlueMessengerColors.deepBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Polls Bubble + Create Poll launcher
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CometChatPollsBubble(
                    loggedInUser: widget.backend.currentUser.id,
                    pollQuestion: 'Which floating island style feels best?',
                    pollId: 'poll_showcase_1',
                    options: _pollOptions,
                    alignment: BubbleAlignment.left,
                    choosePoll: (vote, _) async => _votePoll(vote),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: BlueMessengerColors.deepBlue,
                      ),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => Padding(
                            padding: const EdgeInsets.fromLTRB(14, 48, 14, 18),
                            child: Container(
                              height: 500,
                              decoration: BlueIslandDecorations.floatingPill(
                                radius: 28,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: const CometChatCreatePoll(
                                title: 'New Team Poll',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_chart_rounded, size: 18),
                      label: const Text('Create Poll'),
                    ),
                  ),
                ],
              ),
            ),

            // Link Preview + Message Translation
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CometChatLinkPreviewBubble(
                    alignment: BubbleAlignment.left,
                    onTapUrl: (_) async {},
                    links: const [
                      {
                        'url': 'https://convokit.dev/docs',
                        'title': 'ConvoKit Flutter UI Kit',
                        'description':
                            'Pure-Dart contracts and modular Flutter messaging widgets.',
                      },
                    ],
                    child: const Text(
                      'https://convokit.dev/docs',
                      style: TextStyle(
                        color: BlueMessengerColors.royalBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const MessageTranslationBubble(
                    alignment: BubbleAlignment.left,
                    translatedText:
                        '¡Hola equipo! El diseño azul flotante está listo.',
                    child: Text(
                      'Hello team! The floating blue design is ready.',
                      style: TextStyle(color: BlueMessengerColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Collaborative Document & Whiteboard + WebView route
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CometChatCollaborativeBubble(
                    url: 'https://convokit.dev/collab/design-spec',
                    title: 'Collaborative Design Doc',
                    subtitle: 'Shared document · Ocean Design Guild',
                    buttonText: 'Open Document',
                    alignment: BubbleAlignment.left,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CometChatCollaborativeWebView(
                                title: 'Collaborative Whiteboard',
                                webviewUrl: 'https://convokit.dev/whiteboard',
                                appBarColor: BlueMessengerColors.deepBlue,
                                backIconColor: Colors.white,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.draw_outlined, size: 18),
                        label: const Text('Whiteboard WebView'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CometChatWebView(
                                title: 'ConvoKit Docs',
                                webViewUrl: 'https://convokit.dev/docs',
                                appBarColor: BlueMessengerColors.deepBlue,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.public_rounded, size: 18),
                        label: const Text('In-App WebView'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SectionSeparator(
                text: 'Media, Voice, Sticker & Status Bubbles',
                dividerColor: BlueMessengerColors.islandBorder,
                textStyle: TextStyle(
                  color: BlueMessengerColors.deepBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Text, Voice Note, File, Video, Image Moderation, Action, Deleted, MessageBubble
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConvoKitMessageBubble(
                    alignment: BubbleAlignment.right,
                    contentView: const CometChatTextBubble(
                      text: 'Standard CometChatTextBubble inside ConvoKitMessageBubble',
                      alignment: BubbleAlignment.right,
                    ),
                    footerView: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConvoKitDate(
                          date: DateTime.now(),
                          pattern: DateTimePattern.timeFormat,
                        ),
                        const SizedBox(width: 4),
                        const ConvoKitReceipt(
                          status: ReceiptStatus.read,
                          readIcon: Icon(
                            Icons.done_all_rounded,
                            size: 16,
                            color: BlueMessengerColors.skyBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const CometChatVoiceNoteBubble(
                    title: 'Design_Sync_Voice_Note.m4a',
                    alignment: BubbleAlignment.left,
                  ),
                  const SizedBox(height: 12),
                  CometChatFilesBubble(
                    message: _sampleFileMessage,
                    alignment: BubbleAlignment.left,
                    maxWidth: 260,
                  ),
                  const SizedBox(height: 12),
                  CometChatVideosBubble(
                    message: _sampleVideoMessage,
                    alignment: BubbleAlignment.left,
                    maxWidth: 220,
                  ),
                  const SizedBox(height: 12),
                  ImageModerationFilter(
                    message: _sampleImageMessage,
                    warningText: 'Sensitive media preview',
                    child: CometChatImagesBubble(
                      message: _sampleImageMessage,
                      alignment: BubbleAlignment.left,
                      maxWidth: 220,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const CometChatStickerBubble(
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 12),
                  const ConvoKitActionBubble(
                    text: 'Maya Lin added Sara Al-Harbi to Ocean Design Guild',
                  ),
                  const SizedBox(height: 8),
                  const ConvoKitDeletedBubble(),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SectionSeparator(
                text: 'Reactions, Composer Tools & Cards',
                dividerColor: BlueMessengerColors.islandBorder,
                textStyle: TextStyle(
                  color: BlueMessengerColors.deepBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Reactions + Rich Text Toolbar + Inline Audio Recorder
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CometChatReactions(
                    reactionList: _sampleReactions,
                    alignment: BubbleAlignment.left,
                    onReactionTap: (emoji) {
                      if (emoji == null) return;
                      setState(() {
                        for (final entry in _sampleReactions) {
                          if (entry['reaction'] == emoji) {
                            final active = entry['reactedByMe'] == true;
                            entry['reactedByMe'] = !active;
                            entry['count'] =
                                (entry['count'] as int) + (active ? -1 : 1);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ConvoKitRichTextToolbar(
                    activeFormats: _activeFormats,
                    onFormatTap: (fmt) {
                      setState(() {
                        if (!_activeFormats.add(fmt)) {
                          _activeFormats.remove(fmt);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CometChatInlineAudioRecorder(
                    onCancel: () {},
                    onSubmit: (_, {fileBytes}) {},
                  ),
                ],
              ),
            ),

            // DecoratedContainer, DottedBorder, Shimmer, ConvoKitCardView
            FloatingIslandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CometChatDecoratedContainer(
                    title: 'Decorated Floating Callout',
                    content: Text(
                      'Styled with Blue Messenger theme tokens.',
                      style: TextStyle(color: BlueMessengerColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DottedBorder(
                    color: BlueMessengerColors.royalBlue,
                    strokeWidth: 1.5,
                    radius: const Radius.circular(16),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ConvoKitShimmerEffect(
                          colorPalette: palette,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: BlueMessengerColors.chipFill,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'DottedBorder + ConvoKitShimmerEffect loading preview',
                            style: TextStyle(
                              color: BlueMessengerColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConvoKitCardView(
                    cardJson:
                        '{"type":"card","title":"Release Readiness Card","subtitle":"ConvoKit 0.1.0 · Pure Dart Core","body":[{"type":"text","text":"Zero SDK imports · 2,441 tests passing."}]}',
                    onAction: (_) {},
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SectionSeparator(
                text: 'Core Lightweight Views (lib/convokit.dart)',
                dividerColor: BlueMessengerColors.islandBorder,
                textStyle: TextStyle(
                  color: BlueMessengerColors.deepBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Core ConversationsView & MessageListView from lib/convokit.dart
            FloatingIslandCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Text(
                      'Core ConversationsView',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BlueMessengerColors.deepBlue,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ConversationsView(
                      onConversationTap: (_) {},
                    ),
                  ),
                  const Divider(color: BlueMessengerColors.islandBorder),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Text(
                      'Core MessageListView',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BlueMessengerColors.deepBlue,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 180,
                    child: MessageListView(
                      conversationId: 'conv_showcase_preview',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
