import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';

class _CapturingMessageRepository implements MessageRepository {
  _CapturingMessageRepository(this._inner);

  final MessageRepository _inner;
  final List<ChatMessage> sentMessages = <ChatMessage>[];

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) => _inner.fetchMessages(conversationId, request);

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) {
    sentMessages.add(message);
    return _inner.sendMessage(message);
  }

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
  Future<ChatResult<void>> sendTyping(String conversationId, bool isTyping) =>
      _inner.sendTyping(conversationId, isTyping);
}

void main() {
  testWidgets(
    'CometChatCreatePoll uses explicit conversationId when provided and falls back to receiverUid when null',
    (tester) async {
      final backend = FakeChatBackend(seededMessageCount: 0);
      final capturingMessages = _CapturingMessageRepository(backend.messages);
      final kit = ConvoKit(
        session: backend.session,
        users: backend.users,
        conversations: backend.conversations,
        messages: capturingMessages,
        events: backend.events,
        capabilities: const ChatCapabilities(),
      );

      Future<void> submitPoll(Widget pollWidget) async {
        await tester.pumpWidget(
          ConvoKitScope(
            kit: kit,
            child: MaterialApp(
              localizationsDelegates: Translations.localizationsDelegates,
              supportedLocales: Translations.supportedLocales,
              home: Scaffold(body: pollWidget),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Preferred review slot?');
        await tester.enterText(fields.at(1), 'Morning');
        await tester.enterText(fields.at(2), 'Afternoon');
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      // 1. Explicit conversationId overrides user/group receiverUid.
      await submitPoll(
        const CometChatCreatePoll(
          conversationId: 'conv_explicit_42',
          group: 'grp_design',
        ),
      );

      expect(capturingMessages.sentMessages, hasLength(1));
      expect(capturingMessages.sentMessages.last, isA<CustomMessage>());
      expect(
        capturingMessages.sentMessages.last.conversationId,
        'conv_explicit_42',
      );

      // 2. Null conversationId falls back to receiverUid (existing behavior).
      await submitPoll(
        const CometChatCreatePoll(
          user: 'user_2',
        ),
      );

      expect(capturingMessages.sentMessages, hasLength(2));
      expect(capturingMessages.sentMessages.last.conversationId, 'user_2');
    },
  );
}
