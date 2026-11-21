import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart'
    show CometChatVoiceNoteBubble, ExtensionType;

/// Immutable snapshot of initial "Atelier Studio" demo data.
///
/// Created fresh on every [StudioSeedData.create] call so backend resets
/// restore deterministic offline state without shared mutable collections.
class StudioSeedSnapshot {
  const StudioSeedSnapshot({
    required this.currentUser,
    required this.users,
    required this.userRoles,
    required this.groups,
    required this.conversations,
    required this.messagesByConversation,
    required this.pinnedByConversation,
    required this.savedMessages,
  });

  final ChatUser currentUser;
  final List<ChatUser> users;
  final Map<String, String> userRoles;
  final List<ChatGroup> groups;
  final List<ChatConversation> conversations;
  final Map<String, List<ChatMessage>> messagesByConversation;
  final Map<String, List<ChatMessage>> pinnedByConversation;
  final List<ChatMessage> savedMessages;
}

/// Offline seed dataset for the fictional "Atelier Studio" team.
///
/// All timestamps are computed dynamically relative to [anchorTime] (defaulting
/// to [DateTime.now]) so conversations always display fresh relative dates.
class StudioSeedData {
  StudioSeedData._();

  /// Dynamic reference timestamp defaulting to the current local time.
  static DateTime get baseTime => DateTime.now();

  // Teammate IDs
  static const String nadiaId = 'user_nadia';
  static const String tariqId = 'user_tariq';
  static const String claireId = 'user_claire';
  static const String kenjiId = 'user_kenji';
  static const String amaraId = 'user_amara';
  static const String mateoId = 'user_mateo';
  static const String priyaId = 'user_priya';
  static const String sorenId = 'user_soren';

  // Group IDs
  static const String designSystemsGroupId = 'grp_design_systems';
  static const String brandRefreshGroupId = 'grp_brand_refresh';
  static const String studioLoungeGroupId = 'grp_studio_lounge';

  // Conversation IDs
  static const String designSystemsConvId = 'conv_grp_design_systems';
  static const String brandRefreshConvId = 'conv_grp_brand_refresh';
  static const String studioLoungeConvId = 'conv_grp_studio_lounge';
  static const String tariqConvId = 'conv_dm_tariq';
  static const String claireConvId = 'conv_dm_claire';
  static const String kenjiConvId = 'conv_dm_kenji';
  static const String amaraConvId = 'conv_dm_amara';
  static const String priyaConvId = 'conv_dm_priya';

  // Notable seeded message IDs (for thread replies, polls, pins, saves)
  static const String designGridParentMsgId = 'msg_ds_001';
  static const String designPollMsgId = 'msg_ds_005';
  static const String brandCardMsgId = 'msg_br_003';
  static const String studioStickerMsgId = 'msg_sl_002';
  static const String tariqVoiceNoteMsgId = 'msg_dm_tariq_003';

