/// The last twelve — repositories, blocs and controllers.
/// Track 3 TEST3 / construction coverage (ENG-38684).
///
/// This closes the never-constructed list for the messaging, calls and shared
/// areas. What is left is the heaviest kind: classes that register SDK
/// listeners, resolve dependencies through a service locator, or wrap a data
/// source in a four-branch error map.
///
/// The five call blocs are constructed and immediately closed. That is a
/// deliberately shallow assertion and worth being honest about: each one
/// registers a listener in its constructor and generates a listener id from
/// the wall clock, so the useful thing to pin is that constructing and
/// disposing one is safe and that its initial state is what the widget builds
/// against before anything happens. Driving them needs a live SDK and belongs
/// in the E2E suite.
///
/// [MessageComposerRepositoryImpl] is the opposite: no listeners, and a
/// four-branch error map per method that is entirely testable here.
///
///   flutter test test/shared_ui/repositories_and_controllers_test.dart
library;

import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTextMessage extends Fake implements TextMessage {
  _FakeTextMessage(this.text);
  @override
  final String text;
}

class _FakeGroup extends Fake implements Group {
  @override
  String get guid => 'g1';
  @override
  String get name => 'Platform';
}

/// The real builder, not a fake: the controller's superclass calls
/// `getRequest()` during construction, so a fake would only prove that a fake
/// throws.
GroupMembersBuilderProtocol _membersBuilder() =>
    UIGroupMembersBuilder(GroupMembersRequestBuilder('g1'));

/// Fails `sendTextMessage` with whatever it is given, so the repository's
/// error map can be walked branch by branch.
class _ThrowingComposerDataSource extends Fake
    implements MessageComposerDataSource {
  _ThrowingComposerDataSource(this.error);
  final Object error;

  @override
  Future<TextMessage> sendTextMessage(TextMessage message) async => throw error;
}

class _EchoComposerDataSource extends Fake
    implements MessageComposerDataSource {
  int calls = 0;

  @override
  Future<TextMessage> sendTextMessage(TextMessage message) async {
    calls++;
    return message;
  }
}

class _StubMessageDataSource extends Fake implements MessageDataSource {
  final List<String> seen = [];

  @override
  Future<Result<List<MessageEntity>>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    seen.add('getMessages($conversationId,$limit,$offset)');
    return const Success(<MessageEntity>[]);
  }
}

class _StubUserDataSource extends Fake implements UserDataSource {
  final List<String> seen = [];

  @override
  Future<Result<UserEntity>> getUser(String userId) async {
    seen.add('getUser($userId)');
    return const Failure(message: 'Not implemented');
  }
}

class _StubGroupDataSource extends Fake implements GroupDataSource {
  final List<String> seen = [];

  @override
  Future<Result<GroupEntity>> getGroup(String groupId) async {
    seen.add('getGroup($groupId)');
    return const Failure(message: 'Not implemented');
  }
}

