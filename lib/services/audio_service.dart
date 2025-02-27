import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:convert';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playAudioData(dynamic audioData) async {
    if (audioData is Uint8List) {
      await _audioPlayer.play(BytesSource(audioData));
    } else if (audioData is String) {
      try {
        // Try to decode base64 encoded string.
        Uint8List decodedData = base64.decode(audioData);
        await _audioPlayer.play(BytesSource(decodedData));
      } catch (_) {
        // If decoding fails, assume it's a URL or file path.
        await _audioPlayer.play(UrlSource(audioData));
      }
    } else {
      throw Exception("Unsupported audioData format");
    }
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
  }

  static Future<void> resume() async {
    await _audioPlayer.resume();
  }

  static Future<void> stop() async {
    await _audioPlayer.stop();
  }
}