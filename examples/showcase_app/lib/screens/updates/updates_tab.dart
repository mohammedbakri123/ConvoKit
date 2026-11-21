import 'dart:async';
import 'dart:convert';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../backend/studio_backend.dart';
import '../../backend/studio_seed_data.dart';
import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';
import '../../widgets/floating_glass_tab_bar.dart';
import '../chat/create_poll_sheet.dart';
import 'core_views_demo_screen.dart';
import 'saved_messages_screen.dart';

/// Updates tab serving as the Extensions, Bubbles & Library Gallery.
///
/// Follows the 2026 "one hero moment per screen; the rest stays calm" principle:
/// - Top [CollapsingGlassHeader] driven by [ScrollController] + clearance for
///   both the header and [FloatingGlassTabBar].
/// - One tonal **Atelier Studio Showcase Hero Card** (`radius: 24`,
///   `primaryContainer` fill, `24pt w700` headline, live [CometChatPollsBubble],
///   full-pill `>=44px` CTA buttons).
/// - Calm grouped `surfaceContainerLow` cards (`radius: 20`, zero glass, zero
///   heavy shadows) preserving 100% of mounted library widgets.
/// - Built exclusively with [SingleChildScrollView] + [Column] (zero
///   hand-rolled `ListView`s).
class UpdatesTab extends StatefulWidget {
  const UpdatesTab({
    super.key,
    this.backend,
    this.headerActions,
  });

  /// Optional [StudioBackend] for live poll voting and saved messages wiring.
  final StudioBackend? backend;

  /// Optional trailing actions rendered inside [CollapsingGlassHeader].
  final List<GlassHeaderAction>? headerActions;

