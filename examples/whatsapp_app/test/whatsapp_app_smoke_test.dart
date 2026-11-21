import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_app/data/whatsapp_in_memory_backend.dart';
import 'package:whatsapp_app/main.dart';
import 'package:whatsapp_app/screens/whatsapp_chat_screen.dart';

void main() {
  testWidgets(
    'WhatsAppApp renders modern chats list, opens chat screen on tap, and sends a message',
    (WidgetTester tester) async {
      final backend = WhatsAppInMemoryBackend();

      await tester.pumpWidget(WhatsAppApp(backend: backend));
      await tester.pumpAndSettle();

      // 1. Modern WhatsApp header, filter chips, bottom nav, FAB, and ConvoKitConversations render.
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(ConvoKitConversations), findsOneWidget);

      // Seeded contacts appear in the chats list.
      expect(find.text('Amina Hassan'), findsOneWidget);
      expect(find.text('Weekend Hike Crew'), findsOneWidget);

      // 2. Tapping a chat opens the WhatsAppChatScreen with real ConvoKit widgets.
      await tester.tap(find.text('Amina Hassan'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsAppChatScreen), findsOneWidget);
      expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
      expect(find.byType(ConvoKitMessageList), findsOneWidget);
      expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
      expect(find.text('On my way! Be there in 5 minutes.'), findsOneWidget);

      // 3. Typing a message and tapping send appends it to the message list.
      await tester.enterText(
        find.byType(TextField),
        'See you at the window table!',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('See you at the window table!'), findsOneWidget);
    },
  );
}
