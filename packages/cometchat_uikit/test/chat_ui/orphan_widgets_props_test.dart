/// Standalone widget prop verification for shared conversation/list views.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice', presence: UserPresence.online);

  testWidgets('ConvoKitConversationListItem handles tap and long press callbacks', (
    tester,
  ) async {
    ChatConversation? tapped;
    final conv = ChatConversation.direct(
      id: 'c1',
      peer: alice,
      updatedAt: DateTime(2026),
      lastMessage: TextMessage(
        id: 'm1',
        localId: 'm1',
        conversationId: 'c1',
        sender: alice,
        createdAt: DateTime(2026),
        text: 'Hello',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: ConvoKitConversationListItem(
            conversation: conv,
            onItemClick: (c) => tapped = c,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(ConvoKitConversationListItem));
    expect(tapped, conv);
  });
}
