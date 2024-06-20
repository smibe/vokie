import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class TimedAudioPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _stopTimer;

  Future<void> playFromPath(String path, {int startSeconds = 0, int? durationSeconds}) async {
    if (_audioPlayer.state != PlayerState.stopped) {
      await _audioPlayer.stop();
    }
    _stopTimer?.cancel();

    await _audioPlayer.setSourceDeviceFile(path);
    await _audioPlayer.seek(Duration(seconds: startSeconds));

    if (durationSeconds != null) {
      _stopTimer = Timer(Duration(seconds: durationSeconds), () {
        _audioPlayer.stop();
      });
    }

    await _audioPlayer.resume();
  }

  Stream<PlayerState> get stateChanged => _audioPlayer.onPlayerStateChanged;

  Future<void> stop() async {
    await _audioPlayer.stop();
    _stopTimer?.cancel();
  }

  void dispose() {
    _audioPlayer.dispose();
    _stopTimer?.cancel();
  }
}
