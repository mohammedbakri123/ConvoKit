import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../convokit/fake_chat_backend.dart';

void main() {
  group('ConvoKitGroupMembersController (GroupRepository + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 5);
    });

    test(
      'enters disabled/empty state when capabilities.groups is false and groups is null',
      () async {
        final kit = ConvoKit(
          session: fake.session,
          users: fake.users,
          conversations: fake.conversations,
          messages: fake.messages,
          events: fake.events,
          groups: null,
          capabilities: const ChatCapabilities(groups: false),
        );
        final group = fake.groupsList.first;
        var emptyCalled = false;

        final controller = ConvoKitGroupMembersController(
          group: group,
          onEmpty: () => emptyCalled = true,
        );
        controller.attachKit(kit);

        await controller.loadMembers();
        expect(controller.isDisabled, isTrue);
        expect(controller.members, isEmpty);
        expect(emptyCalled, isTrue);

        final addRes = await controller.addMembers(['u99']);
        expect(addRes.isFailure, isTrue);
        expect(addRes.errorOrNull?.code, equals(ChatErrorCode.unsupported));

        final removeRes = await controller.removeMember(fake.user2.id);
        expect(removeRes.isFailure, isTrue);
        expect(removeRes.errorOrNull?.code, equals(ChatErrorCode.unsupported));

        controller.dispose();
      },
    );

    test('loads members, filters by search, selects, and removes member', () async {
      final kit = ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: fake.groups,
        capabilities: const ChatCapabilities(groups: true),
      );
      final group = fake.groupsList.first;
      final controller = ConvoKitGroupMembersController(
        group: group,
        selectionMode: SelectionMode.multiple,
      );
      controller.attachKit(kit);

      await controller.loadMembers();
      expect(controller.isDisabled, isFalse);
      expect(controller.members, isNotEmpty);

      final firstMember = controller.members.first;
      controller.onSearch(firstMember.user.name);
      expect(
        controller.visibleMembers.every(
          (m) => m.user.name.toLowerCase().contains(
            firstMember.user.name.toLowerCase(),
          ),
        ),
        isTrue,
      );
      controller.onSearch('');

      controller.toggleSelection(firstMember.user.id);
      expect(controller.getSelectedList().map((m) => m.user.id), [
        firstMember.user.id,
      ]);
      controller.clearSelection();
      expect(controller.getSelectedList(), isEmpty);

      final initialCount = controller.members.length;
      final removeRes = await controller.removeMember(firstMember.user.id);
      expect(removeRes.isSuccess, isTrue);
      expect(controller.members.length, equals(initialCount - 1));

      final addRes = await controller.addMembers([firstMember.user.id]);
      expect(addRes.isSuccess, isTrue);

      controller.dispose();
    });
  });
}