  @override
  State<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<UpdatesTab> {
  final ScrollController _scrollController = ScrollController();

  late final StudioSeedSnapshot _snapshot;
  late final MediaRecorderController _recorderController;
  late final DateTime _galleryDay;
  late final DateTime _galleryVideoTime;
  late final DateTime _galleryAudioTime;

  // Interactive Poll state
  late List<PollOptions> _pollOptions;

  // Sticker keyboard toggle state (visible by default to show empty-state gap)
  bool _showStickerKeyboard = true;

  // Reactions interactive state (user message/reaction content)
  late List<Map<String, dynamic>> _reactions;

  // Message preview dismiss/restore state
  bool _showMessagePreview = true;

  // Single-select state
  String _selectedDensity = 'balanced';

  // Time-slot selector state
  DateTime? _selectedSlot;

  // Search filter chips state
  final Set<String> _selectedFilters = <String>{'All'};

  // Status feedback banner text
  String? _lastInteractionNote;

  static const String _studioCardJson = '''
{
  "title": "Atelier Studio · Q2 Design Review",
  "fallbackText": "Atelier Studio Q2 Design Review",
  "body": [
    {
      "type": "text",
      "variant": "heading2",
      "content": "Design Systems v4 Sign-Off"
    },
    {
      "type": "text",
      "content": "All light and dark ConvoKitColorPalette tokens verified offline with zero SDK dependencies."
    },
    {
      "type": "button",
      "id": "approve_tokens",
      "label": "Approve Token Spec",
      "action": {
        "type": "customCallback",
        "callbackId": "approve_tokens"
      }
    }
  ]
}
''';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _galleryDay = DateTime(now.year, now.month, now.day);
    _galleryVideoTime = now.subtract(const Duration(minutes: 18));
    _galleryAudioTime = now.subtract(const Duration(minutes: 42));
    _snapshot = widget.backend?.seedSnapshot ?? StudioSeedData.create();
    _recorderController = MediaRecorderController(const MediaRecorderReady());
    _pollOptions = _buildInitialPollOptions();
    _reactions = <Map<String, dynamic>>[
      <String, dynamic>{'reaction': '🔥', 'count': 4, 'reactedByMe': true},
      <String, dynamic>{'reaction': '🎨', 'count': 2, 'reactedByMe': false},
      <String, dynamic>{'reaction': '✅', 'count': 3, 'reactedByMe': false},
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  List<PollOptions> _buildInitialPollOptions() {
    final nadia = _snapshot.users[0];
    final tariq = _snapshot.users[1];
    final amara = _snapshot.users[4];
    return <PollOptions>[
      PollOptions(
        id: '1',
        optionText: '4px base (compact)',
        voteCount: 1,
        votersUid: <String>[tariq.id],
        voters: <ChatUser>[tariq],
      ),
      PollOptions(
        id: '2',
        optionText: '8px base (balanced)',
        voteCount: 2,
        votersUid: <String>[nadia.id, amara.id],
        voters: <ChatUser>[nadia, amara],
      ),
      PollOptions(
        id: '3',
        optionText: '12px editorial',
        voteCount: 0,
        votersUid: <String>[],
        voters: <ChatUser>[],
      ),
    ];
  }

  Future<void> _handleChoosePoll(String optionId, String pollId) async {
    final currentUser =
        widget.backend?.session.currentUser ?? _snapshot.currentUser;

    widget.backend?.messages.votePoll(
      pollMessageId: pollId,
      optionId: optionId,
      voter: currentUser,
    );

    if (!mounted) return;
    setState(() {
      _pollOptions = _pollOptions.map((option) {
        final nextVotersUid = List<String>.from(option.votersUid)
          ..remove(currentUser.id);
        final nextVoters = option.voters
            .where((u) => u.id != currentUser.id)
            .toList();
        if (option.id == optionId) {
          nextVotersUid.add(currentUser.id);
          nextVoters.add(currentUser);
        }
        return PollOptions(
          id: option.id,
          optionText: option.optionText,
          voteCount: nextVotersUid.length,
          votersUid: nextVotersUid,
          voters: nextVoters,
        );
      }).toList();
      _lastInteractionNote = 'Voted for poll option #$optionId';
    });
  }

  void _toggleReaction(String? emoji) {
    if (emoji == null) return;
    setState(() {
      _reactions = _reactions.map((entry) {
        if (entry['reaction'] != emoji) return entry;
        final active = entry['reactedByMe'] == true;
        final count = (entry['count'] as int?) ?? 0;
        return <String, dynamic>{
          'reaction': emoji,
          'count': active ? (count > 1 ? count - 1 : 1) : count + 1,
          'reactedByMe': !active,
        };
      }).toList();
    });
  }

  void _openCreatePoll(BuildContext context) {
    unawaited(
      CreatePollSheet.show(
        context,
        conversationId: StudioSeedData.designSystemsConvId,
        group: _snapshot.groups.first,
        title: 'Create Studio Poll',
      ),
    );
  }

  void _openCoreViews(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CoreViewsDemoScreen(),
        ),
      ),
    );
  }

  void _openSavedMessages(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SavedMessagesScreen(backend: widget.backend),
        ),
      ),
    );
  }

  void _openCollaborativeWebView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CometChatCollaborativeWebView(
            title: 'Atelier Design Spec',
            webviewUrl: 'https://atelier.studio/docs/tokens-v4',
            appBarColor: colorScheme.surfaceContainerLow,
            backIconColor: colorScheme.primary,
            titleStyle: ShowcaseTypography.compactTitle.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  void _openWebView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CometChatWebView(
            title: 'ConvoKit Web Preview',
            webViewUrl: 'https://atelier.studio/whiteboard/q2',
            appBarColor: colorScheme.surfaceContainerLow,
            webViewStyle: WebViewStyle(
              appBarColor: colorScheme.surfaceContainerLow,
              backIconColor: colorScheme.primary,
              titleStyle: ShowcaseTypography.compactTitle.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required ChatUser currentUser,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Container(
      key: const Key('updates_hero_card'),
      margin: const EdgeInsets.fromLTRB(
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceXs,
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceSm,
      ),
      padding: const EdgeInsets.all(ShowcaseTokens.spaceXl),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusHeroCard),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: ShowcaseTokens.spaceSm),
              Text(
                'STUDIO SHOWCASE',
                style: ShowcaseTypography.sectionLabel.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: ShowcaseTokens.spaceSm),
          Text(
            'Atelier Studio Showcase',
            style: ShowcaseTypography.heroHeadline.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: ShowcaseTokens.spaceXs),
          Text(
            'Vote live in-memory or jump directly into Core lightweight views and Saved Messages.',
            style: ShowcaseTypography.rowSubtitle.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: ShowcaseTokens.spaceLg),
          CometChatPollsBubble(
            pollId: StudioSeedData.designPollMsgId,
            pollQuestion:
                'Which grid density should we ship for the Q2 icon set?',
            loggedInUser: currentUser.id,
            options: _pollOptions,
            alignment: BubbleAlignment.left,
            choosePoll: _handleChoosePoll,
            style: CometChatPollsBubbleStyle(
              backgroundColor: colorScheme.surfaceContainerLowest,
              questionTextStyle: ShowcaseTypography.rowTitle.copyWith(
                color: colorScheme.onSurface,
              ),
              pollOptionsTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
                color: colorScheme.onSurface,
              ),
              voteCountTextStyle: ShowcaseTypography.timestamp.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              borderRadius: BorderRadius.circular(
                ShowcaseTokens.radiusNestedCard,
              ),
              border: Border.all(color: colorScheme.outlineVariant),
              progressColor: palette.primary,
              selectedOptionColor: palette.primary,
            ),
          ),
          const SizedBox(height: ShowcaseTokens.spaceLg),
          Wrap(
            spacing: ShowcaseTokens.spaceSm,
            runSpacing: ShowcaseTokens.spaceSm,
            children: <Widget>[
              FilledButton.icon(
                key: const Key('updates_open_core_views_button'),
                onPressed: () => _openCoreViews(context),
                icon: const ExcludeSemantics(
                  child: Icon(Icons.view_quilt_outlined, size: 18),
                ),
                label: const Text('Core Views Demo'),
              ),
              OutlinedButton.icon(
                key: const Key('updates_open_saved_messages_button'),
                onPressed: () => _openSavedMessages(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                ),
                icon: const ExcludeSemantics(
                  child: Icon(Icons.bookmark_border_rounded, size: 18),
                ),
                label: const Text('Saved Messages'),
              ),
              OutlinedButton.icon(
                key: const Key('updates_create_poll_button'),
                onPressed: () => _openCreatePoll(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                ),
                icon: const ExcludeSemantics(
                  child: Icon(Icons.poll_outlined, size: 18),
                ),
                label: const Text('Create Poll'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ShowcaseTokens.spaceLg,
            ShowcaseTokens.spaceXl,
            ShowcaseTokens.spaceLg,
            ShowcaseTokens.spaceSm,
          ),
          child: SectionSeparator(
            text: title,
            height: 28,
            dividerColor: colorScheme.outlineVariant,
            textStyle: ShowcaseTypography.sectionLabel.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildShowcaseCard(
    BuildContext context, {
    required String label,
    String? caption,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ShowcaseTokens.spaceLg,
        vertical: ShowcaseTokens.spaceSm,
      ),
      padding: const EdgeInsets.all(ShowcaseTokens.spaceLg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusCard),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: ShowcaseTypography.rowTitle.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: ShowcaseTokens.spaceXs),
            Text(
              caption,
              style: ShowcaseTypography.rowSubtitle.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: ShowcaseTokens.spaceMd),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser =
        widget.backend?.session.currentUser ??
        ConvoKitScope.maybeOf(context)?.session.currentUser ??
        _snapshot.currentUser;

    final topClearance =
        CollapsingGlassHeader.topClearance(context) + ShowcaseTokens.spaceSm;
    final bottomClearance = FloatingGlassTabBar.bottomClearance(context);
    final nestedRadius = BorderRadius.circular(ShowcaseTokens.radiusNestedCard);

    // Seeded sample messages for the gallery (type-safe lookups)
    final imageMessage = _snapshot
        .messagesByConversation[StudioSeedData.brandRefreshConvId]!
        .whereType<MediaMessage>()
        .firstWhere((m) => m.attachment.kind == AttachmentKind.image);
    final fileMessage = _snapshot
        .messagesByConversation[StudioSeedData.designSystemsConvId]!
        .whereType<MediaMessage>()
        .firstWhere((m) => m.attachment.kind == AttachmentKind.file);
    final voiceNoteMessage = _snapshot
        .messagesByConversation[StudioSeedData.tariqConvId]!
        .whereType<MediaMessage>()
        .firstWhere((m) => m.attachment.kind == AttachmentKind.audio);
    final stickerMessage = _snapshot
        .messagesByConversation[StudioSeedData.studioLoungeConvId]!
        .whereType<CustomMessage>()
        .first;
    final sampleTextMessage = _snapshot
        .messagesByConversation[StudioSeedData.designSystemsConvId]!
        .whereType<TextMessage>()
        .first;

    // Offline-safe video MediaMessage (empty local path avoids network/plugin stalls)
    final galleryVideoMessage = MediaMessage(
      id: 'gallery_video_001',
      localId: 'local_gallery_video_001',
      conversationId: StudioSeedData.studioLoungeConvId,
      sender: _snapshot.users[3],
      createdAt: _galleryVideoTime,
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_gallery_video',
        remoteId: 'media_gallery_video',
        kind: AttachmentKind.video,
        url: '',
        state: AttachmentState.uploaded,
        mimeType: 'video/mp4',
        sizeBytes: 4200000,
        name: 'spring_transition_preview.mp4',
      ),
      caption: 'Spring physics transition preview clip',
    );

    final galleryAudioMessage = MediaMessage(
      id: 'gallery_audio_001',
      localId: 'local_gallery_audio_001',
      conversationId: StudioSeedData.tariqConvId,
      sender: _snapshot.users[1],
      createdAt: _galleryAudioTime,
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_gallery_audio',
        remoteId: 'media_gallery_audio',
        kind: AttachmentKind.audio,
        url: 'https://atelier.studio/assets/audio/studio_brief.m4a',
        state: AttachmentState.uploaded,
        mimeType: 'audio/m4a',
        sizeBytes: 512000,
        name: 'studio_brief.m4a',
      ),
      caption: 'Audio design brief recording',
      metadata: const <String, dynamic>{
        'audioDurationsMs': <int>[64000],
      },
    );

    final mediaViewerItems = <ChatAttachment>[
      imageMessage.attachment,
      galleryVideoMessage.attachment,
    ];

    final attachmentActions = <ActionItem>[
      ActionItem(
        id: 'photo',
        title: 'Photo Library',
        icon: ExcludeSemantics(
          child: Icon(Icons.photo_library_outlined, color: colorScheme.primary),
        ),
        onItemClick: () {
          setState(() => _lastInteractionNote = 'Selected Photo Library');
        },
      ),
      ActionItem(
        id: 'document',
        title: 'Document',
        icon: ExcludeSemantics(
          child: Icon(Icons.description_outlined, color: colorScheme.primary),
        ),
        onItemClick: () {
          setState(() => _lastInteractionNote = 'Selected Document');
        },
      ),
    ];

    final messageActions = <ActionItem>[
      ActionItem(
        id: 'reply',
        title: 'Reply in Thread',
        icon: ExcludeSemantics(
          child: Icon(Icons.reply_rounded, color: colorScheme.primary),
        ),
        onItemClick: () {
          setState(() => _lastInteractionNote = 'Selected Reply in Thread');
        },
      ),
      ActionItem(
        id: 'bookmark',
        title: 'Save Message',
        icon: ExcludeSemantics(
          child: Icon(Icons.bookmark_border_rounded, color: colorScheme.primary),
        ),
        onItemClick: () {
          setState(() => _lastInteractionNote = 'Selected Save Message');
        },
      ),
    ];

    final outgoingBubbleColor = isDark
        ? ShowcaseTokens.darkOutgoingBubble
        : ShowcaseTokens.lightOutgoingBubble;
    final outgoingBubbleText = isDark
        ? ShowcaseTokens.darkOutgoingText
        : ShowcaseTokens.lightOutgoingText;

    return ColoredBox(
      color: palette.background1 ?? colorScheme.surface,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SingleChildScrollView(
              key: const Key('updates_gallery_scroll'),
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: topClearance,
                bottom: bottomClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // One expressive hero moment per screen
                  _buildHeroCard(context, currentUser: currentUser),

                  if (_lastInteractionNote != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ShowcaseTokens.spaceLg,
                        ShowcaseTokens.spaceSm,
                        ShowcaseTokens.spaceLg,
                        0,
                      ),
                      child: ConvoKitActionBubble(
                        text: _lastInteractionNote!,
                        style: ConvoKitActionBubbleStyle(
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            ShowcaseTokens.radiusFullPill,
                          ),
                          border: Border.all(color: colorScheme.outlineVariant),
                          textStyle: ShowcaseTypography.timestamp.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // ===========================================================
                  // SECTION 1: EXTENSIONS GALLERY
                  // ===========================================================
                  _buildSection(
                    context,
                    title: 'EXTENSIONS GALLERY',
                    children: <Widget>[
                      _buildShowcaseCard(
                        context,
                        label:
                            'CometChatStickerBubble, CometChatStickerKeyboard & StickerAuxiliaryButton',
                        caption:
                            'StickerKeyboard mounts its Phase-7 empty state cleanly (Gap #6)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CometChatStickerBubble(
                                  message: stickerMessage,
                                  width: 96,
                                  height: 96,
                                ),
                                const SizedBox(width: ShowcaseTokens.spaceMd),
                                StickerAuxiliaryButton(
                                  stickerIconTint: colorScheme.primary,
                                  keyboardIconTint: colorScheme.secondary,
                                  onStickerTap: () {
                                    setState(() => _showStickerKeyboard = true);
                                  },
                                  onKeyboardTap: () {
                                    setState(
                                      () => _showStickerKeyboard = false,
                                    );
                                  },
                                ),
                                const SizedBox(width: ShowcaseTokens.spaceSm),
                                Expanded(
                                  child: Text(
                                    _showStickerKeyboard
                                        ? 'Sticker panel open (empty state)'
                                        : 'Tap sticker icon to open panel',
                                    style: ShowcaseTypography.timestamp
                                        .copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            if (_showStickerKeyboard) ...<Widget>[
                              const SizedBox(height: ShowcaseTokens.spaceMd),
                              ClipRRect(
                                borderRadius: nestedRadius,
                                child: CometChatStickerKeyboard(
                                  height: 160,
                                  onStickerTap: (_) {},
                                  style: CometChatStickerKeyboardStyle(
                                    backgroundColor:
                                        colorScheme.surfaceContainerLowest,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'MessageTranslationBubble',
                        caption: 'Original text paired with offline translation',
                        child: Container(
                          padding: const EdgeInsets.all(ShowcaseTokens.spaceMd),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: nestedRadius,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: MessageTranslationBubble(
                            alignment: BubbleAlignment.left,
                            translatedText:
                                'Bonjour l’équipe ! Validation des tokens 2026 avant 16 h.',
                            style: CometChatMessageTranslationBubbleStyle(
                              dividerColor: colorScheme.outlineVariant,
                              translatedTextStyle: ShowcaseTypography
                                  .rowSubtitle
                                  .copyWith(color: colorScheme.onSurface),
                              infoTextStyle: ShowcaseTypography.timestamp
                                  .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            child: CometChatTextBubble(
                              text:
                                  'Morning team! Finalizing the 2026 token spec before 4 PM.',
                              alignment: BubbleAlignment.left,
                              style: CometChatTextBubbleStyle(
                                backgroundColor: Colors.transparent,
                                textColor: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatLinkPreviewBubble',
                        caption: 'Seeded Atelier Studio link metadata card',
                        child: CometChatLinkPreviewBubble(
                          alignment: BubbleAlignment.left,
                          links: const <Map<String, dynamic>>[
                            <String, dynamic>{
                              'url': 'https://atelier.studio/design-tokens',
                              'title': 'Atelier Design System v4',
                              'description':
                                  'Color tokens, spacing scale, and accessibility contrast tables.',
                              'image': 'https://atelier.studio/og/tokens.png',
                            },
                          ],
                          defaultImage: SizedBox(
                            height: 80,
                            width: 232,
                            child: CometChatMediaPlaceholder(
                              backgroundColor: colorScheme.surfaceContainerHigh,
                            ),
                          ),
                          onTapUrl: (url) async {
                            if (!mounted) return;
                            setState(
                              () => _lastInteractionNote = 'Link tapped: $url',
                            );
                          },
                          style: CometChatLinkPreviewBubbleStyle(
                            backgroundColor: colorScheme.surfaceContainerLowest,
                            tileColor: colorScheme.surfaceContainerLowest,
                            titleStyle: ShowcaseTypography.rowTitle.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            descriptionStyle: ShowcaseTypography.rowSubtitle
                                .copyWith(color: colorScheme.onSurfaceVariant),
                            urlStyle: ShowcaseTypography.timestamp.copyWith(
                              color: colorScheme.primary,
                            ),
                            borderRadius: nestedRadius,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'ImageModerationFilter',
                        caption: 'Wraps a MediaMessage with moderation guard',
                        child: ImageModerationFilter(
                          message: imageMessage,
                          warningText: 'Sensitive media content',
                          style: ImageModerationFilterStyle(
                            filterColor: colorScheme.surfaceContainerHigh,
                            warningTextStyle: ShowcaseTypography.rowTitle
                                .copyWith(color: colorScheme.onSurface),
                          ),
                          child: SizedBox(
                            height: 110,
                            width: 180,
                            child: ClipRRect(
                              borderRadius: nestedRadius,
                              child: CometChatMediaPlaceholder(
                                backgroundColor:
                                    colorScheme.surfaceContainerHigh,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label:
                            'CometChatCollaborativeBubble, CometChatCollaborativeWebView & CometChatWebView',
                        caption:
                            'Collaborative document card + WebView launchers',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CometChatCollaborativeBubble(
                              url: 'https://atelier.studio/docs/tokens-v4',
                              title: 'Atelier Token Spec',
                              subtitle: 'Edit design tokens together',
                              buttonText: 'Open Document',
                              alignment: BubbleAlignment.left,
                              style: CometChatCollaborativeBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                titleStyle: ShowcaseTypography.rowTitle
                                    .copyWith(color: colorScheme.onSurface),
                                subtitleStyle: ShowcaseTypography.rowSubtitle
                                    .copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                buttonTextStyle: ShowcaseTypography.buttonLabel
                                    .copyWith(color: colorScheme.primary),
                                dividerColor: colorScheme.outlineVariant,
                                borderRadius: nestedRadius,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                iconTint: colorScheme.primary,
                                webViewAppBarColor:
                                    colorScheme.surfaceContainerLow,
                                webViewBackIconColor: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            Wrap(
                              spacing: ShowcaseTokens.spaceSm,
                              runSpacing: ShowcaseTokens.spaceSm,
                              children: <Widget>[
                                OutlinedButton(
                                  onPressed: () =>
                                      _openCollaborativeWebView(context),
                                  child: const Text('CollaborativeWebView'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _openWebView(context),
                                  child: const Text('CometChatWebView'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'ConvoKitCardView',
                        caption: 'Pure-Flutter interactive JSON card renderer',
                        child: ConvoKitCardView(
                          cardJson: jsonEncode(jsonDecode(_studioCardJson)),
                          themeMode: ConvoKitCardThemeMode.auto,
                          onAction: (event) {
                            setState(() {
                              _lastInteractionNote =
                                  'Card action: ${event.elementId} (${event.action.type})';
                            });
                          },
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatCard',
                        caption: 'Library structured card primitive',
                        child: Center(
                          child: CometChatCard(
                            title: 'Atelier Studio',
                            avatarName: 'AS',
                            avatarWidth: 56,
                            avatarHeight: 56,
                            titlePadding: const EdgeInsets.only(
                              bottom: ShowcaseTokens.spaceXs,
                            ),
                            cardStyle: CardStyle(
                              titleStyle: ShowcaseTypography.compactTitle
                                  .copyWith(color: colorScheme.onSurface),
                              avatarStyle: ShowcaseTheme.avatarStyle(context),
                            ),
                            subtitleView: Padding(
                              padding: const EdgeInsets.only(
                                bottom: ShowcaseTokens.spaceSm,
                              ),
                              child: Text(
                                '8 teammates · 3 studio channels',
                                style: ShowcaseTypography.rowSubtitle.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ===========================================================
                  // SECTION 2: BUBBLES & MEDIA VIEWERS GALLERY
                  // ===========================================================
                  _buildSection(
                    context,
                    title: 'BUBBLES & MEDIA VIEWERS GALLERY',
                    children: <Widget>[
                      _buildShowcaseCard(
                        context,
                        label: 'CometChatTextBubble',
                        caption: 'Standalone incoming & outgoing text bubbles',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CometChatTextBubble(
                                text:
                                    'Incoming studio note styled via ConvoKit.',
                                alignment: BubbleAlignment.left,
                                style: CometChatTextBubbleStyle(
                                  backgroundColor:
                                      colorScheme.surfaceContainerLowest,
                                  textColor: colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(
                                    ShowcaseTokens.radiusBubble,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceSm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: CometChatTextBubble(
                                text:
                                    'Outgoing reply with WhatsApp-inspired palette.',
                                alignment: BubbleAlignment.right,
                                style: CometChatTextBubbleStyle(
                                  backgroundColor: outgoingBubbleColor,
                                  textColor: outgoingBubbleText,
                                  borderRadius: BorderRadius.circular(
                                    ShowcaseTokens.radiusBubble,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatVoiceNoteBubble & CometChatAudioPlayer',
                        caption: 'Waveform voice note + standalone audio player',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CometChatVoiceNoteBubble(
                              audioUrl: voiceNoteMessage.attachment.url,
                              title: voiceNoteMessage.attachment.name,
                              alignment: BubbleAlignment.left,
                              metadata: voiceNoteMessage.metadata,
                              style: CometChatVoiceNoteBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                playIconColor: colorScheme.primary,
                                audioBarColor: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            CometChatAudioPlayer(
                              audioUrl: galleryAudioMessage.attachment.url,
                              title: galleryAudioMessage.attachment.name,
                              alignment: BubbleAlignment.left,
                              style: CometChatVoiceNoteBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                playIconColor: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatImageBubble & CometChatImagesBubble',
                        caption:
                            'Single-image (legacy) & multi-image grid bubble',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // ignore: deprecated_member_use
                            CometChatImageBubble(
                              imageUrl: imageMessage.attachment.url,
                              width: 180,
                              height: 110,
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            CometChatImagesBubble(
                              message: imageMessage,
                              alignment: BubbleAlignment.left,
                              maxWidth: 240,
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatVideoBubble & CometChatVideosBubble',
                        caption:
                            'Single-video (legacy) & multi-video grid bubble',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // ignore: deprecated_member_use
                            CometChatVideoBubble(
                              videoUrl: '',
                              width: 180,
                              height: 110,
                              placeHolder: CometChatMediaPlaceholder(
                                backgroundColor:
                                    colorScheme.surfaceContainerHigh,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            CometChatVideosBubble(
                              message: galleryVideoMessage,
                              alignment: BubbleAlignment.left,
                              maxWidth: 240,
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatAudiosBubble',
                        caption: 'Multi-attachment audio list bubble',
                        child: CometChatAudiosBubble(
                          message: galleryAudioMessage,
                          alignment: BubbleAlignment.left,
                          maxWidth: 260,
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatFileBubble & CometChatFilesBubble',
                        caption:
                            'Single-file (legacy) & multi-file card stack bubble',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // ignore: deprecated_member_use
                            CometChatFileBubble(
                              title: fileMessage.attachment.name,
                              subtitle: '2.4 MB · PDF',
                              fileUrl: fileMessage.attachment.url,
                              fileMimeType: fileMessage.attachment.mimeType,
                              fileExtension: 'pdf',
                              fileSize: fileMessage.attachment.sizeBytes,
                              alignment: BubbleAlignment.left,
                              style: CometChatFileBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                titleColor: colorScheme.onSurface,
                                subtitleColor: colorScheme.onSurfaceVariant,
                                downloadIconTint: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            CometChatFilesBubble(
                              message: fileMessage,
                              alignment: BubbleAlignment.left,
                              maxWidth: 260,
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label:
                            'CometChatMediaGrid, CometChatMediaCaption, CometChatMediaPlaceholder & CometChatVideoFirstFrame',
                        caption:
                            'Shared media grid, caption, placeholders & frame extractor',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CometChatMediaGrid(
                              media: mediaViewerItems,
                              width: 240,
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceSm),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  ShowcaseTokens.spaceMd,
                                ),
                              ),
                              child: CometChatMediaCaption(
                                caption:
                                    'Shared CometChatMediaCaption with markdown **bold** support.',
                                alignment: BubbleAlignment.left,
                                textStyle: ShowcaseTypography.rowSubtitle
                                    .copyWith(color: colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 72,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      ShowcaseTokens.spaceSm,
                                    ),
                                    child: CometChatMediaPlaceholder(
                                      backgroundColor:
                                          colorScheme.surfaceContainerHigh,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: ShowcaseTokens.spaceSm),
                                SizedBox(
                                  width: 72,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      ShowcaseTokens.spaceSm,
                                    ),
                                    child: CometChatMediaPlaceholder(
                                      backgroundColor:
                                          colorScheme.surfaceContainerHigh,
                                      unsupported: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: ShowcaseTokens.spaceSm),
                                SizedBox(
                                  width: 72,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      ShowcaseTokens.spaceSm,
                                    ),
                                    child: CometChatVideoFirstFrame(
                                      source: '',
                                      fallback: CometChatMediaPlaceholder(
                                        backgroundColor:
                                            colorScheme.surfaceContainerHigh,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'ConvoKitDeletedBubble & ConvoKitActionBubble',
                        caption:
                            'Deleted message placeholder & system event pill',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ConvoKitDeletedBubble(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ShowcaseTokens.spaceMd,
                                vertical: ShowcaseTokens.spaceSm,
                              ),
                              style: ConvoKitDeletedBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                iconColor: colorScheme.onSurfaceVariant,
                                textColor: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            ConvoKitActionBubble(
                              text:
                                  'Nadia Haddad added Amara Okafor to Design Systems',
                              style: ConvoKitActionBubbleStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  ShowcaseTokens.radiusFullPill,
                                ),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                textStyle: ShowcaseTypography.timestamp
                                    .copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'Fullscreen Media Viewer Launchers',
                        caption:
                            'CometChatMediaViewer, ImageViewer & VideoPlayer',
                        child: Wrap(
                          spacing: ShowcaseTokens.spaceSm,
                          runSpacing: ShowcaseTokens.spaceSm,
                          children: <Widget>[
                            OutlinedButton.icon(
                              key: const Key(
                                'updates_open_media_viewer_button',
                              ),
                              onPressed: () {
                                unawaited(
                                  CometChatMediaViewer.open(
                                    context,
                                    mediaViewerItems,
                                  ),
                                );
                              },
                              icon: const ExcludeSemantics(
                                child: Icon(
                                  Icons.collections_outlined,
                                  size: 18,
                                ),
                              ),
                              label: const Text('CometChatMediaViewer'),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'updates_open_image_viewer_button',
                              ),
                              onPressed: () {
                                unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ImageViewer(
                                        imageUrl:
                                            imageMessage.attachment.url ?? '',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const ExcludeSemantics(
                                child: Icon(Icons.image_outlined, size: 18),
                              ),
                              label: const Text('ImageViewer'),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'updates_open_video_player_button',
                              ),
                              onPressed: () {
                                unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const VideoPlayer(
                                        videoUrl:
                                            'https://atelier.studio/assets/micro_interactions_reel.mp4',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const ExcludeSemantics(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 18,
                                ),
                              ),
                              label: const Text('VideoPlayer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ===========================================================
                  // SECTION 3: REACTIONS, COMPOSER & INTERACTIVE PRIMITIVES
                  // ===========================================================
                  _buildSection(
                    context,
                    title: 'REACTIONS, COMPOSER & INTERACTIVE PRIMITIVES',
                    children: <Widget>[
                      _buildShowcaseCard(
                        context,
                        label: 'CometChatReactions & CometChatReactionList',
                        caption:
                            'Tap reaction pills to toggle local state (Gap #4)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CometChatReactions(
                              reactionList: _reactions,
                              alignment: BubbleAlignment.left,
                              onReactionTap: _toggleReaction,
                              style: CometChatReactionsStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                activeReactionBackgroundColor:
                                    colorScheme.primaryContainer,
                                countTextColor: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            CometChatReactionList(
                              height: 64,
                              message: sampleTextMessage,
                              emptyStateText:
                                  'Reaction list sheet (v1 backend deferred)',
                              style: CometChatReactionListStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'ConvoKitMessagePreview',
                        caption: 'Quoted reply banner used above composer',
                        child: _showMessagePreview
                            ? ConvoKitMessagePreview(
                                messagePreviewTitle: 'Nadia Haddad',
                                messagePreviewSubtitle:
                                    'Finalizing the 2026 token spec today.',
                                message: sampleTextMessage,
                                onCloseClick: () {
                                  setState(() => _showMessagePreview = false);
                                },
                                messagePreviewStyle:
                                    ConvoKitMessagePreviewStyle(
                                      messagePreviewBackground:
                                          colorScheme.surfaceContainerLowest,
                                      messagePreviewTitleColor:
                                          colorScheme.primary,
                                      messagePreviewSubtitleColor:
                                          colorScheme.onSurfaceVariant,
                                    ),
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  setState(() => _showMessagePreview = true);
                                },
                                child: const Text(
                                  'Restore ConvoKitMessagePreview',
                                ),
                              ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'ConvoKitEmojiKeyboard',
                        caption: 'Category-indexed emoji picker grid',
                        child: ClipRRect(
                          borderRadius: nestedRadius,
                          child: ConvoKitEmojiKeyboard(colorPalette: palette),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatMediaRecorder',
                        caption:
                            'Standalone audio recorder driven by MediaRecorderController',
                        child: CometChatMediaRecorder(
                          mediaRecorderController: _recorderController,
                          onSubmit: (_, path) {
                            setState(
                              () => _lastInteractionNote =
                                  'Recorder submitted: $path',
                            );
                          },
                          onClose: () {
                            _recorderController.cancelRecording();
                          },
                          style: CometChatMediaRecorderStyle(
                            backgroundColor: colorScheme.surfaceContainerLowest,
                            borderRadius: nestedRadius,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatQuickView',
                        caption: 'Accent-barred quick preview card',
                        child: CometChatQuickView(
                          title: 'Design Systems · Pinned Note',
                          subtitle:
                              'WCAG AA contrast checks cleared across all surfaces.',
                          quickViewStyle: QuickViewStyle(
                            background: colorScheme.surfaceContainerLowest,
                            leadingBarTint: colorScheme.primary,
                            leadingBarWidth: 4,
                            titleStyle: ShowcaseTypography.rowTitle.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            subtitleStyle: ShowcaseTypography.rowSubtitle
                                .copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatSingleSelect',
                        caption: 'Interactive single-choice selector',
                        child: CometChatSingleSelect(
                          selectedValue: _selectedDensity,
                          options: <OptionElement>[
                            OptionElement(
                              value: 'compact',
                              label: 'Compact (4px)',
                            ),
                            OptionElement(
                              value: 'balanced',
                              label: 'Balanced (8px)',
                            ),
                          ],
                          optionBackground: colorScheme.surfaceContainerLowest,
                          selectedOptionBackground: colorScheme.primary,
                          optionTextStyle: ShowcaseTypography.rowSubtitle
                              .copyWith(color: colorScheme.onSurface),
                          selectedOptionsTextStyle: ShowcaseTypography
                              .buttonLabel
                              .copyWith(color: colorScheme.onPrimary),
                          onChanged: (value) {
                            setState(() {
                              _selectedDensity = value;
                              _lastInteractionNote = 'Selected density: $value';
                            });
                          },
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'CometChatTimeSlotSelector',
                        caption: 'Studio critique slot picker',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CometChatTimeSlotSelector(
                              selectedDay: _galleryDay,
                              duration: const Duration(minutes: 30),
                              timeFormat: TimeFormat.twelveHour,
                              availableSlots: <DateTimeRange>[
                                DateTimeRange(
                                  start: DateTime(
                                    _galleryDay.year,
                                    _galleryDay.month,
                                    _galleryDay.day,
                                    10,
                                    0,
                                  ),
                                  end: DateTime(
                                    _galleryDay.year,
                                    _galleryDay.month,
                                    _galleryDay.day,
                                    11,
                                    30,
                                  ),
                                ),
                              ],
                              style: TimeSlotSelectorStyle(
                                slotBackgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                selectedSlotBackgroundColor:
                                    colorScheme.primary,
                                slotTextStyle: ShowcaseTypography.timestamp
                                    .copyWith(color: colorScheme.onSurface),
                                selectedSlotTextStyle: ShowcaseTypography
                                    .timestamp
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimary,
                                    ),
                              ),
                              onSelection: (slot) {
                                setState(() {
                                  _selectedSlot = slot;
                                  _lastInteractionNote =
                                      'Selected slot: ${slot.hour}:${slot.minute.toString().padLeft(2, '0')}';
                                });
                              },
                            ),
                            if (_selectedSlot != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: ShowcaseTokens.spaceSm,
                                ),
                                child: Text(
                                  'Picked: ${_selectedSlot!.hour}:${_selectedSlot!.minute.toString().padLeft(2, '0')}',
                                  style: ShowcaseTypography.timestamp.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label:
                            'CometChatDecoratedContainer, DottedBorder & CometChatMarquee',
                        caption: 'Container, dashed border, and marquee utilities',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            CometChatDecoratedContainer(
                              title: 'Studio Status',
                              colorPalette: palette,
                              typography: typography,
                              spacing: spacing,
                              padding: const EdgeInsets.all(
                                ShowcaseTokens.spaceMd,
                              ),
                              margin: EdgeInsets.zero,
                              style: DecoratedContainerStyle(
                                backgroundColor:
                                    colorScheme.surfaceContainerLowest,
                                borderRadius: nestedRadius,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              content: CometChatMarquee(
                                text: 'Atelier Studio · ConvoKit 0.1.0',
                                style: ShowcaseTypography.rowSubtitle.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            DottedBorder(
                              color: colorScheme.primary,
                              strokeWidth: 1.2,
                              radius: const Radius.circular(
                                ShowcaseTokens.radiusNestedCard,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: ShowcaseTokens.spaceMd,
                                vertical: ShowcaseTokens.spaceMd,
                              ),
                              child: Text(
                                'DottedBorder drop-zone primitive',
                                style: ShowcaseTypography.rowSubtitle.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label: 'GetMenuView & SearchFilterChip',
                        caption:
                            'Menu option row and toggleable search filter chips',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: nestedRadius,
                              child: GetMenuView(
                                option: CometChatOption(
                                  id: 'studio_info',
                                  title: 'Atelier Studio Directory',
                                  iconWidget: ExcludeSemantics(
                                    child: Icon(
                                      Icons.groups_outlined,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            Wrap(
                              spacing: ShowcaseTokens.spaceSm,
                              runSpacing: ShowcaseTokens.spaceSm,
                              children: <String>['All', 'Unread', 'Media'].map((
                                label,
                              ) {
                                final selected = _selectedFilters.contains(
                                  label,
                                );
                                return SearchFilterChip(
                                  label: label,
                                  icon: label == 'Media'
                                      ? Icons.perm_media_outlined
                                      : Icons.filter_list_rounded,
                                  isSelected: selected,
                                  colorPalette: palette,
                                  spacing: spacing,
                                  typography: typography,
                                  selectedColor: colorScheme.primary,
                                  selectedTextColor: colorScheme.onPrimary,
                                  selectedIconColor: colorScheme.onPrimary,
                                  onTap: () {
                                    setState(() {
                                      if (selected &&
                                          _selectedFilters.length > 1) {
                                        _selectedFilters.remove(label);
                                      } else {
                                        _selectedFilters.add(label);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      _buildShowcaseCard(
                        context,
                        label:
                            'CometChatAttachmentOptionSheet & CometchatMessageOptionSheet',
                        caption:
                            'Action sheets mounted inline and as modal sheets',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              height: 140,
                              child: CometChatAttachmentOptionSheet(
                                actionItems: attachmentActions,
                                style: CometChatAttachmentOptionSheetStyle(
                                  backgroundColor:
                                      colorScheme.surfaceContainerLowest,
                                  titleColor: colorScheme.onSurface,
                                  iconColor: colorScheme.primary,
                                  borderRadius: nestedRadius,
                                ),
                              ),
                            ),
                            const SizedBox(height: ShowcaseTokens.spaceMd),
                            SizedBox(
                              height: 185,
                              child: CometchatMessageOptionSheet(
                                messageObject: sampleTextMessage,
                                actionItems: messageActions,
                                onReactionTap: (_, emoji) {
                                  setState(
                                    () => _lastInteractionNote =
                                        'Quick reaction: ${emoji ?? ''}',
                                  );
                                },
                                messageOptionStyle:
                                    ConvoKitMessageOptionSheetStyle(
                                      backgroundColor:
                                          colorScheme.surfaceContainerLowest,
                                      titleColor: colorScheme.onSurface,
                                      iconColor: colorScheme.primary,
                                      borderRadius: nestedRadius,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollapsingGlassHeader(
              title: 'Updates',
              scrollController: _scrollController,
              actions: widget.headerActions ?? const <GlassHeaderAction>[],
            ),
          ),
        ],
      ),
    );
  }
}
