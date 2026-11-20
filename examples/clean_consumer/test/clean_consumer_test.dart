import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clean_consumer/main.dart';
import 'package:clean_consumer/in_memory_chat_backend.dart';
import 'package:convokit/convokit.dart';

void main() {
  group('Clean Consumer acceptance tests (Criteria 13 & 14)', () {
    test('examples/clean_consumer contains ZERO flutter_bloc and ZERO cometchat imports', () {
      final dir = Directory('lib');
      final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains('flutter_bloc'),
          isFalse,
          reason: '${file.path} must not import flutter_bloc',
        );
        expect(
          content.contains('package:cometchat'),
          isFalse,
          reason: '${file.path} must not import any package:cometchat_*',
        );
      }
    });

    testWidgets('renders ConversationsView and navigates to MessageListView against fake backend', (tester) async {
      final fake = InMemoryChatBackend();
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        groups: fake.groups,
        media: fake.media,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kitProvider.overrideWithValue(kit),
          ],
          child: const CleanConsumerApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert ConversationsView is rendered
      expect(find.byType(ConversationsView), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);

      // Verify conversation items are rendered from superhero demo data
      expect(find.text('Captain America'), findsOneWidget);

      // Tap on Captain America conversation to navigate to ChatScreen
      await tester.tap(find.text('Captain America'));
      await tester.pumpAndSettle();

      // Assert ChatScreen and MessageListView are rendered
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(MessageListView), findsOneWidget);
      expect(find.text('Captain America'), findsOneWidget);
    });
  });
}
