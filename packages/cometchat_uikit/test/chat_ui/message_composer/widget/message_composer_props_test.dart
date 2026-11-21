import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';
import '../../../helpers/fake_media_provider.dart';

class _RecordingMessageRepository implements MessageRepository {
  _RecordingMessageRepository(this._inner);
  final MessageRepository _inner;
  final List<(String conversationId, bool isTyping)> typingCalls = [];

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) => _inner.fetchMessages(conversationId, request);

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) =>
      _inner.sendMessage(message);

  @override
  Future<ChatResult<void>> deleteMessage(String messageId) =>
      _inner.deleteMessage(messageId);

  @override
  Future<ChatResult<void>> markAsDelivered(String messageId) =>
      _inner.markAsDelivered(messageId);

  @override
  Future<ChatResult<void>> markAsRead(String messageId) =>
      _inner.markAsRead(messageId);

  @override
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping) {
    typingCalls.add((conversationId, isTyping));
    return _inner.sendTyping(conversationId, isTyping);
  }
}

void main() {
  Widget pumpHarness({
    required ConvoKit kit,
    required Widget child,
  }) {
    return ConvoKitScope(
      kit: kit,
      child: MaterialApp(
        localizationsDelegates: const [Translations.delegate],
        home: Scaffold(body: child),
      ),
    );
  }

  group('ConvoKitMessageComposer (ConvoKitScope + FakeChatBackend)', () {
    testWidgets('sends text via MessageCoordinator.sendTextMessage', (
      tester,
    ) async {
      final backend = FakeChatBackend(seededMessageCount: 2);
      final kit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: ChatCapabilities.basic(),
        groups: backend.groups,
        media: backend.media,
      );

      ChatMessage? sentCallbackMessage;
      await tester.pumpWidget(
        pumpHarness(
          kit: kit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
            onSendButtonTap: (_, msg, _) => sentCallbackMessage = msg,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello ConvoKit');
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pumpAndSettle();

      expect(backend.sendCallCount, 1);
      expect(sentCallbackMessage, isA<TextMessage>());
      expect((sentCallbackMessage! as TextMessage).text, 'Hello ConvoKit');
    });

    testWidgets('gates typing events on capabilities.typing', (tester) async {
      final backend = FakeChatBackend(seededMessageCount: 1);
      final recordingMessages = _RecordingMessageRepository(backend.messages);

      // 1. capabilities.typing == false -> zero sendTyping calls
      final noTypingKit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: recordingMessages,
        events: backend.events,
        capabilities: const ChatCapabilities(typing: false),
      );

      await tester.pumpWidget(
        pumpHarness(
          kit: noTypingKit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Typing...');
      await tester.pump();
      expect(recordingMessages.typingCalls, isEmpty);

      // 2. capabilities.typing == true -> sendTyping(convId, true) called
      final typingKit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: recordingMessages,
        events: backend.events,
        capabilities: const ChatCapabilities(typing: true),
      );

      await tester.pumpWidget(
        pumpHarness(
          kit: typingKit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Now typing');
      await tester.pump();
      expect(
        recordingMessages.typingCalls,
        contains(('conv_1_2', true)),
      );
    });

    testWidgets('hides attach button when kit.media == null || !capabilities.media', (
      tester,
    ) async {
      final backend = FakeChatBackend(seededMessageCount: 1);

      // Without media capability
      final noMediaKit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: const ChatCapabilities(media: false),
        media: null,
      );

      await tester.pumpWidget(
        pumpHarness(
          kit: noMediaKit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Add attachment'), findsNothing);

      // With media capability
      final mediaKit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: const ChatCapabilities(media: true),
        media: FakeChatMediaProvider(),
      );

      await tester.pumpWidget(
        pumpHarness(
          kit: mediaKit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Add attachment'), findsOneWidget);
    });

    testWidgets('renders reply preview and clears on close tap', (
      tester,
    ) async {
      final backend = FakeChatBackend(seededMessageCount: 1);
      final kit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: backend.messages,
        events: backend.events,
        capabilities: const ChatCapabilities(),
      );

      var cleared = false;
      final replyTarget = TextMessage(
        id: 'm1',
        localId: 'loc_m1',
        conversationId: 'conv_1_2',
        sender: backend.user2,
        createdAt: DateTime(2026),
        text: 'Original message',
      );

      await tester.pumpWidget(
        pumpHarness(
          kit: kit,
          child: ConvoKitMessageComposer(
            conversationId: 'conv_1_2',
            user: backend.user2,
            replyMessage: replyTarget,
            onClearReply: () => cleared = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Original message'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(cleared, isTrue);
      expect(find.text('Original message'), findsNothing);
    });
  });
}
