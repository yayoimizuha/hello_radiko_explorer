import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:sembast_web/sembast_web.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
    required String programId,
    required String channelId,
    required DateTime ft,
    required String url,
    required String title,
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
        final key = _generateKey(channelId, ft);
        await _store.record(key).put(_database!, {
          'programId': programId,
          'channelId': channelId,
          'ft': ft.toIso8601String(),
          'url': url, // 元のURLも保存しておく
          'audioData': base64Audio, // 音声データをbase64エンコードして保存
          'title': title, // タイトルも保存
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
  Future<Uint8List?> getDownloadedAudio(String channelId, DateTime ft) async {
    await _ensureInitialized();

    final key = _generateKey(channelId, ft);
    final record = await _store.record(key).get(_database!);

    if (record != null && record['audioData'] != null) {
      return base64Decode(record['audioData'] as String);
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
  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    await _ensureInitialized();

    final records = await _store.find(_database!);
    // audioDataはサイズが大きいため、一覧表示用には除外する
    return records.map((snapshot) {
      final value = Map<String, dynamic>.from(snapshot.value);
      if (value.containsKey('audioData')) {
        value['hasAudioData'] = true;
        value.remove('audioData');
      }
      return value;
    }).toList();
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
