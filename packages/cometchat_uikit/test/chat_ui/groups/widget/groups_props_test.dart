import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../convokit/fake_chat_backend.dart';

class _FailingGroupRepository implements GroupRepository {
  @override
  Future<ChatResult<ChatPage<ChatGroup>>> listGroups({
    String? cursor,
    int limit = 30,
  }) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Groups failed'));

  @override
  Future<ChatResult<ChatGroup>> getGroup(String id) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Get group failed'));

  @override
  Future<ChatResult<ChatPage<ChatMember>>> listMembers(
    String groupId, {
    String? cursor,
    int limit = 30,
  }) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Members failed'));

  @override
  Future<ChatResult<void>> joinGroup(String groupId) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Join failed'));

  @override
  Future<ChatResult<void>> leaveGroup(String groupId) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Leave failed'));

  @override
  Future<ChatResult<void>> addMembers(
    String groupId,
    List<String> userIds,
  ) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Add failed'));

  @override
  Future<ChatResult<void>> removeMember(
    String groupId,
    String userId,
  ) async =>
      const ChatFailure(ChatError(ChatErrorCode.network, 'Remove failed'));
}

void main() {
  group('ConvoKitGroups (ConvoKitScope + FakeChatBackend)', () {
    late FakeChatBackend fake;

    setUp(() {
      fake = FakeChatBackend(seededMessageCount: 5);
    });

    Widget wrapWithScope(ConvoKit kit, Widget child) {
      return MaterialApp(
        localizationsDelegates: Translations.localizationsDelegates,
        supportedLocales: Translations.supportedLocales,
        home: ConvoKitScope(kit: kit, child: child),
      );
    }

    ConvoKit buildKit({
      bool groupsEnabled = true,
      GroupRepository? groupsRepo,
    }) {
      return ConvoKit(
        session: fake.session,
        users: fake.users,
        conversations: fake.conversations,
        messages: fake.messages,
        events: fake.events,
        groups: groupsEnabled ? (groupsRepo ?? fake.groups) : null,
        capabilities: ChatCapabilities(groups: groupsEnabled),
      );
    }

    testWidgets(
      'renders empty/disabled state cleanly when capabilities.groups is false and groups is null',
      (tester) async {
        var emptyCalled = false;
        final key = GlobalKey<ConvoKitGroupsState>();

        await tester.pumpWidget(
          wrapWithScope(
            buildKit(groupsEnabled: false),
            ConvoKitGroups(
              key: key,
              debounceDuration: Duration.zero,
              onEmpty: () => emptyCalled = true,
              emptyStateView: (_) => const Text('Groups Disabled'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(emptyCalled, isTrue);
        expect(find.text('Groups Disabled'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        final joinRes = await key.currentState!.joinGroup('any');
        expect(joinRes.isFailure, isTrue);
        final leaveRes = await key.currentState!.leaveGroup('any');
        expect(leaveRes.isFailure, isTrue);
      },
    );

    testWidgets(
      'loads groups via GroupRepository.listGroups and invokes callbacks',
      (tester) async {
        List<ChatGroup>? loaded;
        ChatGroup? tapped;

        await tester.pumpWidget(
          wrapWithScope(
            buildKit(),
            ConvoKitGroups(
              debounceDuration: Duration.zero,
              onLoad: (groups) => loaded = groups,
              onItemTap: (ctx, group) => tapped = group,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(loaded, isNotNull);
        expect(loaded!.length, equals(fake.groupsList.length));
        expect(find.text(fake.groupsList.first.name), findsOneWidget);

        await tester.tap(find.text(fake.groupsList.first.name));
        await tester.pump();
        expect(tapped?.id, equals(fake.groupsList.first.id));
      },
    );

    testWidgets('supports joinGroup, leaveGroup, and fetchGroup', (
      tester,
    ) async {
      final key = GlobalKey<ConvoKitGroupsState>();
      final firstGroup = fake.groupsList.first;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitGroups(
            key: key,
            debounceDuration: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fetched = await key.currentState!.fetchGroup(firstGroup.id);
      expect(fetched?.id, equals(firstGroup.id));

      final joined = await key.currentState!.joinGroup(firstGroup.id);
      expect(joined.isSuccess, isTrue);

      final left = await key.currentState!.leaveGroup(firstGroup.id);
      expect(left.isSuccess, isTrue);
    });

    testWidgets('supports selection mode and invokes onSelection', (
      tester,
    ) async {
      List<ChatGroup>? selected;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(),
          ConvoKitGroups(
            debounceDuration: Duration.zero,
            selectionMode: SelectionMode.multiple,
            activateSelection: ActivateSelection.onClick,
            onSelection: (groups) => selected = groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(fake.groupsList.first.name));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.map((g) => g.id), equals([fake.groupsList.first.id]));
    });

    testWidgets('renders errorStateView and respects hideError on failure', (
      tester,
    ) async {
      Exception? reported;

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(groupsRepo: _FailingGroupRepository()),
          ConvoKitGroups(
            debounceDuration: Duration.zero,
            onError: (e) => reported = e,
            errorStateView: (_) => const Text('Groups Error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(find.text('Groups Error'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithScope(
          buildKit(groupsRepo: _FailingGroupRepository()),
          const ConvoKitGroups(
            debounceDuration: Duration.zero,
            hideError: true,
            errorStateView: _errorBuilder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groups Error'), findsNothing);
    });
  });
}

Widget _errorBuilder(BuildContext context) => const Text('Groups Error');
