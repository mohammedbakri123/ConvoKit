import 'package:blue_messenger_app/data/blue_in_memory_backend.dart';
import 'package:blue_messenger_app/main.dart';
import 'package:blue_messenger_app/screens/blue_chat_screen.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'BlueMessengerApp renders floating-island tabs, opens chat, and sends a message',
    (WidgetTester tester) async {
      final backend = BlueInMemoryBackend();

      await tester.pumpWidget(BlueMessengerApp(backend: backend));
      await tester.pumpAndSettle();

      // 1. Floating-island shell, search pill, nav pill, FAB, and ConvoKitConversations render.
      expect(find.text('Blue Messenger'), findsOneWidget);
      expect(find.byKey(const Key('blue_floating_search_pill')), findsOneWidget);
      expect(find.byKey(const Key('blue_floating_island_nav')), findsOneWidget);
      expect(find.byKey(const Key('blue_new_chat_fab')), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Groups'), findsNWidgets(2));
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.byType(ConvoKitConversations), findsOneWidget);

      // Seeded conversations appear in the chats list.
      expect(find.text('Maya Lin'), findsWidgets);
      expect(find.text('Ocean Design Guild'), findsWidgets);

      // 2. Switching to Contacts and Groups tabs renders ConvoKitUsers and ConvoKitGroups.
      await tester.tap(find.byKey(const Key('blue_nav_tab_contacts')));
      await tester.pumpAndSettle();
      expect(find.byType(ConvoKitUsers), findsOneWidget);

      await tester.tap(find.byKey(const Key('blue_nav_tab_groups')));
      await tester.pumpAndSettle();
      expect(find.byType(ConvoKitGroups), findsOneWidget);

      // Return to Chats tab.
      await tester.tap(find.byKey(const Key('blue_nav_tab_chats')));
      await tester.pumpAndSettle();

      // 3. Tapping a chat opens BlueChatScreen with library widgets.
      await tester.tap(find.text('Maya Lin').first);
      await tester.pumpAndSettle();

      expect(find.byType(BlueChatScreen), findsOneWidget);
      expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
      expect(find.byType(ConvoKitMessageList), findsOneWidget);
      expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
      expect(
        find.byKey(const Key('blue_floating_composer_island')),
        findsOneWidget,
      );
      expect(
        find.text('The floating islands feel super crisp! Ready for review.'),
        findsOneWidget,
      );

      // 4. Typing a message and tapping send appends it to the message list.
      await tester.enterText(
        find.byType(TextField),
        'Blue Messenger looks awesome!',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Blue Messenger looks awesome!'), findsOneWidget);
    },
  );
}
