import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:convert';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? currentPlayingDownloadId;

  static Future<bool> isPlaying() async {
    // This is a simple implementation based on our tracking variable.
    // In a more robust solution, you might use _audioPlayer.onPlayerStateChanged.
    return currentPlayingDownloadId != null;
  }

  static Future<void> playAudioData(dynamic audioData) async {
    print("audioData.runtimeType:${audioData.runtimeType}");

    try {
      // Asynchronously decode base64 encoded string in a separate isolate.
      if (audioData is Uint8List) {
        await _audioPlayer.play(BytesSource(audioData));
      } else if (audioData is String) {
        if (audioData.startsWith("http")) {
          await _audioPlayer.play(UrlSource(audioData));
        } else {
          Uint8List decodedData = await _decodeBase64(audioData);
          await _audioPlayer.play(BytesSource(decodedData));
        }
      }
    } catch (e) {
      print("_decodeBase64 error: $e");
      // If decoding fails, assume it's a URL or file path.
      // await _audioPlayer.play(UrlSource(audioData));
    }
  }

  static Future<Uint8List> _decodeBase64(String data) async {
    Uint8List? result;
    final sink = ByteConversionSink.withCallback((bytes) {
      result = Uint8List.fromList(bytes);
    });
    final converter = base64.decoder.startChunkedConversion(sink);
    String remainder = "";
    const int chunkSize = 1024 * 256;
    int pos = 0;
    while (pos < data.length) {
      int end = pos + chunkSize;
      if (end > data.length) {
        end = data.length;
      }
      String chunk = remainder + data.substring(pos, end);
      int completeLength = chunk.length - (chunk.length % 4);
      if (completeLength > 0) {
        converter.add(chunk.substring(0, completeLength));
        remainder = chunk.substring(completeLength);
      } else {
        remainder = chunk;
      }
      pos = end;
      await Future.delayed(Duration(milliseconds: 2));
    }
    if (remainder.isNotEmpty) {
      converter.add(remainder);
    }
    converter.close();
    return result!;
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
