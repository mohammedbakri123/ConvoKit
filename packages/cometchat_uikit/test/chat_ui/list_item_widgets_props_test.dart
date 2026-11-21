/// Widget slot prop verification for conversation and group list items.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = ChatUser(id: 'u1', name: 'Alice', presence: UserPresence.online);
  const group = ChatGroup(id: 'g1', name: 'Design', type: GroupType.private);

  testWidgets('ConvoKitConversationListItem renders custom leading/title/subtitle/trailing slots', (
    tester,
  ) async {
    final conv = ChatConversation.group(
      id: 'c_g1',
      group: group,
      unreadCount: 1,
      updatedAt: DateTime(2026),
      lastMessage: TextMessage(
        id: 'm1',
        localId: 'm1',
        conversationId: 'c_g1',
        sender: alice,
        createdAt: DateTime(2026),
        text: 'Design review at 3pm',
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
            leadingView: (_, _) => const Text('L'),
            titleView: (_, _) => const Text('T'),
            subtitleView: (_, _) => const Text('S'),
            trailingView: (_, _) => const Text('R'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('L'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });
}
