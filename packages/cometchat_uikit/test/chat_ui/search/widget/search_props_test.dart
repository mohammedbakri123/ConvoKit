import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

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

void main() {
  group('CometChatSearch (ConvoKitScope + FakeChatBackend)', () {
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

    testWidgets('hides search UI when capabilities.search is false', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(search: false),
      );

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          const CometChatSearch(debounceDuration: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
      'searches users via UserRepository.searchUsers and invokes callbacks',
      (tester) async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(search: true),
        );

        List<ChatUser>? loaded;
        ChatUser? tapped;

        await tester.pumpWidget(
          wrapWithScope(
            kit,
            CometChatSearch(
              debounceDuration: Duration.zero,
              onUsersLoad: (users) => loaded = users,
              onUserClicked: (user) => tapped = user,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), fake.user2.name);
        await tester.pumpAndSettle();

        expect(loaded, isNotNull);
        expect(loaded!.any((u) => u.id == fake.user2.id), isTrue);
        final userRow = find.descendant(
          of: find.byType(ListView),
          matching: find.text(fake.user2.name),
        );
        expect(userRow, findsOneWidget);

        await tester.tap(userRow);
        await tester.pump();
        expect(tapped?.id, equals(fake.user2.id));
      },
    );

    testWidgets('renders emptyStateView and fires onEmpty when no users match', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(search: true),
      );

      var emptyCalled = false;

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          CometChatSearch(
            debounceDuration: Duration.zero,
            onEmpty: () => emptyCalled = true,
            emptyStateView: (_) => const Text('Custom Empty Search'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz_no_such_user_999');
      await tester.pumpAndSettle();

      expect(emptyCalled, isTrue);
      expect(find.text('Custom Empty Search'), findsOneWidget);
    });

    testWidgets('renders errorStateView and fires onError on repository failure', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: _FailingUserRepository(),
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(search: true),
      );

      Exception? reportedError;

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          CometChatSearch(
            debounceDuration: Duration.zero,
            onError: (e) => reportedError = e,
            errorStateView: (_) => const Text('Custom Search Error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pumpAndSettle();

      expect(reportedError, isNotNull);
      expect(find.text('Custom Search Error'), findsOneWidget);
    });

    testWidgets('clear button resets search back to initialStateView', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: const ChatCapabilities(search: true),
      );

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          CometChatSearch(
            debounceDuration: Duration.zero,
            initialStateView: (_) => const Text('Initial Search State'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial Search State'), findsOneWidget);

      await tester.enterText(find.byType(TextField), fake.user2.name);
      await tester.pumpAndSettle();
      expect(find.text('Initial Search State'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Initial Search State'), findsOneWidget);
    });
  });
}
