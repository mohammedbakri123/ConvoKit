import 'package:flutter_test/flutter_test.dart';
import 'package:cometchat_chat_uikit/convokit.dart';

import 'contract_compilation_test.dart';

void main() {
  group('ConvoKit constructor validation (runtime release-safe checks)', () {
    final session = HostChatSession(const ChatUser(id: 'u1', name: 'Alice'));
    final users = HostUserRepository();
    final conversations = HostConversationRepository();
    final messages = HostMessageRepository();
    final events = HostChatEventSource();
    final groups = HostGroupRepository();
    final media = HostChatMediaProvider();

    test('valid default setup without optional providers succeeds', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          capabilities: const ChatCapabilities(),
        ),
        returnsNormally,
      );
    });

    test('valid full setup with basic capabilities and all providers succeeds', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          groups: groups,
          media: media,
          capabilities: ChatCapabilities.basic(),
        ),
        returnsNormally,
      );
    });

    test('throws ArgumentError when capabilities.groups is true but groups is null', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          groups: null,
          capabilities: const ChatCapabilities(groups: true),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('groups provider and capabilities.groups disagree'),
          ),
        ),
      );
    });

    test('throws ArgumentError when capabilities.groups is false but groups is non-null', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          groups: groups,
          capabilities: const ChatCapabilities(groups: false),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('groups provider and capabilities.groups disagree'),
          ),
        ),
      );
    });

    test('throws ArgumentError when capabilities.media is true but media is null', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          media: null,
          capabilities: const ChatCapabilities(media: true),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('media provider and capabilities.media disagree'),
          ),
        ),
      );
    });

    test('throws ArgumentError when capabilities.media is false but media is non-null', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          media: media,
          capabilities: const ChatCapabilities(media: false),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('media provider and capabilities.media disagree'),
          ),
        ),
      );
    });

    test('throws ArgumentError when capabilities.mediaDelete is true but media is null', () {
      expect(
        () => ConvoKit(
          session: session,
          users: users,
          conversations: conversations,
          messages: messages,
          events: events,
          media: null,
          capabilities: const ChatCapabilities(media: false, mediaDelete: true),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('mediaDelete requires a media provider'),
          ),
        ),
      );
    });
  });
}
