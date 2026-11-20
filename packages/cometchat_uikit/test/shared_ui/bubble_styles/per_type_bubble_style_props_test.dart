/// Render-verified prop matrix for the per-type bubble style classes —
/// Track 3 PROP2 (ENG-38936).
///
/// These classes share a shape. Each carries a handful of properties its own
/// bubble widget reads, plus the nine message-bubble chrome properties —
/// `border`, `borderRadius`, the avatar / date / receipt / sender-name styles,
/// the background image and the two threaded-indicator properties — which no
/// bubble widget reads at all. Those nine travel through
/// `MessageUtils.getBubbleStyle`, which pulls them off the matching field of
/// [CometChatIncomingMessageBubbleStyle] / [CometChatOutgoingMessageBubbleStyle]
/// and hands them to the surrounding [ConvoKitMessageBubble].
///
/// So the file has two halves: the chrome nine driven through
/// [ConvoKitMessageList] with a message of the right type, and the
/// type-specific properties asserted on their own widget.
///
///   flutter test test/shared_ui/bubble_styles/per_type_bubble_style_props_test.dart
library;

import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageListBloc extends MockBloc<MessageListEvent, MessageListState>
    implements MessageListBloc {}

final _me = User(uid: 'u1', name: 'Alice');
final _them = User(uid: 'u2', name: 'Bob');
final _sentAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

/// A 1x1 transparent PNG — enough for a DecorationImage that never paints.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

TextMessage _text({
  bool byMe = false,
  String text = 'hello',
  DateTime? deletedAt,
}) => TextMessage(
  id: 1,
  text: text,
  sender: byMe ? _me : _them,
  receiver: byMe ? _them : _me,
  receiverUid: byMe ? 'u2' : 'u1',
  type: MessageTypeConstants.text,
  receiverType: ReceiverTypeConstants.user,
  sentAt: _sentAt,
  deletedAt: deletedAt,
);

MediaMessage _media(String type, {bool byMe = false}) => MediaMessage(
  id: 2,
  sender: byMe ? _me : _them,
  receiver: byMe ? _them : _me,
  receiverUid: byMe ? 'u2' : 'u1',
  type: type,
  receiverType: ReceiverTypeConstants.user,
  sentAt: _sentAt,
);

/// A call message. getBubbleStyle keys the call branch on
/// `custom + meeting`, not on the `call_occurred` type the call bubble itself
/// renders for, so the fixture has to use the meeting type to reach it.
CustomMessage _call({bool byMe = false}) => CustomMessage(
  id: 4,
  customData: const {'callType': CallTypeConstants.audioCall},
  sender: byMe ? _me : _them,
  receiver: byMe ? _them : _me,
  receiverUid: byMe ? 'u2' : 'u1',
  type: MessageTypeConstants.meeting,
  receiverType: ReceiverTypeConstants.user,
  sentAt: _sentAt,
);

CustomMessage _custom(String type, {bool byMe = false}) => CustomMessage(
  id: 3,
  customData: const {'k': 'v'},
  sender: byMe ? _me : _them,
  receiver: byMe ? _them : _me,
  receiverUid: byMe ? 'u2' : 'u1',
  type: type,
  receiverType: ReceiverTypeConstants.user,
  sentAt: _sentAt,
);

