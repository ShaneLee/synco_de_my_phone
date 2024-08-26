import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerManager {
  final AudioPlayer _player = AudioPlayer();
  String? path;
  String? _currentlyPlayingPath;

  bool isPlaying(String? pathA, String? pathB) {
    return pathA == _currentlyPlayingPath || pathB == _currentlyPlayingPath;
  }

  Future<void> setUpPlayer(String filePath, {bool isUrl = false}) async {
    // Set up the player with necessary context (e.g., keep awake)
    if (Platform.isAndroid) {
      await _player.setAudioContext(AudioContext(android: const AudioContextAndroid(stayAwake: true)));
    } else if (Platform.isIOS) {
      await _player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
      ));
    }

    // Set source
    if (isUrl) {
      await _player.setSource(UrlSource(filePath));
    } else {
      await _player.setSource(DeviceFileSource(filePath));
    }

    // Handle state changes
    _player.onPlayerStateChanged.listen((state) {
      _currentlyPlayingPath = state == PlayerState.playing ? filePath : null;
    });
  }

  Future<void> play() async {
    await _player.resume();
    _currentlyPlayingPath = path;
  }

  Future<void> pause() async {
    await _player.pause();
    _currentlyPlayingPath = null;
  }

  void dispose() {
    _player.dispose();
  }
}
