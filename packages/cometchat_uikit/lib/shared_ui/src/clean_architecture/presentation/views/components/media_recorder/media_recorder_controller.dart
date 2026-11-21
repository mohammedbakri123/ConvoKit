import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

abstract class MediaRecorderState extends Equatable {
  final Duration duration;
  final List<double> amplitudes;
  final String? filePath;
  final String? error;

  const MediaRecorderState({
    this.duration = Duration.zero,
    this.amplitudes = const [],
    this.filePath,
    this.error,
  });

  bool get isRecording => this is MediaRecorderRecording;
  bool get isPaused => this is MediaRecorderPaused;
  bool get isCompleted => this is MediaRecorderCompleted;
  bool get hasError => this is MediaRecorderError;
  bool get canRecord =>
      this is MediaRecorderReady || this is MediaRecorderCompleted;

  @override
  List<Object?> get props => [duration, amplitudes, filePath, error];
}

class MediaRecorderInitial extends MediaRecorderState {
  const MediaRecorderInitial();
}

class MediaRecorderReady extends MediaRecorderState {
  const MediaRecorderReady();
}

class MediaRecorderRecording extends MediaRecorderState {
  const MediaRecorderRecording({
    required super.duration,
    required super.amplitudes,
  });

  MediaRecorderRecording copyWith({
    Duration? duration,
    List<double>? amplitudes,
  }) {
    return MediaRecorderRecording(
      duration: duration ?? this.duration,
      amplitudes: amplitudes ?? this.amplitudes,
    );
  }
}

class MediaRecorderPaused extends MediaRecorderState {
  const MediaRecorderPaused({
    required super.duration,
    required super.amplitudes,
  });
}

class MediaRecorderCompleted extends MediaRecorderState {
  const MediaRecorderCompleted({
    required super.duration,
    required super.filePath,
  });
}

class MediaRecorderError extends MediaRecorderState {
  const MediaRecorderError({required super.error});
}

/// Plain [ChangeNotifier] controller replacing the legacy `MediaRecorderBloc`.
class MediaRecorderController extends ChangeNotifier {
  MediaRecorderState _state;
  Timer? _timer;
  StreamSubscription? _amplitudeSubscription;

  MediaRecorderController([MediaRecorderState? initialState])
      : _state = initialState ?? const MediaRecorderInitial();

  MediaRecorderState get state => _state;

  void _emit(MediaRecorderState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void initialize() {
    _emit(const MediaRecorderReady());
  }

  void startRecording() {
    _emit(const MediaRecorderRecording(duration: Duration.zero, amplitudes: []));
    _startTimer();
  }

  void stopRecording({String? filePath}) {
    _stopTimer();
    _amplitudeSubscription?.cancel();
    _emit(MediaRecorderCompleted(duration: _state.duration, filePath: filePath));
  }

  void pauseRecording() {
    _stopTimer();
    if (_state is MediaRecorderRecording) {
      _emit(MediaRecorderPaused(
        duration: _state.duration,
        amplitudes: _state.amplitudes,
      ));
    }
  }

  void resumeRecording() {
    if (_state is MediaRecorderPaused) {
      _emit(MediaRecorderRecording(
        duration: _state.duration,
        amplitudes: _state.amplitudes,
      ));
      _startTimer();
    }
  }

  void cancelRecording() {
    _stopTimer();
    _amplitudeSubscription?.cancel();
    _emit(const MediaRecorderReady());
  }

  void updateTimer(Duration duration) {
    if (_state is MediaRecorderRecording) {
      _emit((_state as MediaRecorderRecording).copyWith(duration: duration));
    }
  }

  void updateVisualizer(List<double> amplitudes) {
    if (_state is MediaRecorderRecording) {
      _emit((_state as MediaRecorderRecording).copyWith(amplitudes: amplitudes));
    }
  }

  void setError(String error) {
    _stopTimer();
    _amplitudeSubscription?.cancel();
    _emit(MediaRecorderError(error: error));
  }

  void _startTimer() {
    _timer?.cancel();
    final startTime = DateTime.now();
    final baseDuration = _state.duration;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = DateTime.now().difference(startTime);
      updateTimer(baseDuration + elapsed);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }
}
