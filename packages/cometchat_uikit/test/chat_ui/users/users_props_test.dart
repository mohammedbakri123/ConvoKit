import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';

class _FailingUserRepository implements UserRepository {
  @override
  Future<ChatResult<ChatUser>> getUser(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'User fetch failed'));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'List failed'));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  }) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Search failed'));
}

class _EmptyUserRepository implements UserRepository {
  @override
  Future<ChatResult<ChatUser>> getUser(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.notFound, 'Not found'));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> listUsers({
    String? cursor,
    int limit = 30,
  }) async => const ChatSuccess(ChatPage<ChatUser>(items: []));

  @override
  Future<ChatResult<ChatPage<ChatUser>>> searchUsers(
    String query, {
    String? cursor,
    int limit = 30,
  }) async => const ChatSuccess(ChatPage<ChatUser>(items: []));
}

void main() {
  group('ConvoKitUsers (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 5);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(kit: kit, child: child),
      );
    }

    ConvoKit buildKit({
      UserRepository? users,
      bool searchEnabled = true,
    }) {
      return ConvoKit(
        session: fake.session,
        users: users ?? fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities(search: searchEnabled),
      );
    }

    testWidgets('loads users via UserRepository.listUsers and fires onLoad', (
      tester,
    ) async {
      List<ChatUser>? loaded;
      ChatUser? tapped;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitUsers(
            debounceDuration: Duration.zero,
            onLoad: (users) => loaded = users,
            onItemTap: (ctx, user) => tapped = user,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(fake.allUsers.length));
      expect(find.text(fake.user2.name), findsOneWidget);

      await tester.tap(find.text(fake.user2.name));
      await tester.pump();
      expect(tapped?.id, equals(fake.user2.id));
    });

    testWidgets('hides search bar when capabilities.search is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(
          buildKit(searchEnabled: false),
          const ConvoKitUsers(debounceDuration: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text(fake.user1.name), findsOneWidget);
    });

    testWidgets(
      'searches users via UserRepository.searchUsers when capabilities.search is true',
      (tester) async {
        await tester.pumpWidget(
          wrapWithScope(
            buildKit(searchEnabled: true),
            const ConvoKitUsers(debounceDuration: Duration.zero),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), fake.user3.name);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.text(fake.user3.name),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.text(fake.user2.name),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('paginates users across pages with pageLimit', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          const ConvoKitUsers(
            debounceDuration: Duration.zero,
            pageLimit: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(fake.user1.name), findsOneWidget);
      expect(find.text(fake.user2.name), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text(fake.user3.name), findsOneWidget);
    });

    testWidgets('supports selection mode and invokes onSelection', (
      tester,
    ) async {
      List<ChatUser>? selected;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitUsers(
            debounceDuration: Duration.zero,
            selectionMode: SelectionMode.multiple,
            activateSelection: ActivateSelection.onClick,
            onSelection: (users, ctx) => selected = users,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(fake.user2.name));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.map((u) => u.id), equals([fake.user2.id]));
    });

    testWidgets('renders emptyStateView and fires onEmpty when no users', (
      tester,
    ) async {
      var emptyCalled = false;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(users: _EmptyUserRepository()),
          ConvoKitUsers(
            debounceDuration: Duration.zero,
            onEmpty: () => emptyCalled = true,
            emptyStateView: (_) => const Text('No Contacts'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(emptyCalled, isTrue);
      expect(find.text('No Contacts'), findsOneWidget);
    });

    testWidgets('renders errorStateView and fires onError on failure', (
      tester,
    ) async {
      Exception? reported;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(users: _FailingUserRepository()),
          ConvoKitUsers(
            debounceDuration: Duration.zero,
            onError: (e) => reported = e,
            errorStateView: (_) => const Text('Users Error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(find.text('Users Error'), findsOneWidget);
    });

    testWidgets('fetchUser retrieves user via UserRepository.getUser', (
      tester,
    ) async {
      final key = GlobalKey<ConvoKitUsersState>();

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitUsers(
            key: key,
            debounceDuration: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fetched = await key.currentState!.fetchUser(fake.user2.id);
      expect(fetched?.id, equals(fake.user2.id));
    });
  });
}
