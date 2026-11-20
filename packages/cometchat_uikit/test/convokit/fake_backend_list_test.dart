import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:convokit/convokit.dart';

import 'fake_chat_backend.dart';

void main() {
  group('Fake backend list tests (Phase 2)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 105);
    });

    testWidgets('ConversationsView renders list from fake backend', (tester) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const ConversationsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ConversationsView), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    test('Older pagination loads all pages, no duplicates, terminates with null cursor', () async {
      // 105 messages seeded, page size 30
      final allLoaded = <ChatMessage>[];
      final seenIds = <String>{};
      String? cursor;
      bool hasOlder = true;

      while (hasOlder) {
        final result = await fake.messages.fetchMessages(
          'conv_1_2',
          MessagePageRequest(
            limit: 30,
            cursor: cursor,
            direction: MessagePageDirection.older,
          ),
        );

        expect(result.isSuccess, isTrue);
        final page = result.getOrThrow();
        expect(page.items.length, lessThanOrEqualTo(30));

        for (final m in page.items) {
          expect(seenIds.contains(m.id), isFalse, reason: 'Duplicate message id found: ${m.id}');
          seenIds.add(m.id!);
          allLoaded.add(m);
        }

        cursor = page.olderCursor;
        hasOlder = page.hasOlder;
      }

      expect(allLoaded.length, 105);
      expect(hasOlder, isFalse);
      expect(cursor, isNull);
    });

    test('Search users filters by query against fake backend', () async {
      final searchResult = await fake.users.searchUsers('bob');
      expect(searchResult.isSuccess, isTrue);
      final page = searchResult.getOrThrow();
      expect(page.items.length, 1);
      expect(page.items.first.name, 'Bob');

      // Search matching multiple (e.g. 'e' matches Alice, Charlie)
      final multiResult = await fake.users.searchUsers('e');
      expect(multiResult.isSuccess, isTrue);
      final multiPage = multiResult.getOrThrow();
      expect(multiPage.items.any((u) => u.name == 'Alice'), isTrue);
      expect(multiPage.items.any((u) => u.name == 'Charlie'), isTrue);

      // Search matching none
      final emptyResult = await fake.users.searchUsers('nonexistent');
      expect(emptyResult.isSuccess, isTrue);
      expect(emptyResult.getOrThrow().items, isEmpty);
    });

    test('List users with pagination', () async {
      final res = await fake.users.listUsers(limit: 2);
      expect(res.isSuccess, isTrue);
      final page1 = res.getOrThrow();
      expect(page1.items.length, 2);
      expect(page1.hasOlder, isTrue);

      final res2 = await fake.users.listUsers(cursor: page1.olderCursor, limit: 2);
      expect(res2.isSuccess, isTrue);
      final page2 = res2.getOrThrow();
      expect(page2.items.length, 2);
    });

    test('Groups and members render from fake backend', () async {
      final grpRes = await fake.groups.listGroups();
      expect(grpRes.isSuccess, isTrue);
      final groups = grpRes.getOrThrow().items;
      expect(groups.length, 1);
      expect(groups.first.name, 'Core Team');

      final membersRes = await fake.groups.listMembers('group_team');
      expect(membersRes.isSuccess, isTrue);
      final members = membersRes.getOrThrow().items;
      expect(members.length, 3);
      expect(members.any((m) => m.user.name == 'Alice'), isTrue);
    });

    test('Conversations mark as read resets unread count', () async {
      final convRes = await fake.conversations.getConversation('conv_1_2');
      expect(convRes.isSuccess, isTrue);
      expect(convRes.getOrThrow().unreadCount, 2);

      final markRes = await fake.conversations.markAsRead('conv_1_2');
      expect(markRes.isSuccess, isTrue);

      final updatedConv = await fake.conversations.getConversation('conv_1_2');
      expect(updatedConv.getOrThrow().unreadCount, 0);
    });
  });
}
