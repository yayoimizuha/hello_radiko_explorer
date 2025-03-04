import 'dart:typed_data';
import 'dart:convert';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

// AudioHandlerの実装
class MyAudioHandler extends audio_service_pkg.BaseAudioHandler
    with audio_service_pkg.QueueHandler, audio_service_pkg.SeekHandler {
  final _player = AudioPlayer();
  String? currentPlayingDownloadId;
  bool _isPlaying = false;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // プレーヤーの状態変化をリッスン
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            audio_service_pkg.MediaControl.skipToPrevious,
            if (playing)
              audio_service_pkg.MediaControl.pause
            else
              audio_service_pkg.MediaControl.play,
            audio_service_pkg.MediaControl.skipToNext,
          ],
          systemActions: const {
            audio_service_pkg.MediaAction.seek,
            audio_service_pkg.MediaAction.seekForward,
            audio_service_pkg.MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState:
              const {
                ProcessingState.idle:
                    audio_service_pkg.AudioProcessingState.idle,
                ProcessingState.loading:
                    audio_service_pkg.AudioProcessingState.loading,
                ProcessingState.buffering:
                    audio_service_pkg.AudioProcessingState.buffering,
                ProcessingState.ready:
                    audio_service_pkg.AudioProcessingState.ready,
                ProcessingState.completed:
                    audio_service_pkg.AudioProcessingState.completed,
              }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: 0,
        ),
      );
      
      // 再生完了時に停止する
      if (_player.processingState == ProcessingState.completed && playing) {
        stop();
        _isPlaying = false;
      }
    });

    // メディア情報の更新
    _player.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });
  }

  // 再生状態の取得
  Future<bool> isPlaying() async {
    return _isPlaying;
  }

  // オーディオデータの再生
  Future<void> playAudioData(dynamic audioData) async {
    print("audioData.runtimeType:${audioData.runtimeType}");

    try {
      // メディア情報の設定
      mediaItem.add(
        audio_service_pkg.MediaItem(
          id: currentPlayingDownloadId ?? 'unknown',
          title: 'Audio',
          duration: await _player.duration ?? Duration.zero,
        ),
      );

      if (audioData is Uint8List) {
        // メモリ内のバイトデータからオーディオを再生
        final audioSource = AudioSource.uri(
          Uri.dataFromBytes(audioData, mimeType: 'audio/mpeg'),
        );
        await _player.setAudioSource(audioSource);
      } else if (audioData is String) {
        if (audioData.startsWith("http")) {
          // URLからオーディオを再生
          await _player.setUrl(audioData);
        } else {
          // Base64エンコードされた文字列からオーディオを再生
          // Uint8List decodedData = await _decodeBase64(audioData);
          final audioSource = AudioSource.uri(
            Uri.parse("data:audio/mpeg;base64,$audioData"),
          );
          await _player.setAudioSource(audioSource);
        }
      }

      play();
      _isPlaying = true;
    } catch (e) {
      print("Audio playback error: $e");
    }
  }

  // Base64デコード
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

  // BaseAudioHandlerのメソッドオーバーライド
  @override
  Future<void> play() async {
    await _player.play();
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // 指定秒数だけスキップ
  Future<void> skipSize(int move) async {
    final current = _player.position;
    Duration newPosition = current + Duration(seconds: move);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    await _player.seek(newPosition);
  }

  // 現在再生中のダウンロードIDを取得
  String? getCurrentPlayingDownloadId() {
    return currentPlayingDownloadId;
  }

  // ストリームの公開
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
}

// シングルトンとしてのAudioService
class AudioService {
  static MyAudioHandler? _audioHandler;

  // AudioHandlerの初期化
  static Future<void> init() async {
    _audioHandler ??= await initAudioService();
  }

  // AudioHandlerの初期化
  static Future<MyAudioHandler> initAudioService() async {
    return await audio_service_pkg.AudioService.init(
      builder: () => MyAudioHandler(),
      config: const audio_service_pkg.AudioServiceConfig(
        androidNotificationChannelId: 'com.example.hello_radiko_explorer.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
  }

  // 以下、元のAudioServiceと同じインターフェースを提供するメソッド
  static String? get currentPlayingDownloadId =>
      _audioHandler?.currentPlayingDownloadId;
  static set currentPlayingDownloadId(String? id) {
    if (_audioHandler != null) {
      _audioHandler!.currentPlayingDownloadId = id;
    }
  }

  static Future<bool> isPlaying() async {
    await init();
    return _audioHandler?.isPlaying() ?? false;
  }

  static Future<void> playAudioData(dynamic audioData) async {
    await init();
    await _audioHandler?.playAudioData(audioData);
  }

  static Future<void> pause() async {
    await init();
    await _audioHandler?.pause();
  }

  static Future<void> resume() async {
    await init();
    await _audioHandler?.play();
  }

  static Future<void> stop() async {
    await init();
    await _audioHandler?.stop();
  }

  static Future<void> skipSize(int move) async {
    await init();
    await _audioHandler?.skipSize(move);
  }

  static Future<void> seek(Duration position) async {
    await init();
    await _audioHandler?.seek(position);
  }

  static Stream<Duration> get positionStream {
    init();
    return _audioHandler?.positionStream ?? Stream.value(Duration.zero);
  }

  static Stream<Duration?> get durationStream {
    init();
    return _audioHandler?.durationStream ?? Stream.value(null);
  }

  static Stream<PlayerState> get playerStateStream {
    init();
    return _audioHandler?.playerStateStream ??
        Stream.value(PlayerState(false, ProcessingState.idle));
  }

  static String? getCurrentPlayingDownloadId() {
    return _audioHandler?.getCurrentPlayingDownloadId();
  }
}
