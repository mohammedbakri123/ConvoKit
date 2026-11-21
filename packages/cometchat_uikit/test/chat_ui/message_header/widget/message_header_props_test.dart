import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitMessageHeader (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 3);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(
          kit: kit,
          child: Scaffold(appBar: child as PreferredSizeWidget),
        ),
      );
    }

    testWidgets(
      'displays user details and reacts to EventHub.presenceRegistry updates',
      (tester) async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: ChatCapabilities.basic(),
        );

        await tester.pumpWidget(
          wrapWithScope(
            kit,
            ConvoKitMessageHeader(
              user: fake.user2,
              conversationId: 'conv_1_2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(fake.user2.name), findsOneWidget);

        fake.injectPresence(fake.user2, UserPresence.online);
        await tester.pumpAndSettle();
        expect(find.textContaining('Online'), findsOneWidget);

        fake.injectPresence(fake.user2, UserPresence.offline);
        await tester.pumpAndSettle();
        expect(find.textContaining('Offline'), findsOneWidget);
      },
    );

    testWidgets(
      'shows typing indicator when capabilities.typing is true and hides it when false',
      (tester) async {
        // 1. capabilities.typing == true
        final kitWithTyping = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(typing: true),
        );

        await tester.pumpWidget(
          wrapWithScope(
            kitWithTyping,
            ConvoKitMessageHeader(
              user: fake.user2,
              conversationId: 'conv_typing_1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        fake.injectTyping('conv_typing_1', fake.user2, true);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp('typing', caseSensitive: false)),
          findsOneWidget,
        );

        fake.injectTyping('conv_typing_1', fake.user2, false);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp('typing', caseSensitive: false)),
          findsNothing,
        );

        // 2. capabilities.typing == false
        final kitNoTyping = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: const ChatCapabilities(typing: false),
        );

        await tester.pumpWidget(
          wrapWithScope(
            kitNoTyping,
            ConvoKitMessageHeader(
              user: fake.user2,
              conversationId: 'conv_typing_2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        fake.injectTyping('conv_typing_2', fake.user2, true);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp('typing', caseSensitive: false)),
          findsNothing,
        );
      },
    );

    testWidgets('displays group name and member count and handles groups: null', (
      tester,
    ) async {
      final group = fake.groupsList.first;
      final kitNoGroupsRepo = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: null,
        capabilities: const ChatCapabilities(groups: false),
      );

      await tester.pumpWidget(
        wrapWithScope(
          kitNoGroupsRepo,
          ConvoKitMessageHeader(group: group, conversationId: group.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(group.name), findsOneWidget);
      expect(find.textContaining('${group.memberCount}'), findsOneWidget);
    });

    testWidgets(
      'cleanly unsubscribes on didUpdateWidget and dispose without errors',
      (tester) async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          capabilities: ChatCapabilities.basic(),
        );

        await tester.pumpWidget(
          wrapWithScope(
            kit,
            ConvoKitMessageHeader(
              user: fake.user2,
              conversationId: 'conv_switch_a',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch target user
        await tester.pumpWidget(
          wrapWithScope(
            kit,
            ConvoKitMessageHeader(
              user: fake.user3,
              conversationId: 'conv_switch_b',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(fake.user3.name), findsOneWidget);

        // Old conversation typing should not affect the new header
        fake.injectTyping('conv_switch_a', fake.user2, true);
        await tester.pumpAndSettle();
        expect(find.textContaining('typing'), findsNothing);

        // Dispose cleanly
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pumpAndSettle();

        fake.injectPresence(fake.user3, UserPresence.online);
        fake.injectTyping('conv_switch_b', fake.user3, true);
        await tester.pump();
      },
    );

    testWidgets('wires custom callbacks and slots (onBack, onHeaderTap, trailingView)', (
      tester,
    ) async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      var backTapped = false;
      var headerTapped = false;

      await tester.pumpWidget(
        wrapWithScope(
          kit,
          ConvoKitMessageHeader(
            user: fake.user2,
            backButton: (_) => IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => backTapped = true,
            ),
            onHeaderTap: () => headerTapped = true,
            trailingView: (_, _, _) => const [Icon(Icons.star)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(backTapped, isTrue);

      await tester.tap(find.text(fake.user2.name));
      expect(headerTapped, isTrue);

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