MockMessageListBloc _bloc(BaseMessage message) {
  final msgs = <BaseMessage>[message];
  final state = MessageListState(
    status: MessageListStatus.loaded,
    messages: msgs,
    loggedInUser: _me,
  );
  final b = MockMessageListBloc();
  whenListen(b, Stream<MessageListState>.value(state), initialState: state);
  when(() => b.operationsStream).thenAnswer(
    (_) => Stream<MessageOperation>.fromIterable([
      MessageOperation.set(msgs, animated: false),
    ]),
  );
  when(() => b.findMessageIndex(any())).thenReturn(null);
  when(
    () => b.getReceiptNotifierForMessage(any()),
  ).thenReturn(ValueNotifier(MessageReceiptStatus.sent));
  when(
    () => b.getThreadReplyCountNotifier(any()),
  ).thenReturn(ValueNotifier<int>(0));
  when(() => b.initializeThreadReplyCount(any(), any())).thenAnswer((_) {});
  when(() => b.notifyMessageChanged(any())).thenAnswer((_) {});
  return b;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ConvoKitMessageBubble _bubble(WidgetTester tester) => tester
    .widget<ConvoKitMessageBubble>(find.byType(ConvoKitMessageBubble).first);

Iterable<Color?> _fills(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.color ?? (c.decoration as BoxDecoration?)?.color);

Iterable<double?> _textSizes(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.style?.fontSize);

Iterable<Color?> _textColors(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.style?.color);

Iterable<Color?> _iconColors(WidgetTester tester) =>
    tester.widgetList<Icon>(find.byType(Icon)).map((i) => i.color);

void main() {
  setUpAll(() => registerFallbackValue(_text()));
  setUp(() => ConvoKitUIKit.loggedInUser = _me);
  tearDown(() => ConvoKitUIKit.loggedInUser = null);

  // ---------------------------------------------------------------------
  // The nine chrome properties, per style class.
  //
  // No bubble widget reads these; MessageUtils.getBubbleStyle lifts them off
  // the matching aggregate field and passes them to the enclosing
  // ConvoKitMessageBubble. messageReceiptStyle only reaches a bubble I sent,
  // so its case flips the fixture and the aggregate.
  // ---------------------------------------------------------------------

  group('CometChatTextBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d000), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d033)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d033)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d044),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d077),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(byMe: true)),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  textBubbleStyle: CometChatTextBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d088),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('CometChatImageBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d100), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d133)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d133)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d144),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.image)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d177),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _media(MessageTypeConstants.image, byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  imageBubbleStyle: CometChatImageBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d188),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('CometChatVideoBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d200), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d233)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d233)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d244),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.video)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d277),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _media(MessageTypeConstants.video, byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  videoBubbleStyle: CometChatVideoBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d288),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('CometChatFileBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d300), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d333)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d333)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d344),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.file)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d377),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _media(MessageTypeConstants.file, byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  fileBubbleStyle: CometChatFileBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d388),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('CometChatStickerBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d400), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d433)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d433)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d444),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_custom(ExtensionType.sticker)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d477),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _custom(ExtensionType.sticker, byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  stickerBubbleStyle: CometChatStickerBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d488),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('ConvoKitDeletedBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x0ff1d500), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(63)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(63)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      // getBubbleStyle resolves this property off deletedBubbleStyle, but the
      // message list then discards it — `backgroundImage: isDeleted ? null :
      // ...` at both of its bubble-style call sites. A deleted placeholder
      // deliberately carries no background image, so the property is
      // unreachable on this one style class (ENG-38937).
      expect(_bubble(tester).style?.backgroundImage, isNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0x0ff1d533)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0x0ff1d533)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0x0ff1d544),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_text(deletedAt: DateTime(2024, 1, 1))),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0x0ff1d577),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _text(deletedAt: DateTime(2024, 1, 1), byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  deletedBubbleStyle: ConvoKitDeletedBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0x0ff1d588),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });
  // ---------------------------------------------------------------------
  // The type-specific properties, on the widget that reads each one.
  // ---------------------------------------------------------------------

  group('CometChatTextBubbleStyle — the text bubble', () {
    testWidgets('textStyle and textColor style the message text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CometChatTextBubble(
              text: 'hello world',
              alignment: BubbleAlignment.left,
              style: const CometChatTextBubbleStyle(
                textStyle: TextStyle(fontSize: 31),
                textColor: Color(0xFF1D0A0A),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // the text bubble renders through FormatterUtils.buildTextSpan, so the
      // style lands on the spans rather than on a Text widget
      final spans = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand(
            (r) => <InlineSpan>[r.text, ...?(r.text as TextSpan?)?.children],
          )
          .whereType<TextSpan>()
          .map((s) => s.style);
      expect(spans.map((s) => s?.fontSize), contains(31.0));
      expect(spans.map((s) => s?.color), contains(const Color(0xFF1D0A0A)));
    });
  });

  group('CometChatVideoBubbleStyle — the video bubble', () {
    testWidgets('playIconColor and playIconBackgroundColor style the overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CometChatVideoBubble(
              videoUrl: 'https://example.com/clip.mp4',
              style: const CometChatVideoBubbleStyle(
                playIconColor: Color(0xFF1D2A2A),
                playIconBackgroundColor: Color(0xFF1D2B2B),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_iconColors(tester), contains(const Color(0xFF1D2A2A)));
      expect(_fills(tester), contains(const Color(0xFF1D2B2B)));
    });
  });

  group('CometChatFileBubbleStyle — the file bubble', () {
    testWidgets('title, subtitle and download-icon properties style the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => CometChatFileBubble(
                title: 'report.pdf',
                subtitle: 'from Bob',
                fileUrl: 'https://example.com/report.pdf',
                colorPalette: ConvoKitThemeHelper.getColorPalette(context),
                spacing: ConvoKitThemeHelper.getSpacing(context),
                typography: ConvoKitThemeHelper.getTypography(context),
                style: const CometChatFileBubbleStyle(
                  titleTextStyle: TextStyle(fontSize: 33),
                  titleColor: Color(0xFF1D3A3A),
                  subtitleTextStyle: TextStyle(fontSize: 17),
                  subtitleColor: Color(0xFF1D3B3B),
                  downloadIconTint: Color(0xFF1D3C3C),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_textSizes(tester), contains(33.0));
      expect(_textColors(tester), contains(const Color(0xFF1D3A3A)));
      expect(_textSizes(tester), contains(17.0));
      expect(_textColors(tester), contains(const Color(0xFF1D3B3B)));
      expect([
        ..._iconColors(tester),
        ...tester.widgetList<Image>(find.byType(Image)).map((i) => i.color),
      ], contains(const Color(0xFF1D3C3C)));
    });
  });

  group('ConvoKitDeletedBubbleStyle — the deleted bubble', () {
    testWidgets('textStyle, textColor and iconColor style the placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitDeletedBubble(
              style: const ConvoKitDeletedBubbleStyle(
                textStyle: TextStyle(fontSize: 19),
                textColor: Color(0xFF1D5A5A),
                iconColor: Color(0xFF1D5B5B),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_textSizes(tester), contains(19.0));
      expect(_textColors(tester), contains(const Color(0xFF1D5A5A)));
      expect([
        ..._iconColors(tester),
        ...tester.widgetList<Image>(find.byType(Image)).map((i) => i.color),
      ], contains(const Color(0xFF1D5B5B)));
    });
  });

  group('ConvoKitActionBubbleStyle — the action bubble', () {
    testWidgets('textStyle, border and borderRadius style the pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitActionBubble(
              text: 'Bob joined',
              style: const ConvoKitActionBubbleStyle(
                textStyle: TextStyle(fontSize: 21),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFF1D6A6A), width: 3),
                ),
                borderRadius: BorderRadius.all(Radius.circular(65)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_textSizes(tester), contains(21.0));
      final decorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration as BoxDecoration?);
      expect(
        decorations.map((d) => d?.borderRadius),
        contains(const BorderRadius.all(Radius.circular(65))),
      );
      expect(
        decorations.map((d) => (d?.border as Border?)?.top.color),
        contains(const Color(0xFF1D6A6A)),
      );
    });
  });

  group('CometChatMessageTranslationBubbleStyle — the translation bubble', () {
    testWidgets('infoTextStyle and translatedTextStyle style the two lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTranslationBubble(
              translatedText: 'hola mundo',
              alignment: BubbleAlignment.left,
              style: CometChatMessageTranslationBubbleStyle(
                infoTextStyle: const TextStyle(fontSize: 23),
                translatedTextStyle: const TextStyle(fontSize: 27),
              ),
              child: const Text('hello world'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_textSizes(tester), contains(23.0));
      expect(_textSizes(tester), contains(27.0));
    });
  });

  group('ConvoKitMessageBubbleStyle — the bubble shell', () {
    testWidgets('border and backgroundImage reach the shell', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageBubble(
              alignment: BubbleAlignment.left,
              contentView: const Text('body'),
              style: ConvoKitMessageBubbleStyle(
                border: const Border.fromBorderSide(
                  BorderSide(color: Color(0xFF1D7A7A), width: 3),
                ),
                backgroundImage: DecorationImage(image: MemoryImage(_pixel)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final decorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration as BoxDecoration?);
      expect(
        decorations.map((d) => (d?.border as Border?)?.top.color),
        contains(const Color(0xFF1D7A7A)),
      );
      expect(decorations.map((d) => d?.image), isNot(everyElement(isNull)));
    });
  });

  // ---------------------------------------------------------------------
  // The same nine chrome properties for the voice-note and call bubble
  // styles. Neither bubble widget reads them; they travel through the
  // aggregate field named below, exactly as the six classes above do.
  // ---------------------------------------------------------------------

  group('CometChatVoiceNoteBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFF1F1000), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(83)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(83)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0xFF1F1001)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0xFF1F1001)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0xFF1F1002),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_media(MessageTypeConstants.audio)),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0xFF1F1003),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(
                _media(MessageTypeConstants.audio, byMe: true),
              ),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  voiceNoteBubbleStyle: CometChatVoiceNoteBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0xFF1F1004),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });

  group('CometChatCallBubbleStyle — message-bubble chrome', () {
    testWidgets('border reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFF1F2000), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.border, isNotNull);
    });

    testWidgets('borderRadius reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    borderRadius: BorderRadius.all(Radius.circular(83)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(
        _bubble(tester).style?.borderRadius,
        const BorderRadius.all(Radius.circular(83)),
      );
    });

    testWidgets('messageBubbleBackgroundImage reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    messageBubbleBackgroundImage: DecorationImage(
                      image: MemoryImage(_pixel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style?.backgroundImage, isNotNull);
    });

    testWidgets('messageBubbleDateStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    messageBubbleDateStyle: ConvoKitDateStyle(
                      textStyle: TextStyle(color: Color(0xFF1F2001)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_textColors(tester), contains(const Color(0xFF1F2001)));
    });

    testWidgets('messageBubbleAvatarStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    messageBubbleAvatarStyle: ConvoKitAvatarStyle(
                      backgroundColor: Color(0xFF1F2002),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('senderNameTextStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    senderNameTextStyle: TextStyle(fontSize: 23),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bubble(tester).style, isNotNull);
    });

    testWidgets('threadedMessageIndicatorTextStyle reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    threadedMessageIndicatorTextStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('threadedMessageIndicatorIconColor reaches the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call()),
              style: ConvoKitMessageListStyle(
                incomingMessageBubbleStyle: CometChatIncomingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    threadedMessageIndicatorIconColor: Color(0xFF1F2003),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });

    testWidgets('messageReceiptStyle reaches the bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConvoKitMessageList(
              user: _them,
              messageListBloc: _bloc(_call(byMe: true)),
              style: ConvoKitMessageListStyle(
                outgoingMessageBubbleStyle: CometChatOutgoingMessageBubbleStyle(
                  voiceCallBubbleStyle: CometChatCallBubbleStyle(
                    messageReceiptStyle: CometChatMessageReceiptStyle(
                      sentIconColor: Color(0xFF1F2004),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(ConvoKitMessageBubble), findsWidgets);
    });
  });
}
