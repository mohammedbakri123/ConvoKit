/// [MediaRecorderController] — the state machine behind the voice-note recorder.
library;

import 'package:convokit/shared_ui/src/clean_architecture/presentation/views/components/media_recorder/media_recorder_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaRecorderState', () {
    test('boolean getters reflect each concrete state', () {
      const initial = MediaRecorderInitial();
      expect(initial.isRecording, isFalse);
      expect(initial.isPaused, isFalse);
      expect(initial.isCompleted, isFalse);
      expect(initial.hasError, isFalse);
      expect(initial.canRecord, isFalse);

      const ready = MediaRecorderReady();
      expect(ready.canRecord, isTrue);

      const rec = MediaRecorderRecording(
        duration: Duration(seconds: 2),
        amplitudes: [0.5],
      );
      expect(rec.isRecording, isTrue);
      expect(rec.canRecord, isFalse);

      const paused = MediaRecorderPaused(
        duration: Duration(seconds: 2),
        amplitudes: [0.5],
      );
      expect(paused.isPaused, isTrue);

      const done = MediaRecorderCompleted(
        duration: Duration(seconds: 3),
        filePath: '/tmp/voice.m4a',
      );
      expect(done.isCompleted, isTrue);
      expect(done.canRecord, isTrue);

      const err = MediaRecorderError(error: 'mic denied');
      expect(err.hasError, isTrue);
    });
  });

  group('MediaRecorderController lifecycle', () {
    test('transitions initial -> ready -> recording -> paused -> recording -> completed', () {
      final controller = MediaRecorderController();
      addTearDown(controller.dispose);

      expect(controller.state, isA<MediaRecorderInitial>());

      controller.initialize();
      expect(controller.state, isA<MediaRecorderReady>());

      controller.startRecording();
      expect(controller.state, isA<MediaRecorderRecording>());

      controller.pauseRecording();
      expect(controller.state, isA<MediaRecorderPaused>());

      controller.resumeRecording();
      expect(controller.state, isA<MediaRecorderRecording>());

      controller.stopRecording(filePath: '/tmp/out.m4a');
      expect(controller.state, isA<MediaRecorderCompleted>());
      expect(controller.state.filePath, '/tmp/out.m4a');
    });

    test('cancelRecording returns to MediaRecorderReady', () {
      final controller = MediaRecorderController();
      addTearDown(controller.dispose);

      controller.startRecording();
      controller.cancelRecording();
      expect(controller.state, isA<MediaRecorderReady>());
    });

    test('setError transitions to MediaRecorderError', () {
      final controller = MediaRecorderController();
      addTearDown(controller.dispose);

      controller.startRecording();
      controller.setError('permission denied');
      expect(controller.state, isA<MediaRecorderError>());
      expect(controller.state.error, 'permission denied');
    });
  });
}
