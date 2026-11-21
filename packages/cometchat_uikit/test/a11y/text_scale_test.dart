/// Accessibility text-scale tests for core ConvoKit list items and bubbles.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(
    id: 'alex',
    name: 'Alexandra Constantinou',
    presence: UserPresence.online,
  );
  const group = ChatGroup(
    id: 'g1',
    name: 'Product Engineering Team',
    type: GroupType.private,
    memberCount: 24,
  );

  testWidgets('list items and text bubbles render at 2.0 text scale without error', (
    tester,
  ) async {
    final conv = ChatConversation.direct(
      id: 'c1',
      peer: alice,
      unreadCount: 3,
      updatedAt: DateTime(2026, 9, 1, 14, 30),
      lastMessage: TextMessage(
        id: '1',
        localId: 'm1',
        conversationId: 'c1',
        sender: alice,
        createdAt: DateTime(2026, 9, 1, 14, 30),
        text: 'Rescheduled to Thursday 14:00 — does that work?',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: ListView(
              children: [
                ConvoKitConversationListItem(
                  conversation: conv,
                  onItemClick: (_) {},
                ),
                const CometChatTextBubble(
                  text: 'Rescheduled to Thursday 14:00 — does that work?',
                  alignment: BubbleAlignment.left,
                ),
                ConvoKitAvatar(name: group.name),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ConvoKitConversationListItem), findsOneWidget);
    expect(find.byType(CometChatTextBubble), findsOneWidget);
  });
}