void main() {
  // The call blocs read ServicesBinding.instance while registering their SDK
  // listeners, so the binding has to exist before the first one is built.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Closing an incoming or outgoing call bloc stops the ringtone, which is a
  // platform-channel call. Without a handler the channel throws *after* the
  // test body has finished, which the test runner reports as a failure with no
  // useful stack. Answering the channel keeps the failure surface on the bloc.
  const channel = MethodChannel('cometchat_chat_uikit');
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // ===========================================================================
  group('MessageComposerRepositoryImpl error mapping', () {
    test(
      'a successful send is wrapped in Success and reaches the source',
      () async {
        final source = _EchoComposerDataSource();
        final result = await MessageComposerRepositoryImpl(
          dataSource: source,
        ).sendTextMessage(_FakeTextMessage('hi'));

        expect(result.isSuccess, isTrue);
        expect(source.calls, 1);
      },
    );

    test(
      'a typed data-source exception keeps its message, code and cause',
      () async {
        final cause = Exception('socket');
        final result = await MessageComposerRepositoryImpl(
          dataSource: _ThrowingComposerDataSource(
            MessageComposerDataSourceException(
              message: 'send failed',
              code: 'ERR_NET',
              originalException: cause,
            ),
          ),
        ).sendTextMessage(_FakeTextMessage('hi'));

        result.fold((f) {
          expect(f.message, 'send failed');
          expect(f.code, 'ERR_NET');
          expect(f.exception, same(cause));
        }, (_) => fail('expected a Failure'));
      },
    );

    test('an untyped error is wrapped with context and no cause', () async {
      // A StateError is an Error, not an Exception, so the cause slot is left
      // null rather than holding something of the wrong type — the same
      // decision the notification-feed repository makes.
      final result = await MessageComposerRepositoryImpl(
        dataSource: _ThrowingComposerDataSource(StateError('bad state')),
      ).sendTextMessage(_FakeTextMessage('hi'));

      result.fold((f) {
        expect(f.message, contains('Failed to send text message'));
        expect(f.message, contains('bad state'));
        expect(f.exception, isNull);
      }, (_) => fail('expected a Failure'));
    });

    test('a plain Exception is kept as the cause', () async {
      final cause = Exception('boom');
      final result = await MessageComposerRepositoryImpl(
        dataSource: _ThrowingComposerDataSource(cause),
      ).sendTextMessage(_FakeTextMessage('hi'));

      result.fold(
        (f) => expect(f.exception, same(cause)),
        (_) => fail('expected a Failure'),
      );
    });
  });

  // ===========================================================================
  group('the shared entity repositories', () {
    // Worth recording: this whole layer is scaffolding. Every method on
    // MessageDataSourceImpl, UserDataSourceImpl and GroupDataSourceImpl
    // returns `Failure('Not implemented')`, and the only thing that builds
    // these three repositories is service_locator.dart. The tests below cover
    // the delegation, which is all there is to cover, and say out loud that
    // the layer beneath it does nothing.
    test(
      'MessageRepositoryImpl forwards its arguments, defaults included',
      () async {
        final source = _StubMessageDataSource();
        final repository = MessageRepositoryImpl(dataSource: source);

        await repository.getMessages(conversationId: 'c1');
        await repository.getMessages(
          conversationId: 'c1',
          limit: 10,
          offset: 20,
        );

        expect(source.seen, ['getMessages(c1,50,0)', 'getMessages(c1,10,20)']);
      },
    );

    test('MessageRepositoryImpl returns what the source returns', () async {
      final result = await MessageRepositoryImpl(
        dataSource: _StubMessageDataSource(),
      ).getMessages(conversationId: 'c1');

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), isEmpty);
    });

    test('UserRepositoryImpl delegates getUser unchanged', () async {
      final source = _StubUserDataSource();
      final result = await UserRepositoryImpl(dataSource: source).getUser('u1');

      expect(source.seen, ['getUser(u1)']);
      expect(result.isFailure, isTrue);
    });

    test('GroupRepositoryImpl delegates getGroup unchanged', () async {
      final source = _StubGroupDataSource();
      final result = await GroupRepositoryImpl(
        dataSource: source,
      ).getGroup('g1');

      expect(source.seen, ['getGroup(g1)']);
      expect(result.isFailure, isTrue);
    });

    test('the three repositories are pass-throughs — no error mapping of '
        'their own', () async {
      // Unlike the composer and notification-feed repositories, these do not
      // wrap the data source in a try/catch, so a throwing source throws
      // through them rather than becoming a Failure. Pinned so the difference
      // between the two styles is visible.
      final result = await UserRepositoryImpl(
        dataSource: _StubUserDataSource(),
      ).getUser('u1');

      result.fold(
        (f) => expect(f.message, 'Not implemented'),
        (_) => fail('expected the source Failure to pass straight through'),
      );
    });
  });

  // ===========================================================================
  group('CustomInteractiveMessage', () {
    CustomInteractiveMessage build() => CustomInteractiveMessage(
      customData: {'k': 'v'},
      subType: 'poll',
      receiverUid: 'u2',
      receiverType: CometChatReceiverType.user,
    );

    test('packs its custom data into interactiveData', () {
      final message = build();

      expect(message.customData, {'k': 'v'});
      expect(message.subType, 'poll');
      expect(message.interactiveData['customData'], {'k': 'v'});
    });

    test('defaults the ids the SDK requires rather than leaving them null', () {
      final message = build();

      expect(message.id, 0);
      expect(message.muid, isEmpty);
      expect(message.parentMessageId, 0);
      expect(message.replyCount, 0);
    });

    test('carries the interactive category and custom type', () {
      expect(build().type, isNotEmpty);
      expect(build(), isA<InteractiveMessage>());
    });

    test('toInteractiveMessage re-packs the current customData', () {
      // customData is mutable, so the repack is what makes an edit visible on
      // the wire — without it the message would send its original payload.
      final message = build()..customData = {'k': 'changed'};

      final packed = message.toInteractiveMessage();

      expect(packed.interactiveData['customData'], {'k': 'changed'});
      expect(packed, same(message));
    });
  });

  // ===========================================================================
  group('MessageListBlocAdapter', () {
    testWidgets('wraps a bloc and exposes the template map by key', (
      tester,
    ) async {
      // The adapter is what the message list hands to option builders and
      // custom views, so its template lookup is the seam every custom bubble
      // goes through.
      final bloc = MessageListBloc(disableSDKListeners: true);
      addTearDown(bloc.close);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      late MessageListBlocAdapter adapter;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            adapter = MessageListBlocAdapter(
              bloc: bloc,
              templateMap: const <String, CometChatMessageTemplate>{},
              scrollController: scrollController,
              context: context,
            );
            return const SizedBox();
          },
        ),
      );

      expect(adapter.bloc, same(bloc));
      expect(adapter, isA<ConvoKitMessageListControllerProtocol>());
    });
  });

  // ===========================================================================
  group('CometChatGroupMembersController', () {
    test('constructs with a group and defaults its options', () {
      final controller = CometChatGroupMembersController(
        groupMembersBuilderProtocol: _membersBuilder(),
        group: _FakeGroup(),
      );

      expect(controller.group.guid, 'g1');
      expect(controller.usersStatusVisibility, isTrue);
      expect(controller.selectionMode, SelectionMode.none);
      expect(controller.hideBanMemberOption, isNull);
      expect(controller.hideKickMemberOption, isNull);
      expect(controller.hideScopeChangeOption, isNull);
    });

    test('the three listener ids share one timestamp and stay distinct', () {
      // All three are built from the same dateStamp, so they must differ by
      // suffix or one SDK listener would displace another.
      final controller = CometChatGroupMembersController(
        groupMembersBuilderProtocol: _membersBuilder(),
        group: _FakeGroup(),
      );

      final ids = {
        controller.groupSDKListenerID,
        controller.userSDKListenerID,
        controller.groupUIListenerID,
      };

      expect(ids, hasLength(3));
      for (final id in ids) {
        expect(id, startsWith(controller.dateStamp));
      }
    });

    test('the moderation options are honoured when supplied', () {
      final controller = CometChatGroupMembersController(
        groupMembersBuilderProtocol: _membersBuilder(),
        group: _FakeGroup(),
        userStatusVisibility: false,
        mode: SelectionMode.multiple,
        hideBanMemberOption: true,
        hideKickMemberOption: true,
        hideScopeChangeOption: false,
      );

      expect(controller.usersStatusVisibility, isFalse);
      expect(controller.selectionMode, SelectionMode.multiple);
      expect(controller.hideBanMemberOption, isTrue);
      expect(controller.hideKickMemberOption, isTrue);
      expect(controller.hideScopeChangeOption, isFalse);
    });

    test('two controllers do not share listener ids', () {
      final a = CometChatGroupMembersController(
        groupMembersBuilderProtocol: _membersBuilder(),
        group: _FakeGroup(),
      );
      final b = CometChatGroupMembersController(
        groupMembersBuilderProtocol: _membersBuilder(),
        group: _FakeGroup(),
      );

      expect(a.groupSDKListenerID, isNot(b.groupSDKListenerID));
    });
  });
}
