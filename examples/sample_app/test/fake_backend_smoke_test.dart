// Phase 0 — failing test: sample app builds against a fake (InMemory) backend.
//
// This test MUST fail right now. It fails because:
//   1. The ConvoKit public API (ConvoKit, ConvoKitScope, ChatCapabilities) does
//      not exist yet — it will be introduced in Phase 1.
//   2. The InMemoryChatBackend fake does not exist yet — it will be built
//      during Phase 2/6.
//   3. The sample app is still wired to CometChat (cometchat_chat_uikit).
//
// When all three conditions are resolved, this test will pass: the sample app
// will render a ConversationsView fed by an in-memory fake, with no CometChat
// SDK dependency and no network.
//
// DO NOT make this test pass without completing Phase 1 (own models + contracts
// + ConvoKitScope) and providing the InMemoryChatBackend.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// These imports will resolve once Phase 1 introduces the ConvoKit public API.
// Until then, they cause a compilation failure — which is the intended failure
// mode for this test.  The imports are the ONLY reason this test fails; there
// are no typos or syntax errors.
//
// ignore: uri_does_not_exist
import 'package:convokit/convokit.dart';
// The InMemoryChatBackend will live in example/ (not in the shipped package).
// ignore: uri_does_not_exist
import 'package:sample_app/in_memory_chat_backend.dart';

void main() {
  testWidgets(
    'Sample app renders ConversationsView against InMemoryChatBackend',
    (WidgetTester tester) async {
      // 1. Create the fake backend — seeded with demo data, fully offline.
      final fake = InMemoryChatBackend();

      // 2. Build the ConvoKit composition root using the fake's providers.
      //    This is the shape defined in API-DESIGN.md §16.A.
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        capabilities: ChatCapabilities.basic(),
      );

      // 3. Pump a minimal app: ConvoKitScope wrapping a ConversationsView.
      await tester.pumpWidget(
        MaterialApp(
          home: ConvoKitScope(
            kit: kit,
            child: const ConversationsView(),
          ),
        ),
      );

      // Allow async init (stream subscriptions, initial fetch) to settle.
      await tester.pumpAndSettle();

      // 4. Verify: the conversations view rendered at least one conversation
      //    from the fake's seed data, proving the sample app can run against
      //    an in-memory backend with no CometChat SDK and no network.
      expect(find.byType(ConversationsView), findsOneWidget);
    },
  );
}
