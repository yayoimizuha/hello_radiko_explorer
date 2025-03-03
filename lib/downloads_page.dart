import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/services/download_service.dart';
import 'package:hello_radiko_explorer/services/audio_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:hello_radiko_explorer/listen_now_page.dart';
import 'package:hello_radiko_explorer/program_detail_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DownloadsPage extends StatefulWidget {
  final String? programId;
  const DownloadsPage({super.key, this.programId});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with RouteAware, WidgetsBindingObserver {
  final DownloadService _downloadService = DownloadService();
  List<(RadioProgram, DateTime)> _downloads = [];
  bool _isLoading = true;

  String? _playingDownloadId;
  bool _playLoading = false;
  bool _isAudioPlaying = false;
  bool _isPlayingAll = false;
  StreamSubscription<dynamic>? _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await FirebaseAnalytics.instance.logEvent(
        name: "open_tab",
        parameters: {"tab_name": "downloaded"},
      );
    });
    print('DownloadsPage: initState, programId = ${widget.programId}');
    _syncAudioState();
    _loadDownloads();
    _audioPlayerStateSubscription = AudioService.playerStateStream.listen((
      state,
    ) {
      setState(() {
        if (state.playing) {
          _isAudioPlaying = true;
        } else {
          _isAudioPlaying = false;
          _playingDownloadId = null;
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _syncAudioState();
  }

  Future<void> _syncAudioState() async {
    bool playing = false;
    String? currentId;
    try {
      playing = await AudioService.isPlaying();
      currentId = AudioService.getCurrentPlayingDownloadId();
    } catch (e) {
      print("Error syncing audio state: \$e");
    }
    setState(() {
      _isAudioPlaying = playing;
      _playingDownloadId = currentId;
    });
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final downloads = await _downloadService.getAllDownloads();
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
      if (widget.programId != null) {
        String targetId = widget.programId!;
        if (targetId.startsWith("downloads:")) {
          targetId = targetId.replaceFirst("downloads:", "");
        }
        print("Auto-play triggered for programId: $targetId");
        await Future.delayed(const Duration(seconds: 1));
        try {
          final matching = _downloads.firstWhere(
            (d) => "${d.$1.radioChannel.id}-${d.$1.id}" == targetId,
          );
          print("Auto-play: Found matching download: $matching");
          await _playDownload(matching.$1);
        } catch (e) {
          print("Auto-play: Matching download not found: $e");
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ダウンロード一覧の取得に失敗しました: $e')));
    }
  }

  Future<void> _playDownload(RadioProgram download) async {
    print("Auto-play _playDownload called with download: $download");
    final downloadId =
        "${download.radioChannel.id}-${download.ft.toIso8601String()}";
    if (_isAudioPlaying && _playingDownloadId == downloadId) {
      await AudioService.stop();
      setState(() {
        _isAudioPlaying = false;
        _playingDownloadId = null;
      });
      return;
    }
    setState(() {
      _playLoading = true;
      _playingDownloadId = downloadId;
    });
    AudioService.currentPlayingDownloadId = downloadId;
    final channelId = download.radioChannel.id;
    final ft = download.ft;
    bool playSuccess = false;
    final downloadedAudio = await DownloadService().getDownloadedAudio(
      channelId,
      ft,
    );
    if (downloadedAudio != null) {
      await AudioService.playAudioData(
        downloadedAudio,
        download.title,
        Uri.parse(download.img ?? download.radioChannel.bannerUrl),
      );
      await FirebaseAnalytics.instance.logEvent(
        name: "play_downloaded",
        parameters: {"id": download.id},
      );

      playSuccess = true;
    } else {
      final url = await DownloadService().getDownloadedUrl(channelId, ft);
      if (url != null) {
        await AudioService.playAudioData(
          url,
          download.title,
          Uri.parse(download.img ?? download.radioChannel.bannerUrl),
        );
        playSuccess = true;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('再生する音声が見つかりません')));
      }
    }
    setState(() {
      _playLoading = false;
      _isAudioPlaying = playSuccess;
      _playingDownloadId = playSuccess ? downloadId : null;
    });
  }

  Future<void> _playAllDownloads() async {
    await FirebaseAnalytics.instance.logEvent(name: "play_downloaded_all");

    setState(() {
      _isPlayingAll = true;
    });
    for (final tuple in _downloads) {
      if (!_isPlayingAll) break;
      await _playDownload(tuple.$1);
      // 現在再生中の音声が終了するまで待機してから次の音声を再生する
      while (_isAudioPlaying) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    setState(() {
      _isPlayingAll = false;
    });
  }

  Future<void> _deleteAllDownloads() async {
    for (var tuple in List.from(_downloads)) {
      await DownloadService().deleteDownload(
        tuple.$1.radioChannel.id,
        tuple.$1.ft,
      );
    }
    setState(() {
      _downloads.clear();
    });
  }

  @override
  void didPopNext() {
    _syncAudioState().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _audioPlayerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_downloads.isEmpty) {
      return const Center(child: Text('ダウンロード済みのタイムフリーはありません'));
    }

    _downloads.sort((a, b) {
      final dateA = a.$1.ft;
      final dateB = b.$1.ft;
      return dateB.compareTo(dateA);
    });

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView.builder(
        itemCount: _downloads.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isPlayingAll ? null : _playAllDownloads,
                    child: const Text('すべて再生'),
                  ),
                  ElevatedButton(
                    onPressed: _deleteAllDownloads,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('すべて削除'),
                  ),
                ],
              ),
            );
          }
          final int itemIndex = index - 1;
          final download = _downloads[itemIndex].$1;
          final downloadAt = _downloads[itemIndex].$2;
          final ft = download.ft;
          final downloadId =
              "${download.radioChannel.id}-${download.ft.toIso8601String()}";
          // print("downloadId:$downloadId");
          // print("_playingDownloadId:$_playingDownloadId");
          final isPlayingDownload =
              _isAudioPlaying && _playingDownloadId == downloadId;

          return Dismissible(
            key: ValueKey(downloadId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await DownloadService().deleteDownload(
                download.radioChannel.id,
                download.ft,
              );
              setState(() {
                _downloads.removeAt(itemIndex);
              });
            },
            child: Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              shape:
                  isPlayingDownload
                      ? RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.pink, width: 2),
                        borderRadius: BorderRadius.circular(4.0),
                      )
                      : null,
              child: ListTile(
                title: Text(
                  '${download.title} - ${DateFormat('MM/dd HH:mm').format(ft)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ダウンロード日時: ${DateFormat('yyyy/MM/dd HH:mm').format(downloadAt)}',
                ),
                trailing: IconButton(
                  icon:
                      _playLoading && _playingDownloadId == downloadId
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : _isAudioPlaying && _playingDownloadId == downloadId
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.play_arrow),
                  onPressed: () async {
                    final downloadId =
                        "${download.radioChannel.id}-${download.ft.toIso8601String()}";
                    if (_isAudioPlaying && _playingDownloadId == downloadId) {
                      await AudioService.pause();
                      setState(() {
                        _isAudioPlaying = false;
                      });
                      return;
                    }
                    setState(() {
                      _playLoading = true;
                      _playingDownloadId = downloadId;
                    });
                    final channelId = download.radioChannel.id;
                    final ft = download.ft;
                    bool playSuccess = false;
                    final downloadedAudio = await DownloadService()
                        .getDownloadedAudio(channelId, ft);
                    if (downloadedAudio != null) {
                      await AudioService.playAudioData(
                        downloadedAudio,
                        download.title,
                        Uri.parse(
                          download.img ?? download.radioChannel.bannerUrl,
                        ),
                      );
                      playSuccess = true;
                    } else {
                      final url = await DownloadService().getDownloadedUrl(
                        channelId,
                        ft,
                      );
                      if (url != null) {
                        await AudioService.playAudioData(
                          url,
                          download.title,
                          Uri.parse(
                            download.img ?? download.radioChannel.bannerUrl,
                          ),
                        );
                        playSuccess = true;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('再生する音声が見つかりません')),
                        );
                      }
                    }
                    setState(() {
                      _playLoading = false;
                      _isAudioPlaying = playSuccess;
                      _playingDownloadId = playSuccess ? downloadId : null;
                    });
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProgramDetailPage(
                            program: download,
                            openRadikoInApp: false,
                          ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
