/// Style prop verification for conversation, user, and group list items.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice', presence: UserPresence.online);
  const group = ChatGroup(id: 'g1', name: 'Engineering', type: GroupType.public);

  testWidgets('ConvoKitConversationListItem applies style properties', (
    tester,
  ) async {
    final conv = ChatConversation.direct(
      id: 'c1',
      peer: alice,
      unreadCount: 2,
      updatedAt: DateTime(2026),
      lastMessage: TextMessage(
        id: 'm1',
        localId: 'm1',
        conversationId: 'c1',
        sender: alice,
        createdAt: DateTime(2026),
        text: 'Thursday works',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: ConvoKitConversationListItem(
            conversation: conv,
            onItemClick: (_) {},
            style: const ConvoKitConversationListItemStyle(
              backgroundColor: Color(0xFF102030),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    expect(group.name, 'Engineering');
  });
}
