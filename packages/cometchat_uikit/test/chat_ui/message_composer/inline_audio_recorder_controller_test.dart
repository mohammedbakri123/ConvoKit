import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InlineAudioRecorderController', () {
    late InlineAudioRecorderController controller;

    setUp(() {
      controller = InlineAudioRecorderController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts idle and transitions through recording lifecycle', () {
      expect(controller.state.status, InlineAudioRecorderStatus.idle);

      controller.startRecording();
      expect(controller.state.isRecording, isTrue);

      controller.updateDuration(const Duration(seconds: 3));
      controller.updateAmplitude(0.75);
      expect(controller.state.duration, const Duration(seconds: 3));
      expect(controller.state.amplitudes, [0.75]);

      controller.pauseRecording();
      expect(controller.state.isPaused, isTrue);

      controller.resumeRecording(isFreshRestart: false);
      expect(controller.state.isRecording, isTrue);
      expect(controller.state.duration, const Duration(seconds: 3));

      controller.stopRecording();
      expect(controller.state.isCompleted, isTrue);
      expect(controller.state.hasRecording, isTrue);
    });

    test('handles playback, seek, error, and cancel/reset', () {
      controller.recordingCompleted(
        filePath: '/tmp/voice.m4a',
        duration: const Duration(seconds: 10),
      );
      expect(controller.state.filePath, '/tmp/voice.m4a');

      controller.playRecording();
      expect(controller.state.isPlaying, isTrue);

      controller.seekToPosition(0.5);
      expect(controller.state.currentPosition, const Duration(seconds: 5));

      controller.pausePlayback();
      expect(controller.state.isPaused, isTrue);

      controller.recordingError('mic unavailable');
      expect(controller.state.hasError, isTrue);
      expect(controller.state.errorMessage, 'mic unavailable');

      controller.cancelRecording();
      expect(controller.state.isIdle, isTrue);
      expect(controller.state.duration, Duration.zero);
    });
  });
}
