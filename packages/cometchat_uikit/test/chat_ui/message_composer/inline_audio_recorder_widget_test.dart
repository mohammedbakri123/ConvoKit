import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('cometchat_chat_uikit');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'startRecordingAudio':
              return true;
            case 'stopRecordingAudio':
              return '/tmp/recorded.m4a';
            case 'pauseRecordingAudio':
            case 'resumeRecordingAudio':
            case 'releaseMediaResources':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('CometChatInlineAudioRecorder renders and invokes onCancel', (
    tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [Translations.delegate],
        home: Scaffold(
          body: CometChatInlineAudioRecorder(
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CometChatInlineAudioRecorder), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cancelled, isTrue);
  });
}
