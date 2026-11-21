import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// video_player does not re-export the platform interface, and the interface is
// the only seam for faking playback in headless widget tests.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Installs a fresh [FakeVideoPlayerPlatform] as [VideoPlayerPlatform.instance]
/// so audio/video/voice-note bubbles do not hit the real platform in widget
/// tests.
FakeVideoPlayerPlatform installFakeVideoPlayerPlatform({
  Duration duration = const Duration(seconds: 30),
}) {
  final fake = FakeVideoPlayerPlatform(duration: duration);
  VideoPlayerPlatform.instance = fake;
  return fake;
}

/// Pumps a bounded sequence of frames so async loads, route transitions, and
/// debounced callbacks complete without timing out on repeating animations
/// such as `ConvoKitShimmerEffect` or indeterminate progress indicators.
Future<void> pumpShowcaseFrames(
  WidgetTester tester, {
  int frames = 10,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Headless [VideoPlayerPlatform] fake for widget tests in `showcase_app`.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({this.duration = const Duration(seconds: 30)});

  final Duration duration;
  bool failCreate = false;
  bool failPlay = false;

  int _nextId = 1;
  final Map<int, StreamController<VideoEvent>> _streams =
      <int, StreamController<VideoEvent>>{};
  final Map<int, Duration> _positions = <int, Duration>{};

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failCreate) {
      throw PlatformException(
        code: 'VideoError',
        message: 'fake create failed',
      );
    }
    final id = _nextId++;
    _streams[id] = StreamController<VideoEvent>.broadcast();
    _positions[id] = Duration.zero;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = _streams[playerId];
    if (controller == null) return const Stream<VideoEvent>.empty();
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: duration,
            size: const Size(640, 480),
          ),
        );
      }
    });
    return controller.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    _positions.remove(playerId);
    await _streams.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    if (failPlay) {
      throw PlatformException(
        code: 'VideoError',
        message: 'fake play failed',
      );
    }
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async =>
      _positions[playerId] ?? Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) =>
      const ColoredBox(color: Color(0xFF000000), child: SizedBox.expand());
}