  /// Creates a fresh [StudioSeedSnapshot] anchored at [anchorTime] (defaults to
  /// [DateTime.now]).
  static StudioSeedSnapshot create({DateTime? anchorTime}) {
    final anchor = anchorTime ?? DateTime.now();
    DateTime minutesAgo(int minutes) =>
        anchor.subtract(Duration(minutes: minutes));

    // 8 Atelier Studio teammates
    const nadia = ChatUser(
      id: nadiaId,
      name: 'Nadia Haddad',
      presence: UserPresence.online,
    );
    const tariq = ChatUser(
      id: tariqId,
      name: 'Tariq Mansour',
      presence: UserPresence.online,
    );
    const claire = ChatUser(
      id: claireId,
      name: 'Claire Laurent',
      presence: UserPresence.online,
    );
    const kenji = ChatUser(
      id: kenjiId,
      name: 'Kenji Sato',
      presence: UserPresence.away,
    );
    const amara = ChatUser(
      id: amaraId,
      name: 'Amara Okafor',
      presence: UserPresence.online,
    );
    const mateo = ChatUser(
      id: mateoId,
      name: 'Mateo Silva',
      presence: UserPresence.offline,
    );
    const priya = ChatUser(
      id: priyaId,
      name: 'Priya Nair',
      presence: UserPresence.away,
    );
    const soren = ChatUser(
      id: sorenId,
      name: 'Soren Lindqvist',
      presence: UserPresence.offline,
    );

    final users = <ChatUser>[
      nadia,
      tariq,
      claire,
      kenji,
      amara,
      mateo,
      priya,
      soren,
    ];

    final userRoles = <String, String>{
      nadiaId: 'Design Director',
      tariqId: 'Staff Product Designer',
      claireId: 'Brand Lead',
      kenjiId: 'Motion Designer',
      amaraId: 'Design Systems Engineer',
      mateoId: 'UX Researcher',
      priyaId: 'Senior Illustrator',
      sorenId: 'Creative Copywriter',
    };

    // 3 Studio groups
    const designSystemsMembers = <ChatMember>[
      ChatMember(user: nadia, role: GroupRole.owner),
      ChatMember(user: amara, role: GroupRole.admin),
      ChatMember(user: tariq, role: GroupRole.member),
      ChatMember(user: claire, role: GroupRole.member),
      ChatMember(user: kenji, role: GroupRole.member),
      ChatMember(user: mateo, role: GroupRole.member),
    ];
    final designSystemsGroup = ChatGroup(
      id: designSystemsGroupId,
      name: 'Design Systems',
      description: 'Core tokens, component specs, and accessibility audits.',
      type: GroupType.public,
      memberCount: designSystemsMembers.length,
      members: designSystemsMembers,
    );

    const brandRefreshMembers = <ChatMember>[
      ChatMember(user: nadia, role: GroupRole.owner),
      ChatMember(user: claire, role: GroupRole.admin),
      ChatMember(user: priya, role: GroupRole.member),
      ChatMember(user: soren, role: GroupRole.member),
    ];
    final brandRefreshGroup = ChatGroup(
      id: brandRefreshGroupId,
      name: 'Brand Refresh 2026',
      description: 'Private identity sprint for the Q3 Atelier rebrand.',
      type: GroupType.private,
      memberCount: brandRefreshMembers.length,
      members: brandRefreshMembers,
    );

    const studioLoungeMembers = <ChatMember>[
      ChatMember(user: nadia, role: GroupRole.owner),
      ChatMember(user: tariq, role: GroupRole.admin),
      ChatMember(user: claire, role: GroupRole.member),
      ChatMember(user: kenji, role: GroupRole.member),
      ChatMember(user: amara, role: GroupRole.member),
      ChatMember(user: mateo, role: GroupRole.member),
      ChatMember(user: priya, role: GroupRole.member),
      ChatMember(user: soren, role: GroupRole.member),
    ];
    final studioLoungeGroup = ChatGroup(
      id: studioLoungeGroupId,
      name: 'Studio Lounge',
      description: 'All-hands studio banter, Friday demos, and inspiration.',
      type: GroupType.passwordProtected,
      memberCount: studioLoungeMembers.length,
      members: studioLoungeMembers,
    );

    final groups = <ChatGroup>[
      designSystemsGroup,
      brandRefreshGroup,
      studioLoungeGroup,
    ];

    // -------------------------------------------------------------------------
    // Messages — Group 1: Design Systems (12 messages: text, quoted replies,
    // PDF file, image, link preview, poll, voice note)
    // -------------------------------------------------------------------------
    final dsMsg1 = TextMessage(
      id: designGridParentMsgId,
      localId: 'local_ds_001',
      conversationId: designSystemsConvId,
      sender: nadia,
      createdAt: minutesAgo(210),
      serverCreatedAt: minutesAgo(210),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Morning team! Finalizing the 2026 token spec today — please review spacing and elevation before 4 PM.',
    );
    final dsMsg2 = TextMessage(
      id: 'msg_ds_002',
      localId: 'local_ds_002',
      conversationId: designSystemsConvId,
      sender: amara,
      createdAt: minutesAgo(198),
      serverCreatedAt: minutesAgo(198),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: dsMsg1,
      text:
          'Checked contrast ratios on dark surfaces — all primary tokens clear WCAG AA.',
    );
    final dsMsg3 = TextMessage(
      id: 'msg_ds_003',
      localId: 'local_ds_003',
      conversationId: designSystemsConvId,
      sender: tariq,
      createdAt: minutesAgo(186),
      serverCreatedAt: minutesAgo(186),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: dsMsg1,
      text:
          'Added the compact mobile radius tokens to Figma so iOS and Android stay aligned.',
    );
    final dsMsg4 = MediaMessage(
      id: 'msg_ds_004',
      localId: 'local_ds_004',
      conversationId: designSystemsConvId,
      sender: amara,
      createdAt: minutesAgo(142),
      serverCreatedAt: minutesAgo(142),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_ds_spec_pdf',
        remoteId: 'media_ds_spec_pdf',
        kind: AttachmentKind.file,
        url: 'https://atelier.studio/assets/Atelier_Design_Tokens_v4.pdf',
        state: AttachmentState.uploaded,
        mimeType: 'application/pdf',
        sizeBytes: 2480120,
        name: 'Atelier_Design_Tokens_v4.pdf',
      ),
      caption: 'Updated token table & dark-mode parity sheet (v4).',
    );
    final dsMsg7 = TextMessage(
      id: 'msg_ds_007',
      localId: 'local_ds_007',
      conversationId: designSystemsConvId,
      sender: nadia,
      createdAt: minutesAgo(124),
      serverCreatedAt: minutesAgo(124),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: dsMsg4,
      text:
          'Love how clean the surfaceContainer ladder reads in v4 — zero shadow clutter on list rows.',
    );
    final dsMsg8 = TextMessage(
      id: 'msg_ds_008',
      localId: 'local_ds_008',
      conversationId: designSystemsConvId,
      sender: kenji,
      createdAt: minutesAgo(105),
      serverCreatedAt: minutesAgo(105),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Published the 240ms spring curve notes here: https://atelier.studio/specs/liquid-glass-motion',
    );
    final dsMsg9 = MediaMessage(
      id: 'msg_ds_009',
      localId: 'local_ds_009',
      conversationId: designSystemsConvId,
      sender: claire,
      createdAt: minutesAgo(84),
      serverCreatedAt: minutesAgo(84),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_ds_contrast_sheet',
        remoteId: 'media_ds_contrast_sheet',
        kind: AttachmentKind.image,
        url: 'https://atelier.studio/assets/contrast_matrix_2026.png',
        thumbnailUrl:
            'https://atelier.studio/assets/contrast_matrix_2026_thumb.png',
        state: AttachmentState.uploaded,
        mimeType: 'image/png',
        sizeBytes: 940000,
        name: 'contrast_matrix_2026.png',
      ),
      caption: 'Outgoing bubble contrast verification (Light #DCF8C6 & Dark #005C4B).',
    );
    final dsMsg10 = TextMessage(
      id: 'msg_ds_010',
      localId: 'local_ds_010',
      conversationId: designSystemsConvId,
      sender: nadia,
      createdAt: minutesAgo(62),
      serverCreatedAt: minutesAgo(62),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Confirmed! Both outgoing timestamps clear 5.6:1 in Dark and 6.5:1 in Light.',
    );
    final dsMsg11 = MediaMessage(
      id: 'msg_ds_011',
      localId: 'local_ds_011',
      conversationId: designSystemsConvId,
      sender: kenji,
      createdAt: minutesAgo(41),
      serverCreatedAt: minutesAgo(41),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_ds_motion_note',
        remoteId: 'media_ds_motion_note',
        kind: AttachmentKind.audio,
        url: 'https://atelier.studio/assets/audio/kenji_spring_walkthrough.m4a',
        state: AttachmentState.uploaded,
        mimeType: 'audio/m4a',
        sizeBytes: 248000,
        name: 'kenji_spring_walkthrough.m4a',
      ),
      caption: 'Voice note on reduced-motion fallback behavior',
      metadata: const <String, dynamic>{
        CometChatVoiceNoteBubble.audioTypeKey:
            CometChatVoiceNoteBubble.audioTypeVoiceNote,
        'audioDurationMs': 31000,
      },
    );
    final dsMsg5 = CustomMessage(
      id: designPollMsgId,
      localId: 'local_ds_005',
      conversationId: designSystemsConvId,
      sender: nadia,
      createdAt: minutesAgo(26),
      serverCreatedAt: minutesAgo(26),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      kind: ExtensionType.extensionPoll,
      data: <String, dynamic>{
        'question': 'Which grid density should we ship for the Q2 icon set?',
        'total': 3,
        'options': <String, dynamic>{
          '1': <String, dynamic>{
            'text': '4px base (compact)',
            'count': 1,
            'voters': <String, dynamic>{
              tariqId: <String, dynamic>{
                'name': tariq.name,
                'avatar': tariq.avatarUrl,
              },
            },
          },
          '2': <String, dynamic>{
            'text': '8px base (balanced)',
            'count': 2,
            'voters': <String, dynamic>{
              nadiaId: <String, dynamic>{
                'name': nadia.name,
                'avatar': nadia.avatarUrl,
              },
              amaraId: <String, dynamic>{
                'name': amara.name,
                'avatar': amara.avatarUrl,
              },
            },
          },
          '3': <String, dynamic>{
            'text': '12px editorial',
            'count': 0,
            'voters': <String, dynamic>{},
          },
        },
      },
    );
    final dsMsg12 = TextMessage(
      id: 'msg_ds_012',
      localId: 'local_ds_012',
      conversationId: designSystemsConvId,
      sender: amara,
      createdAt: minutesAgo(14),
      serverCreatedAt: minutesAgo(14),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text:
          'Locked the 8-hue monogram palette for avatars too — no more flat mint circles.',
    );
    final dsMsg6 = TextMessage(
      id: 'msg_ds_006',
      localId: 'local_ds_006',
      conversationId: designSystemsConvId,
      sender: mateo,
      createdAt: minutesAgo(6),
      serverCreatedAt: minutesAgo(6),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Usability notes from Tuesday are linked — 8px tested fastest.',
    );

    // -------------------------------------------------------------------------
    // Messages — Group 2: Brand Refresh 2026 (11 messages: text, image, card,
    // quoted reply, PDF file, link preview)
    // -------------------------------------------------------------------------
    final brMsg1 = TextMessage(
      id: 'msg_br_001',
      localId: 'local_br_001',
      conversationId: brandRefreshConvId,
      sender: claire,
      createdAt: minutesAgo(195),
      serverCreatedAt: minutesAgo(195),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Uploaded the terracotta + warm stone palette explorations for the keynote deck.',
    );
    final brMsg5 = TextMessage(
      id: 'msg_br_005',
      localId: 'local_br_005',
      conversationId: brandRefreshConvId,
      sender: nadia,
      createdAt: minutesAgo(178),
      serverCreatedAt: minutesAgo(178),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Terracotta pairs really nicely with our deep forest green primary — feels editorial without losing brand recall.',
    );
    final brMsg2 = MediaMessage(
      id: 'msg_br_002',
      localId: 'local_br_002',
      conversationId: brandRefreshConvId,
      sender: priya,
      createdAt: minutesAgo(152),
      serverCreatedAt: minutesAgo(152),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_br_moodboard',
        remoteId: 'media_br_moodboard',
        kind: AttachmentKind.image,
        url: 'https://atelier.studio/assets/brand_moodboard_2026.png',
        thumbnailUrl:
            'https://atelier.studio/assets/brand_moodboard_2026_thumb.png',
        state: AttachmentState.uploaded,
        mimeType: 'image/png',
        sizeBytes: 1842000,
        name: 'brand_moodboard_2026.png',
      ),
      caption: 'Editorial illustration moodboard — round 3.',
    );
    final brMsg6 = TextMessage(
      id: 'msg_br_006',
      localId: 'local_br_006',
      conversationId: brandRefreshConvId,
      sender: soren,
      createdAt: minutesAgo(134),
      serverCreatedAt: minutesAgo(134),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: brMsg2,
      text:
          'The top-right frame nails the calm warmth we wanted for onboarding.',
    );
    final brMsg7 = TextMessage(
      id: 'msg_br_007',
      localId: 'local_br_007',
      conversationId: brandRefreshConvId,
      sender: claire,
      createdAt: minutesAgo(112),
      serverCreatedAt: minutesAgo(112),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Shared the live keynote prototype link for review: https://atelier.studio/brand/2026-refresh-deck',
    );
    final brMsg8 = TextMessage(
      id: 'msg_br_008',
      localId: 'local_br_008',
      conversationId: brandRefreshConvId,
      sender: nadia,
      createdAt: minutesAgo(92),
      serverCreatedAt: minutesAgo(92),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Walking through slides 4–9 now. Let us keep the hero typography crisp and tight-tracked.',
    );
    final brMsg9 = MediaMessage(
      id: 'msg_br_009',
      localId: 'local_br_009',
      conversationId: brandRefreshConvId,
      sender: claire,
      createdAt: minutesAgo(68),
      serverCreatedAt: minutesAgo(68),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_br_wordmark_pdf',
        remoteId: 'media_br_wordmark_pdf',
        kind: AttachmentKind.file,
        url: 'https://atelier.studio/assets/Atelier_Wordmark_Lockups.pdf',
        state: AttachmentState.uploaded,
        mimeType: 'application/pdf',
        sizeBytes: 3120400,
        name: 'Atelier_Wordmark_Lockups.pdf',
      ),
      caption: 'Final monochrome & dark-surface wordmark lockups.',
    );
    final brMsg3 = CustomMessage(
      id: brandCardMsgId,
      localId: 'local_br_003',
      conversationId: brandRefreshConvId,
      sender: nadia,
      createdAt: minutesAgo(46),
      serverCreatedAt: minutesAgo(46),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      kind: 'card',
      data: <String, dynamic>{
        'fallbackText': 'Brand Refresh 2026 — Sprint 3 Sign-Off',
        'card': <String, dynamic>{
          'title': 'Brand Refresh 2026 — Sprint 3 Sign-Off',
          'body': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'variant': 'heading2',
              'content': 'Brand Refresh 2026',
            },
            <String, dynamic>{
              'type': 'text',
              'content':
                  'Wordmark lockups, editorial serif pairing, and studio palette are ready for leadership review.',
            },
          ],
        },
      },
    );
    final brMsg10 = TextMessage(
      id: 'msg_br_010',
      localId: 'local_br_010',
      conversationId: brandRefreshConvId,
      sender: priya,
      createdAt: minutesAgo(31),
      serverCreatedAt: minutesAgo(31),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text:
          'Exporting the vector icon pack in SVG and Flutter font glyph format next.',
    );
    final brMsg11 = TextMessage(
      id: 'msg_br_011',
      localId: 'local_br_011',
      conversationId: brandRefreshConvId,
      sender: nadia,
      createdAt: minutesAgo(21),
      serverCreatedAt: minutesAgo(21),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Perfect — drop the SVG bundle in the shared folder before standup.',
    );
    final brMsg4 = TextMessage(
      id: 'msg_br_004',
      localId: 'local_br_004',
      conversationId: brandRefreshConvId,
      sender: soren,
      createdAt: minutesAgo(14),
      serverCreatedAt: minutesAgo(14),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Tagline options trimmed to three crisp candidates for Friday.',
    );

    // -------------------------------------------------------------------------
    // Messages — Group 3: Studio Lounge (video, sticker, text)
    // -------------------------------------------------------------------------
    final slMsg1 = MediaMessage(
      id: 'msg_sl_001',
      localId: 'local_sl_001',
      conversationId: studioLoungeConvId,
      sender: kenji,
      createdAt: minutesAgo(95),
      serverCreatedAt: minutesAgo(95),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_sl_motion_reel',
        remoteId: 'media_sl_motion_reel',
        kind: AttachmentKind.video,
        url: 'https://atelier.studio/assets/micro_interactions_reel.mp4',
        thumbnailUrl:
            'https://atelier.studio/assets/micro_interactions_reel_poster.jpg',
        state: AttachmentState.uploaded,
        mimeType: 'video/mp4',
        sizeBytes: 8420000,
        name: 'micro_interactions_reel.mp4',
      ),
      caption: 'Sneak peek of the spring physics for the card transitions.',
    );
    final slMsg2 = CustomMessage(
      id: studioStickerMsgId,
      localId: 'local_sl_002',
      conversationId: studioLoungeConvId,
      sender: priya,
      createdAt: minutesAgo(52),
      serverCreatedAt: minutesAgo(52),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      kind: ExtensionType.sticker,
      data: <String, dynamic>{
        'sticker_url': 'https://atelier.studio/assets/stickers/ship_it.png',
        'sticker_name': 'Ship It Stamp',
      },
    );
    final slMsg3 = TextMessage(
      id: 'msg_sl_003',
      localId: 'local_sl_003',
      conversationId: studioLoungeConvId,
      sender: tariq,
      createdAt: minutesAgo(28),
      serverCreatedAt: minutesAgo(28),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Espresso machine is freshly dialed in — showcase demo at 5 PM!',
    );

    // -------------------------------------------------------------------------
    // Messages — DM 1: Tariq Mansour (11 messages: text, quoted replies,
    // image, link preview, voice note)
    // -------------------------------------------------------------------------
    final tariqMsg1 = TextMessage(
      id: 'msg_dm_tariq_001',
      localId: 'local_dm_tariq_001',
      conversationId: tariqConvId,
      sender: nadia,
      createdAt: minutesAgo(165),
      serverCreatedAt: minutesAgo(165),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Hey Tariq, how did the onboarding prototype feel on iOS?',
    );
    final tariqMsg2 = TextMessage(
      id: 'msg_dm_tariq_002',
      localId: 'local_dm_tariq_002',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(156),
      serverCreatedAt: minutesAgo(156),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: tariqMsg1,
      text:
          'Super smooth — the bottom tab spacing feels right at home on Pro Max.',
    );
    final tariqMsg4 = TextMessage(
      id: 'msg_dm_tariq_004',
      localId: 'local_dm_tariq_004',
      conversationId: tariqConvId,
      sender: nadia,
      createdAt: minutesAgo(140),
      serverCreatedAt: minutesAgo(140),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Did the collapsing large title stay crisp when you flick-scrolled past 44px?',
    );
    final tariqMsg5 = TextMessage(
      id: 'msg_dm_tariq_005',
      localId: 'local_dm_tariq_005',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(126),
      serverCreatedAt: minutesAgo(126),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Yes! Dropping the inner blur on the action capsule once the header bar frosted made it look effortless.',
    );
    final tariqMsg6 = MediaMessage(
      id: 'msg_dm_tariq_006',
      localId: 'local_dm_tariq_006',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(108),
      serverCreatedAt: minutesAgo(108),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_tariq_chat_mock',
        remoteId: 'media_tariq_chat_mock',
        kind: AttachmentKind.image,
        url: 'https://atelier.studio/assets/chat_glass_composer_preview.png',
        thumbnailUrl:
            'https://atelier.studio/assets/chat_glass_composer_preview_thumb.png',
        state: AttachmentState.uploaded,
        mimeType: 'image/png',
        sizeBytes: 1120000,
        name: 'chat_glass_composer_preview.png',
      ),
      caption: 'Floating glass pill composer over the warm light canvas.',
    );
    final tariqMsg7 = TextMessage(
      id: 'msg_dm_tariq_007',
      localId: 'local_dm_tariq_007',
      conversationId: tariqConvId,
      sender: nadia,
      createdAt: minutesAgo(91),
      serverCreatedAt: minutesAgo(91),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: tariqMsg6,
      text:
          'That 28px pill radius with the frosted backdrop looks straight out of 2026.',
    );
    final tariqMsg8 = TextMessage(
      id: 'msg_dm_tariq_008',
      localId: 'local_dm_tariq_008',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(74),
      serverCreatedAt: minutesAgo(74),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Also posted the interactive spec here if you want to share with Amara: https://atelier.studio/prototypes/ios26-tab-capsule',
    );
    final tariqMsg9 = TextMessage(
      id: 'msg_dm_tariq_009',
      localId: 'local_dm_tariq_009',
      conversationId: tariqConvId,
      sender: nadia,
      createdAt: minutesAgo(52),
      serverCreatedAt: minutesAgo(52),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Sent it over. Let us make sure the bubble tails stay subtle — just enough directionality without feeling heavy.',
    );
    final tariqMsg10 = TextMessage(
      id: 'msg_dm_tariq_010',
      localId: 'local_dm_tariq_010',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(34),
      serverCreatedAt: minutesAgo(34),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Agreed — 6px inner tail corner paired with 20px outer corners balances both light and dark canvases.',
    );
    final tariqMsg11 = TextMessage(
      id: 'msg_dm_tariq_011',
      localId: 'local_dm_tariq_011',
      conversationId: tariqConvId,
      sender: nadia,
      createdAt: minutesAgo(19),
      serverCreatedAt: minutesAgo(19),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Awesome. Send me your quick thoughts on the keyboard inset feel?',
    );
    final tariqMsg3 = MediaMessage(
      id: tariqVoiceNoteMsgId,
      localId: 'local_dm_tariq_003',
      conversationId: tariqConvId,
      sender: tariq,
      createdAt: minutesAgo(11),
      serverCreatedAt: minutesAgo(11),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      attachment: const ChatAttachment(
        id: 'att_tariq_voice_note',
        remoteId: 'media_tariq_voice_note',
        kind: AttachmentKind.audio,
        url: 'https://atelier.studio/assets/audio/tariq_critique_note.m4a',
        state: AttachmentState.uploaded,
        mimeType: 'audio/m4a',
        sizeBytes: 312000,
        name: 'tariq_critique_note.m4a',
      ),
      caption: 'Quick voice note on the navigation transitions',
      metadata: const <String, dynamic>{
        CometChatVoiceNoteBubble.audioTypeKey:
            CometChatVoiceNoteBubble.audioTypeVoiceNote,
        'audioDurationMs': 42000,
      },
    );

    // -------------------------------------------------------------------------
    // Messages — DM 2: Claire Laurent (10 messages: text, quoted reply, image,
    // link preview, delivered / read receipts)
    // -------------------------------------------------------------------------
    final claireMsg1 = TextMessage(
      id: 'msg_dm_claire_001',
      localId: 'local_dm_claire_001',
      conversationId: claireConvId,
      sender: claire,
      createdAt: minutesAgo(180),
      serverCreatedAt: minutesAgo(180),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Do you want the print proofs before we lock the Pantone swatches?',
    );
    final claireMsg3 = TextMessage(
      id: 'msg_dm_claire_003',
      localId: 'local_dm_claire_003',
      conversationId: claireConvId,
      sender: nadia,
      createdAt: minutesAgo(162),
      serverCreatedAt: minutesAgo(162),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      repliedTo: claireMsg1,
      text:
          'Definitely — especially the matte uncoated stock for the studio lookbook.',
    );
    final claireMsg4 = MediaMessage(
      id: 'msg_dm_claire_004',
      localId: 'local_dm_claire_004',
      conversationId: claireConvId,
      sender: claire,
      createdAt: minutesAgo(144),
      serverCreatedAt: minutesAgo(144),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      attachment: const ChatAttachment(
        id: 'att_claire_swatches',
        remoteId: 'media_claire_swatches',
        kind: AttachmentKind.image,
        url: 'https://atelier.studio/assets/pantone_swatches_2026.png',
        thumbnailUrl:
            'https://atelier.studio/assets/pantone_swatches_2026_thumb.png',
        state: AttachmentState.uploaded,
        mimeType: 'image/png',
        sizeBytes: 1560000,
        name: 'pantone_swatches_2026.png',
      ),
      caption: 'Daylight test shot of the forest green & warm stone proofs.',
    );
    final claireMsg5 = TextMessage(
      id: 'msg_dm_claire_005',
      localId: 'local_dm_claire_005',
      conversationId: claireConvId,
      sender: nadia,
      createdAt: minutesAgo(120),
      serverCreatedAt: minutesAgo(120),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'The warm stone neutral matches our light chat canvas almost identically!',
    );
    final claireMsg6 = TextMessage(
      id: 'msg_dm_claire_006',
      localId: 'local_dm_claire_006',
      conversationId: claireConvId,
      sender: claire,
      createdAt: minutesAgo(98),
      serverCreatedAt: minutesAgo(98),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Right? I uploaded the full press sheet & color notes here: https://atelier.studio/print/pantone-proofs-2026',
    );
    final claireMsg7 = TextMessage(
      id: 'msg_dm_claire_007',
      localId: 'local_dm_claire_007',
      conversationId: claireConvId,
      sender: nadia,
      createdAt: minutesAgo(76),
      serverCreatedAt: minutesAgo(76),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Did the printer confirm turnaround time if we sign off by Thursday noon?',
    );
    final claireMsg8 = TextMessage(
      id: 'msg_dm_claire_008',
      localId: 'local_dm_claire_008',
      conversationId: claireConvId,
      sender: claire,
      createdAt: minutesAgo(58),
      serverCreatedAt: minutesAgo(58),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Yes — 48-hour courier delivery to the studio, so we have them well ahead of Monday.',
    );
    final claireMsg9 = TextMessage(
      id: 'msg_dm_claire_009',
      localId: 'local_dm_claire_009',
      conversationId: claireConvId,
      sender: nadia,
      createdAt: minutesAgo(42),
      serverCreatedAt: minutesAgo(42),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Great. Let us also double-check the foil embossing margin on the cover.',
    );
    final claireMsg10 = TextMessage(
      id: 'msg_dm_claire_010',
      localId: 'local_dm_claire_010',
      conversationId: claireConvId,
      sender: claire,
      createdAt: minutesAgo(30),
      serverCreatedAt: minutesAgo(30),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text:
          'Already bumped it to 18mm safe margin — bringing both physical mockups over shortly.',
    );
    final claireMsg2 = TextMessage(
      id: 'msg_dm_claire_002',
      localId: 'local_dm_claire_002',
      conversationId: claireConvId,
      sender: nadia,
      createdAt: minutesAgo(22),
      serverCreatedAt: minutesAgo(22),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Yes please — drop them on my desk after standup.',
    );

    // -------------------------------------------------------------------------
    // Messages — DM 3: Kenji Sato (sent with DeliveryState.none)
    // -------------------------------------------------------------------------
    final kenjiMsg1 = TextMessage(
      id: 'msg_dm_kenji_001',
      localId: 'local_dm_kenji_001',
      conversationId: kenjiConvId,
      sender: kenji,
      createdAt: minutesAgo(110),
      serverCreatedAt: minutesAgo(110),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Exported the 60fps Lottie curves for the composer waveform.',
    );
    final kenjiMsg2 = TextMessage(
      id: 'msg_dm_kenji_002',
      localId: 'local_dm_kenji_002',
      conversationId: kenjiConvId,
      sender: nadia,
      createdAt: minutesAgo(35),
      serverCreatedAt: minutesAgo(35),
      sendState: SendState.sent,
      deliveryState: DeliveryState.none,
      text: 'Awesome — I will test them on Android once you are back online.',
    );

    // -------------------------------------------------------------------------
    // Messages — DM 4: Amara Okafor (delivered outgoing)
    // -------------------------------------------------------------------------
    final amaraMsg1 = TextMessage(
      id: 'msg_dm_amara_001',
      localId: 'local_dm_amara_001',
      conversationId: amaraConvId,
      sender: amara,
      createdAt: minutesAgo(180),
      serverCreatedAt: minutesAgo(180),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Zero SDK imports confirmed in the ConvoKit package checks.',
    );
    final amaraMsg2 = TextMessage(
      id: 'msg_dm_amara_002',
      localId: 'local_dm_amara_002',
      conversationId: amaraConvId,
      sender: nadia,
      createdAt: minutesAgo(48),
      serverCreatedAt: minutesAgo(48),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Clean work! Ready to wire the showcase app next.',
    );

    // -------------------------------------------------------------------------
    // Messages — DM 5: Priya Nair (unread incoming)
    // -------------------------------------------------------------------------
    final priyaMsg1 = TextMessage(
      id: 'msg_dm_priya_001',
      localId: 'local_dm_priya_001',
      conversationId: priyaConvId,
      sender: priya,
      createdAt: minutesAgo(90),
      serverCreatedAt: minutesAgo(90),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'Sketched four empty-state spot illustrations for the studio app.',
    );
    final priyaMsg2 = TextMessage(
      id: 'msg_dm_priya_002',
      localId: 'local_dm_priya_002',
      conversationId: priyaConvId,
      sender: priya,
      createdAt: minutesAgo(4),
      serverCreatedAt: minutesAgo(4),
      sendState: SendState.sent,
      deliveryState: DeliveryState.delivered,
      text: 'Can we review the color balance together before lunch?',
    );

    final messagesByConversation = <String, List<ChatMessage>>{
      designSystemsConvId: <ChatMessage>[
        dsMsg1,
        dsMsg2,
        dsMsg3,
        dsMsg4,
        dsMsg7,
        dsMsg8,
        dsMsg9,
        dsMsg10,
        dsMsg11,
        dsMsg5,
        dsMsg12,
        dsMsg6,
      ],
      brandRefreshConvId: <ChatMessage>[
        brMsg1,
        brMsg5,
        brMsg2,
        brMsg6,
        brMsg7,
        brMsg8,
        brMsg9,
        brMsg3,
        brMsg10,
        brMsg11,
        brMsg4,
      ],
      studioLoungeConvId: <ChatMessage>[slMsg1, slMsg2, slMsg3],
      tariqConvId: <ChatMessage>[
        tariqMsg1,
        tariqMsg2,
        tariqMsg4,
        tariqMsg5,
        tariqMsg6,
        tariqMsg7,
        tariqMsg8,
        tariqMsg9,
        tariqMsg10,
        tariqMsg11,
        tariqMsg3,
      ],
      claireConvId: <ChatMessage>[
        claireMsg1,
        claireMsg3,
        claireMsg4,
        claireMsg5,
        claireMsg6,
        claireMsg7,
        claireMsg8,
        claireMsg9,
        claireMsg10,
        claireMsg2,
      ],
      kenjiConvId: <ChatMessage>[kenjiMsg1, kenjiMsg2],
      amaraConvId: <ChatMessage>[amaraMsg1, amaraMsg2],
      priyaConvId: <ChatMessage>[priyaMsg1, priyaMsg2],
    };

    // 8 Seeded Conversations (5 direct + 3 group), sorted newest first
    final conversations = <ChatConversation>[
      ChatConversation.direct(
        id: priyaConvId,
        peer: priya,
        lastMessage: priyaMsg2,
        unreadCount: 1,
        updatedAt: priyaMsg2.serverCreatedAt ?? priyaMsg2.createdAt,
      ),
      ChatConversation.group(
        id: designSystemsConvId,
        group: designSystemsGroup,
        lastMessage: dsMsg6,
        unreadCount: 2,
        updatedAt: dsMsg6.serverCreatedAt ?? dsMsg6.createdAt,
      ),
      ChatConversation.direct(
        id: tariqConvId,
        peer: tariq,
        lastMessage: tariqMsg3,
        unreadCount: 1,
        updatedAt: tariqMsg3.serverCreatedAt ?? tariqMsg3.createdAt,
      ),
      ChatConversation.group(
        id: brandRefreshConvId,
        group: brandRefreshGroup,
        lastMessage: brMsg4,
        unreadCount: 3,
        updatedAt: brMsg4.serverCreatedAt ?? brMsg4.createdAt,
      ),
      ChatConversation.direct(
        id: claireConvId,
        peer: claire,
        lastMessage: claireMsg2,
        unreadCount: 0,
        updatedAt: claireMsg2.serverCreatedAt ?? claireMsg2.createdAt,
      ),
      ChatConversation.group(
        id: studioLoungeConvId,
        group: studioLoungeGroup,
        lastMessage: slMsg3,
        unreadCount: 5,
        updatedAt: slMsg3.serverCreatedAt ?? slMsg3.createdAt,
      ),
      ChatConversation.direct(
        id: kenjiConvId,
        peer: kenji,
        lastMessage: kenjiMsg2,
        unreadCount: 0,
        updatedAt: kenjiMsg2.serverCreatedAt ?? kenjiMsg2.createdAt,
      ),
      ChatConversation.direct(
        id: amaraConvId,
        peer: amara,
        lastMessage: amaraMsg2,
        unreadCount: 0,
        updatedAt: amaraMsg2.serverCreatedAt ?? amaraMsg2.createdAt,
      ),
    ];

    final pinnedByConversation = <String, List<ChatMessage>>{
      designSystemsConvId: <ChatMessage>[dsMsg1, dsMsg4],
      brandRefreshConvId: <ChatMessage>[brMsg3],
      studioLoungeConvId: <ChatMessage>[slMsg1],
      tariqConvId: <ChatMessage>[tariqMsg3],
    };

    final savedMessages = <ChatMessage>[
      dsMsg4,
      brMsg3,
      tariqMsg3,
      amaraMsg1,
    ];

    return StudioSeedSnapshot(
      currentUser: nadia,
      users: users,
      userRoles: userRoles,
      groups: groups,
      conversations: conversations,
      messagesByConversation: messagesByConversation,
      pinnedByConversation: pinnedByConversation,
      savedMessages: savedMessages,
    );
  }
}
