import 'dart:typed_data';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart'
    show CometChatVoiceNoteBubble, ExtensionType;
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/backend/studio_backend.dart';
import 'package:showcase_app/backend/studio_seed_data.dart';

void main() {
  group('StudioBackend & ConvoKit constructor validation', () {
    test('assembles all 7 contracts with ChatCapabilities.basic()', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      expect(backend.kit.session, same(backend.session));
      expect(backend.kit.users, same(backend.users));
      expect(backend.kit.conversations, same(backend.conversations));
      expect(backend.kit.messages, same(backend.messages));
      expect(backend.kit.events, same(backend.events));
      expect(backend.kit.groups, same(backend.groups));
      expect(backend.kit.media, same(backend.media));
      expect(backend.kit.capabilities, equals(ChatCapabilities.basic()));
      expect(backend.session.currentUser?.id, StudioSeedData.nadiaId);
      expect(backend.session.currentUser?.name, 'Nadia Haddad');
    });

    test('ConvoKit constructor enforces capability/provider alignment', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      // capabilities.groups == true but groups == null -> ArgumentError
      expect(
        () => ConvoKit(
          session: backend.session,
          users: backend.users,
          conversations: backend.conversations,
          messages: backend.messages,
          events: backend.events,
          capabilities: const ChatCapabilities(groups: true),
        ),
        throwsArgumentError,
      );

      // capabilities.groups == false but groups != null -> ArgumentError
      expect(
        () => ConvoKit(
          session: backend.session,
          users: backend.users,
          conversations: backend.conversations,
          messages: backend.messages,
          events: backend.events,
          groups: backend.groups,
          capabilities: const ChatCapabilities(groups: false),
        ),
        throwsArgumentError,
      );

      // capabilities.media == true but media == null -> ArgumentError
      expect(
        () => ConvoKit(
          session: backend.session,
          users: backend.users,
          conversations: backend.conversations,
          messages: backend.messages,
          events: backend.events,
          capabilities: const ChatCapabilities(media: true),
        ),
        throwsArgumentError,
      );

      // capabilities.mediaDelete == true but media == null -> ArgumentError
      expect(
        () => ConvoKit(
          session: backend.session,
          users: backend.users,
          conversations: backend.conversations,
          messages: backend.messages,
          events: backend.events,
          capabilities: const ChatCapabilities(mediaDelete: true),
        ),
        throwsArgumentError,
      );
    });
  });

  group('StudioSeedData richness', () {
    test('seeds 8 teammates, 3 groups, 8 conversations, and rich messages', () {
      final snapshot = StudioSeedData.create();

      expect(snapshot.users.length, 8);
      expect(snapshot.currentUser.id, StudioSeedData.nadiaId);
      expect(snapshot.groups.length, 3);
      expect(snapshot.conversations.length, 8);

      final directCount = snapshot.conversations
          .where((c) => c.type == ChatConversationType.direct)
          .length;
      final groupCount = snapshot.conversations
          .where((c) => c.type == ChatConversationType.group)
          .length;
      expect(directCount, 5);
      expect(groupCount, 3);

      // Group types and member counts
      final ds = snapshot.groups.firstWhere(
        (g) => g.id == StudioSeedData.designSystemsGroupId,
      );
      final br = snapshot.groups.firstWhere(
        (g) => g.id == StudioSeedData.brandRefreshGroupId,
      );
      final sl = snapshot.groups.firstWhere(
        (g) => g.id == StudioSeedData.studioLoungeGroupId,
      );
      expect(ds.type, GroupType.public);
      expect(ds.memberCount, 6);
      expect(br.type, GroupType.private);
      expect(br.memberCount, 4);
      expect(sl.type, GroupType.passwordProtected);
      expect(sl.memberCount, 8);

      // Rich message types across conversations
      final allMessages = snapshot.messagesByConversation.values
          .expand((list) => list)
          .toList();
      expect(allMessages.whereType<TextMessage>(), isNotEmpty);
      expect(allMessages.where((m) => m.repliedTo != null), isNotEmpty);

      final mediaMessages = allMessages.whereType<MediaMessage>().toList();
      expect(
        mediaMessages.any((m) => m.attachment.kind == AttachmentKind.image),
        isTrue,
      );
      expect(
        mediaMessages.any((m) => m.attachment.kind == AttachmentKind.video),
        isTrue,
      );
      expect(
        mediaMessages.any((m) => m.attachment.kind == AttachmentKind.file),
        isTrue,
      );
      expect(
        mediaMessages.any(CometChatVoiceNoteBubble.isVoiceNote),
        isTrue,
      );

      final customMessages = allMessages.whereType<CustomMessage>().toList();
      expect(
        customMessages.any((m) => m.kind == ExtensionType.extensionPoll),
        isTrue,
      );
      expect(
        customMessages.any((m) => m.kind == ExtensionType.sticker),
        isTrue,
      );
      expect(customMessages.any((m) => m.kind == 'card'), isTrue);

      expect(snapshot.pinnedByConversation.values.expand((l) => l), isNotEmpty);
      expect(snapshot.savedMessages, isNotEmpty);
    });

    test('anchors timestamps dynamically and seeds 10-14 messages in primary chats', () {
      final customAnchor = DateTime.utc(2026, 11, 21, 18, 0);
      final anchored = StudioSeedData.create(anchorTime: customAnchor);

      for (final convId in const <String>[
        StudioSeedData.designSystemsConvId,
        StudioSeedData.tariqConvId,
        StudioSeedData.brandRefreshConvId,
        StudioSeedData.claireConvId,
      ]) {
        final msgs = anchored.messagesByConversation[convId]!;
        expect(msgs.length, inInclusiveRange(10, 14));
        for (final msg in msgs) {
          expect(msg.createdAt.isBefore(customAnchor), isTrue);
          expect(
            customAnchor.difference(msg.createdAt),
            lessThan(const Duration(hours: 6)),
          );
        }
      }
    });
  });

  group('StudioSession & StudioEventSource', () {
    test('broadcasts user switches, sign-out, and reset', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final emitted = <ChatUser?>[];
      final sub = backend.session.currentUserStream.listen(emitted.add);
      addTearDown(sub.cancel);

      final tariq = (await backend.users.getUser(StudioSeedData.tariqId))
          as ChatSuccess<ChatUser>;
      backend.session.switchUser(tariq.value);
      backend.session.signOut();
      backend.reset();

      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 3);
      expect(emitted[0]?.id, StudioSeedData.tariqId);
      expect(emitted[1], isNull);
      expect(emitted[2]?.id, StudioSeedData.nadiaId);
    });

    test('transitions connection state and emits domain events', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final statuses = <ConnectionState>[];
      final events = <ChatEvent>[];
      final statusSub = backend.events.connectionState.listen(
        (s) => statuses.add(s.state),
      );
      final eventSub = backend.events.events.listen(events.add);
      addTearDown(statusSub.cancel);
      addTearDown(eventSub.cancel);

      final connectRes = await backend.events.connect();
      expect(connectRes.isSuccess, isTrue);
      expect(backend.events.isConnected, isTrue);

      final reconnectRes = await backend.events.reconnect();
      expect(reconnectRes.isSuccess, isTrue);

      final disconnectRes = await backend.events.disconnect();
      expect(disconnectRes.isSuccess, isTrue);
      expect(backend.events.isConnected, isFalse);

      backend.users.updatePresence(StudioSeedData.kenjiId, UserPresence.online);
      await backend.messages.sendTyping(StudioSeedData.tariqConvId, true);

      await Future<void>.delayed(Duration.zero);
      expect(
        statuses,
        containsAllInOrder(<ConnectionState>[
          ConnectionState.connecting,
          ConnectionState.connected,
          ConnectionState.disconnected,
          ConnectionState.connecting,
          ConnectionState.connected,
          ConnectionState.disconnected,
        ]),
      );
      expect(events.whereType<PresenceChanged>().length, 1);
      expect(events.whereType<TypingChanged>().length, 1);
    });
  });

  group('StudioUserRepository', () {
    test('paginates deterministically and searches case-insensitively', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final page1Res =
          await backend.users.listUsers(limit: 3)
              as ChatSuccess<ChatPage<ChatUser>>;
      expect(page1Res.value.items.length, 3);
      expect(page1Res.value.hasOlder, isTrue);

      final page2Res =
          await backend.users.listUsers(
                cursor: page1Res.value.olderCursor,
                limit: 3,
              )
              as ChatSuccess<ChatPage<ChatUser>>;
      expect(page2Res.value.items.length, 3);
      expect(page2Res.value.hasOlder, isTrue);

      final page3Res =
          await backend.users.listUsers(
                cursor: page2Res.value.olderCursor,
                limit: 3,
              )
              as ChatSuccess<ChatPage<ChatUser>>;
      expect(page3Res.value.items.length, 2);
      expect(page3Res.value.hasOlder, isFalse);

      final searchRes =
          await backend.users.searchUsers('LAURENT')
              as ChatSuccess<ChatPage<ChatUser>>;
      expect(searchRes.value.items.length, 1);
      expect(searchRes.value.items.first.id, StudioSeedData.claireId);

      final missingRes = await backend.users.getUser('user_missing');
      expect(missingRes.isFailure, isTrue);
      expect(
        (missingRes as ChatFailure<ChatUser>).error.code,
        ChatErrorCode.notFound,
      );
    });
  });

  group('StudioConversationRepository', () {
    test('paginates, marks as read, and deletes conversations', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final page1 =
          await backend.conversations.listConversations(limit: 5)
              as ChatSuccess<ChatPage<ChatConversation>>;
      expect(page1.value.items.length, 5);
      expect(page1.value.hasOlder, isTrue);

      final page2 =
          await backend.conversations.listConversations(
                cursor: page1.value.olderCursor,
                limit: 5,
              )
              as ChatSuccess<ChatPage<ChatConversation>>;
      expect(page2.value.items.length, 3);
      expect(page2.value.hasOlder, isFalse);

      final markRes = await backend.conversations.markAsRead(
        StudioSeedData.designSystemsConvId,
      );
      expect(markRes.isSuccess, isTrue);
      final updated =
          await backend.conversations.getConversation(
                StudioSeedData.designSystemsConvId,
              )
              as ChatSuccess<ChatConversation>;
      expect(updated.value.unreadCount, 0);

      final deleteRes = await backend.conversations.deleteConversation(
        StudioSeedData.amaraConvId,
      );
      expect(deleteRes.isSuccess, isTrue);
      final afterDelete = await backend.conversations.getConversation(
        StudioSeedData.amaraConvId,
      );
      expect(afterDelete.isFailure, isTrue);
    });
  });

  group('StudioMessageRepository', () {
    test('supports directional latest/older/newer pagination', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final latestRes =
          await backend.messages.fetchMessages(
                StudioSeedData.designSystemsConvId,
                const MessagePageRequest(
                  direction: MessagePageDirection.latest,
                  limit: 2,
                ),
              )
              as ChatSuccess<ChatPage<ChatMessage>>;
      expect(latestRes.value.items.length, 2);
      expect(latestRes.value.hasOlder, isTrue);
      expect(latestRes.value.hasNewer, isFalse);
      expect(latestRes.value.newerCheckpoint, isNotNull);

      final olderRes =
          await backend.messages.fetchMessages(
                StudioSeedData.designSystemsConvId,
                MessagePageRequest(
                  direction: MessagePageDirection.older,
                  cursor: latestRes.value.olderCursor,
                  limit: 2,
                ),
              )
              as ChatSuccess<ChatPage<ChatMessage>>;
      expect(olderRes.value.items.length, 2);
      expect(olderRes.value.hasOlder, isTrue);
      expect(olderRes.value.hasNewer, isTrue);

      // Send a new message and catch up via newerCheckpoint
      final pending = TextMessage(
        localId: 'local_catchup_1',
        conversationId: StudioSeedData.designSystemsConvId,
        sender: backend.session.currentUser!,
        createdAt: DateTime.now().toUtc(),
        text: 'Catch-up verification message',
      );
      await backend.messages.sendMessage(pending);

      final newerRes =
          await backend.messages.fetchMessages(
                StudioSeedData.designSystemsConvId,
                MessagePageRequest(
                  direction: MessagePageDirection.newer,
                  cursor: latestRes.value.newerCheckpoint,
                  limit: 10,
                ),
              )
              as ChatSuccess<ChatPage<ChatMessage>>;
      expect(newerRes.value.items.length, 1);
      expect(newerRes.value.items.first.localId, 'local_catchup_1');
    });

    test(
      'enforces idempotent localId send, syncs conversation, and emits echo + delivered/read receipts',
      () async {
        final backend = StudioBackend.create(
          deliveredReceiptDelay: const Duration(milliseconds: 15),
          readReceiptDelay: const Duration(milliseconds: 35),
        );
        addTearDown(backend.dispose);

        final receivedEvents = <ChatEvent>[];
        final sub = backend.events.events.listen(receivedEvents.add);
        addTearDown(sub.cancel);

        final pending = TextMessage(
          localId: 'local_idempotent_42',
          conversationId: StudioSeedData.tariqConvId,
          sender: backend.session.currentUser!,
          createdAt: DateTime.now().toUtc(),
          text: 'Shipping S1 offline backend today!',
        );

        final firstRes =
            await backend.messages.sendMessage(pending)
                as ChatSuccess<ChatMessage>;
        final retryRes =
            await backend.messages.sendMessage(pending)
                as ChatSuccess<ChatMessage>;

        // Idempotency: exact same server ID and no duplicate message
        expect(firstRes.value.id, isNotNull);
        expect(retryRes.value.id, firstRes.value.id);
        expect(firstRes.value.sendState, SendState.sent);

        // Conversation lastMessage synced
        final convRes =
            await backend.conversations.getConversation(
                  StudioSeedData.tariqConvId,
                )
                as ChatSuccess<ChatConversation>;
        expect(convRes.value.lastMessage?.id, firstRes.value.id);

        // Wait for delayed delivered -> read status transitions
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final echoes = receivedEvents
            .whereType<MessageReceived>()
            .where((e) => e.message.localId == 'local_idempotent_42')
            .toList();
        expect(echoes.length, 1);

        final statusEvents = receivedEvents
            .whereType<MessageStatusChanged>()
            .where((e) => e.messageId == firstRes.value.id)
            .map((e) => e.deliveryState)
            .toList();
        expect(
          statusEvents,
          equals(<DeliveryState>[DeliveryState.delivered, DeliveryState.read]),
        );
      },
    );

    test('supports thread replies, poll voting, and message deletion', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final replies = backend.messages.getThreadReplies(
        StudioSeedData.designSystemsConvId,
        StudioSeedData.designGridParentMsgId,
      );
      expect(replies.length, 2);

      // Vote in-memory on the seeded poll (Nadia switches from option 2 -> 3)
      final voteRes =
          backend.messages.votePoll(
                pollMessageId: StudioSeedData.designPollMsgId,
                optionId: '3',
                voter: backend.session.currentUser!,
              )
              as ChatSuccess<CustomMessage>;
      final options = voteRes.value.data['options'] as Map<String, dynamic>;
      expect((options['2'] as Map<String, dynamic>)['count'], 1);
      expect((options['3'] as Map<String, dynamic>)['count'], 1);
      expect(voteRes.value.data['total'], 3);

      // Delete a message and verify MessageDeleted event
      final deletedEvents = <MessageDeleted>[];
      final sub = backend.events.events
          .where((e) => e is MessageDeleted)
          .cast<MessageDeleted>()
          .listen(deletedEvents.add);
      addTearDown(sub.cancel);

      final delRes = await backend.messages.deleteMessage(
        StudioSeedData.studioStickerMsgId,
      );
      expect(delRes.isSuccess, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(deletedEvents.length, 1);
      expect(deletedEvents.first.messageId, StudioSeedData.studioStickerMsgId);
    });
  });

  group('StudioGroupRepository', () {
    test('lists groups/members and supports leave, join, add, remove', () async {
      final backend = StudioBackend.create();
      addTearDown(backend.dispose);

      final groupsRes =
          await backend.groups.listGroups() as ChatSuccess<ChatPage<ChatGroup>>;
      expect(groupsRes.value.items.length, 3);

      final membersRes =
          await backend.groups.listMembers(StudioSeedData.brandRefreshGroupId)
              as ChatSuccess<ChatPage<ChatMember>>;
      expect(membersRes.value.items.length, 4);

      // Add Tariq to Brand Refresh 2026
      final addRes = await backend.groups.addMembers(
        StudioSeedData.brandRefreshGroupId,
        const <String>[StudioSeedData.tariqId],
      );
      expect(addRes.isSuccess, isTrue);

      final afterAdd =
          await backend.groups.getGroup(StudioSeedData.brandRefreshGroupId)
              as ChatSuccess<ChatGroup>;
      expect(afterAdd.value.memberCount, 5);

      // Remove Tariq
      final removeRes = await backend.groups.removeMember(
        StudioSeedData.brandRefreshGroupId,
        StudioSeedData.tariqId,
      );
      expect(removeRes.isSuccess, isTrue);

      // Leave and rejoin as current user (Nadia)
      final leaveRes = await backend.groups.leaveGroup(
        StudioSeedData.brandRefreshGroupId,
      );
      expect(leaveRes.isSuccess, isTrue);
      final afterLeave =
          await backend.groups.getGroup(StudioSeedData.brandRefreshGroupId)
              as ChatSuccess<ChatGroup>;
      expect(afterLeave.value.memberCount, 3);

      final joinRes = await backend.groups.joinGroup(
        StudioSeedData.brandRefreshGroupId,
      );
      expect(joinRes.isSuccess, isTrue);
      final afterJoin =
          await backend.groups.getGroup(StudioSeedData.brandRefreshGroupId)
              as ChatSuccess<ChatGroup>;
      expect(afterJoin.value.memberCount, 4);
    });
  });

  group('StudioMediaProvider', () {
    test('uploads with progress callbacks and supports delete', () async {
      final backend = StudioBackend.create(
        mediaUploadStepDelay: const Duration(milliseconds: 5),
        mediaUploadProgressSteps: 4,
      );
      addTearDown(backend.dispose);

      final fractions = <double>[];
      final uploadRes =
          await backend.media.upload(
                UploadRequest.bytes(
                  Uint8List.fromList(List<int>.filled(400, 7)),
                  kind: AttachmentKind.image,
                  mimeType: 'image/png',
                  name: 'wireframe.png',
                ),
                onProgress: (p) => fractions.add(p.fraction),
              )
              as ChatSuccess<UploadedMedia>;

      expect(fractions.length, 4);
      expect(fractions.first, greaterThan(0));
      expect(fractions.last, 1.0);
      expect(uploadRes.value.id, isNotEmpty);
      expect(uploadRes.value.url, contains('wireframe.png'));
      expect(uploadRes.value.sizeBytes, 400);

      final deleteRes = await backend.media.delete(uploadRes.value.id);
      expect(deleteRes.isSuccess, isTrue);

      final secondDelete = await backend.media.delete(uploadRes.value.id);
      expect(secondDelete.isFailure, isTrue);
      expect(
        (secondDelete as ChatFailure<void>).error.code,
        ChatErrorCode.notFound,
      );
    });

    test('honors CancellationToken mid-upload without throwing', () async {
      final backend = StudioBackend.create(
        mediaUploadStepDelay: const Duration(milliseconds: 10),
        mediaUploadProgressSteps: 5,
      );
      addTearDown(backend.dispose);

      final token = CancellationToken();
      var callbacks = 0;

      final result = await backend.media.upload(
        UploadRequest.file(
          '/tmp/studio_deck.pdf',
          kind: AttachmentKind.file,
          mimeType: 'application/pdf',
          name: 'studio_deck.pdf',
        ),
        cancel: token,
        onProgress: (_) {
          callbacks++;
          if (callbacks == 2) {
            token.cancel();
          }
        },
      );

      expect(result.isFailure, isTrue);
      expect(
        (result as ChatFailure<UploadedMedia>).error.code,
        ChatErrorCode.cancelled,
      );
      expect(callbacks, 2);
    });
  });
}
