import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

class _EmptyConversationRepository implements ConversationRepository {
  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async => const ChatSuccess(ChatPage<ChatConversation>(items: []));

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.notFound, 'Not found'));

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async =>
      ChatResult.ok();

  @override
  Future<ChatResult<void>> deleteConversation(String id) async =>
      ChatResult.ok();
}

class _FailingConversationRepository implements ConversationRepository {
  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Load failed'));

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Load failed'));

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Mark read failed'));

  @override
  Future<ChatResult<void>> deleteConversation(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Delete failed'));
}

void main() {
  group('ConvoKitConversations (ConvoKitScope + FakeChatBackend)', () {
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
      ConversationRepository? conversations,
      bool receipts = true,
      bool search = true,
    }) {
      return ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: conversations ?? fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities(receipts: receipts, search: search),
      );
    }

    testWidgets('loads conversations from EventHub.conversationStore and handles tap', (
      tester,
    ) async {
      List<ChatConversation>? loaded;
      ChatConversation? tapped;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitConversations(
            onLoad: (list) => loaded = list,
            onItemTap: (conv) => tapped = conv,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loaded, isNotNull);
      expect(loaded, isNotEmpty);

      final firstPeerName = loaded!.first.peer?.name ?? loaded!.first.group!.name;
      expect(find.text(firstPeerName), findsWidgets);

      await tester.tap(find.text(firstPeerName).first);
      await tester.pump();
      expect(tapped?.id, loaded!.first.id);
    });

    testWidgets('hides receipt indicators when capabilities.receipts is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithScope(
          buildKit(receipts: false),
          const ConvoKitConversations(receiptsVisibility: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConvoKitReceipt), findsNothing);
    });

    testWidgets('renders empty state view and fires onEmpty', (tester) async {
      var emptyCalled = false;
      await tester.pumpWidget(
        wrapWithScope(
          buildKit(conversations: _EmptyConversationRepository()),
          ConvoKitConversations(
            onEmpty: () => emptyCalled = true,
            emptyStateView: (_) => const Text('No chats yet'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(emptyCalled, isTrue);
      expect(find.text('No chats yet'), findsOneWidget);
    });

    testWidgets('renders error state view and fires onError', (tester) async {
      Exception? captured;
      await tester.pumpWidget(
        wrapWithScope(
          buildKit(conversations: _FailingConversationRepository()),
          ConvoKitConversations(
            onError: (err) => captured = err,
            errorStateView: (_) => const Text('Failed to load chats'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(find.text('Failed to load chats'), findsOneWidget);
    });
  });
}
