import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../cometchat_uikit_shared.dart';
import '../logging/cometchat_log.dart';
import '../clean_architecture/core/utils/platform_utils/platform_file_utils.dart'
    as platform;

///[SoundManager] is an utility component that provides an audio player
class SoundManager {
  ///[SoundManager] is a singleton class so use this to initialize the instance of this class.
  static final SoundManager _instance = SoundManager._internal();

  ///This method is used to get the instance of this class.
  factory SoundManager() => _instance;

  SoundManager._internal();

  /// Plays [sound], or [customSound] from [packageName]'s assets.
  void play({
    required Sound sound,
    String? customSound,
    String? packageName, // Use it only when using other plugin
    bool? isLooping = false,
  }) async {
    if (kIsWeb) return;

    String soundPath = "";

    if (customSound != null && customSound.isNotEmpty) {
      soundPath = customSound;
    } else {
      soundPath = _getDefaultSoundPath(sound);
      packageName ??= UIConstants.packageName;
      if (platform.platformIsAndroid()) {
        soundPath = "packages/$packageName/$soundPath";
      }
    }
    try {
      await UIConstants.channel.invokeMethod("playCustomSound", {
        'assetAudioPath': soundPath,
        'package': packageName,
        'isLooping': isLooping,
      });
    } catch (e) {
      if (e.toString().contains('AUDIO_FOCUS_FAILED')) {
        ccLog('Audio focus not available. Notification sound skipped.');
      } else {
        ccLog('Error playing sound: $e');
      }
    }
  }

  /// Stops what the UI Kit is playing.
  void stop() async {
    if (kIsWeb) return;
    await UIConstants.channel.invokeMethod("stopPlayer", {});
  }

  String _getDefaultSoundPath(Sound sound) {
    String soundType = "assets/beep.mp3";
    switch (sound) {
      case Sound.incomingMessage:
        soundType = "assets/sound/incoming_message.wav";
        break;
      case Sound.outgoingMessage:
        soundType = "assets/sound/outgoing_message.wav";
        break;
      case Sound.incomingMessageFromOther:
        soundType = "assets/sound/incoming_message.wav";
        break;
      case Sound.outgoingCall:
        soundType = "assets/sound/outgoing_call.wav";
        break;
      case Sound.incomingCall:
        soundType = "assets/sound/incoming_call.wav";
        break;
    }

    return soundType;
  }
}

enum Sound {
  incomingMessage,
  outgoingMessage,
  incomingMessageFromOther,
  outgoingCall,
  incomingCall,
}
