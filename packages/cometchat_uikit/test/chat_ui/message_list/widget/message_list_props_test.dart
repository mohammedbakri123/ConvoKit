import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageList (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 5);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(kit: kit, child: Scaffold(body: child)),
      );
    }

    ConvoKit buildKit({bool receipts = true}) {
      return ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities(receipts: receipts),
      );
    }

    testWidgets('loads messages from MessageStore and fires onLoad', (
      tester,
    ) async {
      final convId = fake.conversationsList.first.id;
      List<ChatMessage>? loaded;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitMessageList(
            conversationId: convId,
            onLoad: (msgs) => loaded = msgs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loaded, isNotNull);
      expect(loaded, isNotEmpty);
    });

    testWidgets('shows gap banner when MessageStore reports a gap', (
      tester,
    ) async {
      final convId = fake.conversationsList.first.id;
      final kit = buildKit();

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          ConvoKitMessageList(conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ConvoKitMessageList));
      final hub = ConvoKitScope.hubOf(element);
      hub.getMessageStore(convId).setGapFlag(true);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('gap_banner')), findsOneWidget);
      expect(find.byKey(const Key('gap_banner_refresh')), findsOneWidget);
    });

    testWidgets('hides receipts when capabilities.receipts is false', (
      tester,
    ) async {
      final convId = fake.conversationsList.first.id;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(receipts: false),
          ConvoKitMessageList(conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConvoKitReceipt), findsNothing);
    });

    testWidgets('handles conversationId change cleanly without throwing', (
      tester,
    ) async {
      final conv1 = fake.conversationsList.first.id;
      final conv2 = fake.conversationsList.length > 1
          ? fake.conversationsList[1].id
          : 'conv_other';
      final kit = buildKit();

      await tester.pumpWidget(
        wrapWithScope(kit, ConvoKitMessageList(conversationId: conv1)),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        wrapWithScope(kit, ConvoKitMessageList(conversationId: conv2)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConvoKitMessageList), findsOneWidget);
    });
  });
}
