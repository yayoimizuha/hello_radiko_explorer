import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:isolate';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

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
    final receivePort = ReceivePort();
    await Isolate.spawn(_base64DecodeIsolate, [receivePort.sendPort, data]);
    return await receivePort.first as Uint8List;
  }

  static void _base64DecodeIsolate(List<dynamic> args) {
    SendPort sendPort = args[0];
    String data = args[1];
    final decoded = base64.decode(data);
    sendPort.send(decoded);
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

  static Stream<PlayerState> get playerStateStream => _audioPlayer.onPlayerStateChanged;
}
