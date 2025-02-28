import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:hello_radiko_explorer/listen_now_page.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Database? _database;
  final StoreRef<String, Map<String, dynamic>> _store =
      StoreRef<String, Map<String, dynamic>>.main();
  bool _initialized = false;
  ValueNotifier<bool> isDownloading = ValueNotifier(false);

  Future<void> init() async {
    if (_initialized) return;

    // Webプラットフォーム用のデータベースファクトリを使用
    final factory = databaseFactoryWeb;

    // データベースを開く
    _database = await factory.openDatabase('timefree_downloads');
    _initialized = true;
  }

  // 音声ファイルをダウンロードしてデータベースに保存
  Future<void> saveDownloadedAudio({
    required RadioProgram program,
    required String url,
  }) async {
    await _ensureInitialized();
    isDownloading.value = true;
    await Future.delayed(Duration(milliseconds: 100));

    try {
      // URLから音声ファイルをダウンロード
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final audioData = Uint8List.fromList(response.bodyBytes);
        final base64Audio = base64Encode(audioData);

        // データベースに保存（BLOB形式としてbase64エンコード済みの値を保存）
        final key = _generateKey(program.radioChannel.id, program.ft);
        await _store.record(key).put(_database!, {
          'radioProgram': program.toJson(),
          'audioData': base64Audio,
          'downloadedAt': DateTime.now().toIso8601String(),
        });
      } else {
        throw Exception('Failed to download audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving audio: $e');
    } finally {
      isDownloading.value = false;
    }
  }

  // 保存した音声データを取得
  Future<String?> getDownloadedAudio(String channelId, DateTime ft) async {
    await _ensureInitialized();

    final key = _generateKey(channelId, ft);
    final record = await _store.record(key).get(_database!);

    if (record != null && record['audioData'] != null) {
      return record['audioData'] as String;
    }

    return null;
  }

  // 後方互換性のために残しておく
  Future<String?> getDownloadedUrl(String channelId, DateTime ft) async {
    await _ensureInitialized();

    final key = _generateKey(channelId, ft);
    final record = await _store.record(key).get(_database!);

    if (record != null) {
      return record['url'] as String?;
    }

    return null;
  }

  // すべてのダウンロード済みタイムフリーを取得
  Future<List<(RadioProgram, DateTime)>> getAllDownloads() async {
    await _ensureInitialized();

    final records = await _store.find(_database!);
    List<(RadioProgram, DateTime)> ret = [];
    for (var record in records) {
      final value = Map<String, dynamic>.from(record.value);
      // ダウンロード済みであることを確認
      if (value.containsKey('audioData')) {
        final radioProgramJson = value['radioProgram'];
        // print(radioProgramJson);
        if (radioProgramJson != null) {
          ret.add((
            RadioProgram.fromJson(radioProgramJson),
            DateTime.parse(value['downloadedAt']),
          ));
        }
      }
      await Future.delayed(Duration(milliseconds: 100)); // イベントループに制御を渡す
    }
    return ret;
  }

  // キーを生成（チャンネルIDと放送日時から一意のキーを作成）
  String _generateKey(String channelId, DateTime ft) {
    return '$channelId-${ft.toIso8601String()}';
  }

  // データベースが初期化されていることを確認
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}
