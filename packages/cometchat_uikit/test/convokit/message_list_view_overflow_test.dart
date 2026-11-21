import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chat_backend.dart';

void main() {
  testWidgets(
    'MessageListView wraps long message text without horizontal Row overflow',
    (tester) async {
      final fake = FakeChatBackend();
      const longText =
          'This is a deliberately very long studio message designed to exceed '
          'a narrow mobile or split-pane viewport width by hundreds of logical '
          'pixels so MessageListView must wrap cleanly without overflowing.';

      fake.messagesByConversation['conv_1_2'] = <ChatMessage>[
        TextMessage(
          id: 'm_long_out',
          localId: 'l_long_out',
          conversationId: 'conv_1_2',
          sender: fake.user1,
          createdAt: DateTime.now(),
          text: longText,
          sendState: SendState.sent,
          deliveryState: DeliveryState.read,
        ),
        TextMessage(
          id: 'm_long_in',
          localId: 'l_long_in',
          conversationId: 'conv_1_2',
          sender: fake.user2,
          createdAt: DateTime.now(),
          text: longText,
          sendState: SendState.sent,
          deliveryState: DeliveryState.delivered,
        ),
      ];

      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: null,
        media: null,
        capabilities: const ChatCapabilities(receipts: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const Scaffold(
              body: SizedBox(
                width: 320,
                height: 480,
                child: MessageListView(conversationId: 'conv_1_2'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longText), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
