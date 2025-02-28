import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:isolate';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentPlayingDownloadId;

  static Future<bool> isPlaying() async {
    // This is a simple implementation based on our tracking variable.
    // In a more robust solution, you might use _audioPlayer.onPlayerStateChanged.
    return currentPlayingDownloadId != null;
  }

  static Future<void> playAudioData(dynamic audioData) async {
    if (audioData is Uint8List) {
      await _audioPlayer.play(BytesSource(audioData));
    } else if (audioData is String) {
      try {
        // Asynchronously decode base64 encoded string in a separate isolate.
        Uint8List decodedData = await _decodeBase64(audioData);
        await _audioPlayer.play(BytesSource(decodedData));
      } catch (_) {
        // If decoding fails, assume it's a URL or file path.
        await _audioPlayer.play(UrlSource(audioData));
      }
    } else {
      throw Exception("Unsupported audioData format");
    }
  }

  static Future<Uint8List> _decodeBase64(String data) async {
    const chunkSize = 1024 * 256;
    final fullBuffer = BytesBuilder(copy: false);

    for (int i = 0; i < data.length; i += chunkSize) {
      final part = data.substring(
        i,
        i + chunkSize < data.length ? i + chunkSize : data.length,
      );
      Uint8List decodedPart = base64Decode(part);
      fullBuffer.add(decodedPart);
      await Future.delayed(Duration(milliseconds: 2));
      // print('Delay finished for chunk from $i');
    }

    return fullBuffer.toBytes();
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
  }

  static Future<void> resume() async {
    await _audioPlayer.resume();
  }

  static Future<void> stop() async {
    await _audioPlayer.stop();
    currentPlayingDownloadId = null;
  }

  // static Future<void> skipForward() async {
  //   final current = await _audioPlayer.getCurrentPosition() ?? Duration.zero;
  //   final newPosition = current + const Duration(seconds: 30);
  //   await _audioPlayer.seek(newPosition);
  // }

  static Future<void> skipSize(int move) async {
    final current = await _audioPlayer.getCurrentPosition() ?? Duration.zero;
    Duration newPosition = current + Duration(seconds: move);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    await _audioPlayer.seek(newPosition);
  }

  static Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  static Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  static Stream<Duration?> get durationStream => _audioPlayer.onDurationChanged;
  static Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  static String? getCurrentPlayingDownloadId() {
    return currentPlayingDownloadId;
  }
}
