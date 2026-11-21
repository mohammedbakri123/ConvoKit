import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'inline_audio_recorder_state.dart';

/// Lightweight [ChangeNotifier] controller for managing inline audio recorder state.
///
/// Replaces the legacy `InlineAudioRecorderBloc` with zero `flutter_bloc` dependency.
class InlineAudioRecorderController extends ChangeNotifier {
  InlineAudioRecorderState _state = const InlineAudioRecorderState();
  InlineAudioRecorderState get state => _state;

  Timer? _durationTimer;
  Timer? _playbackTimer;
  bool _disposed = false;

  /// Method channel for native audio operations.
  static const MethodChannel _channel = MethodChannel('cometchat_chat_uikit');

  void _emit(InlineAudioRecorderState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  void startRecording() {
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.recording,
        duration: Duration.zero,
        amplitudes: const [],
        filePath: null,
        errorMessage: null,
      ),
    );
    _startDurationTimer();
  }

  void pauseRecording() {
    _stopDurationTimer();
    _emit(_state.copyWith(status: InlineAudioRecorderStatus.paused));
  }

  void resumeRecording({bool isFreshRestart = false}) {
    if (isFreshRestart) {
      _emit(
        _state.copyWith(
          status: InlineAudioRecorderStatus.recording,
          duration: Duration.zero,
          amplitudes: const [],
          currentPosition: Duration.zero,
        ),
      );
    } else {
      _emit(_state.copyWith(status: InlineAudioRecorderStatus.recording));
    }
    _startDurationTimer();
  }

  void stopRecording() {
    _stopDurationTimer();
    _emit(_state.copyWith(status: InlineAudioRecorderStatus.completed));
  }

  void cancelRecording() {
    _stopDurationTimer();
    _stopPlaybackTimer();
    _emit(const InlineAudioRecorderState());
  }

  void playRecording() {
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.playing,
        currentPosition: Duration.zero,
      ),
    );
    _startPlaybackTimer();
  }

  void pausePlayback() {
    _stopPlaybackTimer();
    _emit(_state.copyWith(status: InlineAudioRecorderStatus.paused));
  }

  void resumePlayback() {
    _emit(_state.copyWith(status: InlineAudioRecorderStatus.playing));
    _startPlaybackTimer();
  }

  void updateDuration(Duration duration) {
    _emit(_state.copyWith(duration: duration));
  }

  void updatePlaybackPosition(Duration position) {
    _emit(_state.copyWith(currentPosition: position));
  }

  void updateAmplitude(double amplitude) {
    final newAmplitudes = [
      ..._state.amplitudes,
      amplitude.clamp(0.0, 1.0),
    ];
    _emit(_state.copyWith(amplitudes: newAmplitudes));
  }

  void recordingCompleted({
    required String filePath,
    required Duration duration,
  }) {
    _stopDurationTimer();
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.completed,
        filePath: filePath,
        duration: duration,
      ),
    );
  }

  void playbackCompleted() {
    _stopPlaybackTimer();
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.completed,
        currentPosition: Duration.zero,
      ),
    );
  }

  void recordingError(String message) {
    _stopDurationTimer();
    _stopPlaybackTimer();
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.error,
        errorMessage: message,
      ),
    );
  }

  void resetRecorder() {
    _stopDurationTimer();
    _stopPlaybackTimer();
    _emit(const InlineAudioRecorderState());
  }

  void seekToPosition(double progress) {
    final newPosition = Duration(
      milliseconds: (_state.duration.inMilliseconds * progress).round(),
    );
    _stopPlaybackTimer();
    _emit(
      _state.copyWith(
        status: InlineAudioRecorderStatus.playing,
        currentPosition: newPosition,
      ),
    );
    _startPlaybackTimer();
  }

  void setExtractedWaveform(List<double> waveform) {
    _emit(_state.copyWith(extractedWaveform: waveform));
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    final startDuration = _state.duration;
    final startTime = DateTime.now();

    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = DateTime.now().difference(startTime);
      updateDuration(startDuration + elapsed);
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        if (_disposed) return;
        try {
          final status = await _channel.invokeMethod('getPlaybackStatus', {});
          if (_disposed) return;
          if (status is Map) {
            final isPlaying = status['isPlaying'] as bool? ?? false;
            final currentPosition = status['currentPosition'] as int? ?? 0;
            if (!isPlaying) {
              playbackCompleted();
            } else {
              updatePlaybackPosition(Duration(milliseconds: currentPosition));
            }
          }
        } catch (_) {
          // Ignore platform polling errors when native player is unavailable.
        }
      },
    );
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopDurationTimer();
    _stopPlaybackTimer();
    super.dispose();
  }
}
