import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'listen_now_page.dart';
import 'downloads_page.dart';
import 'package:intl/intl.dart';
import 'package:hello_radiko_explorer/services/settings_service.dart';
import 'package:hello_radiko_explorer/services/download_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProgramDetailPage extends StatefulWidget {
  final RadioProgram program;
  final bool openRadikoInApp;

  const ProgramDetailPage({
    super.key,
    required this.program,
    required this.openRadikoInApp,
  });

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  late bool openRadikoInApp;
  bool _isTimeFreeDownloading = false;

  @override
  void initState() {
    super.initState();
    openRadikoInApp = SettingsService().openRadikoInApp;
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    // print(program.info?.replaceAll(RegExp(r'^\s+', multiLine: true), '\n'));
    // print(program.desc?.replaceAll(RegExp(r'^\s+', multiLine: true), '\n'));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(program.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('MM').format(program.ft)}月${DateFormat('dd').format(program.ft)}日 ${DateFormat('HH').format(program.ft)}時${DateFormat('mm').format(program.ft)}分 ~ ${DateFormat('MM').format(program.to)}月${DateFormat('dd').format(program.to)}日 ${DateFormat('HH').format(program.to)}時${DateFormat('mm').format(program.to)}分 ',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              program.img != null
                  ? CachedNetworkImage(
                    imageUrl:
                        "https://serveimage-rnfi7uy4qq-an.a.run.app/serveImage?url=${program.img}",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                  : SizedBox.shrink(),
              const SizedBox(height: 8),
              Text(
                program.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildRadikoButtons(context, program)],
              ),
              const SizedBox(height: 16),
              const Text("番組概要:", style: TextStyle(fontSize: 24)),
              MarkdownBody(
                data: (program.desc ?? '番組概要はありません').replaceAll(
                  RegExp(r'^\s+', multiLine: true),
                  '\n',
                ),
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: Theme.of(context).textTheme.bodyMedium),
                onTapLink: (text, url, title) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  }
                },
                softLineBreak: true,
              ),
              const Text("番組詳細:", style: TextStyle(fontSize: 24)),
              MarkdownBody(
                data: (program.info ?? '詳細はありません').replaceAll(
                  RegExp(r'^\s+', multiLine: true),
                  '\n',
                ),
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: Theme.of(context).textTheme.bodyMedium),
                onTapLink: (text, url, title) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text("出演者:", style: TextStyle(fontSize: 24)),
              Wrap(children: [Text(program.pfm ?? '出演者情報はありません')]),
              const SizedBox(height: 16),
              const Text("オンエア楽曲:", style: TextStyle(fontSize: 24)),
              Column(
                children:
                    program.onAirMusic.map((music) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 8.0),
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://serveimage-rnfi7uy4qq-an.a.run.app/serveImage?url=${music.artworkUrl}',
                                placeholder:
                                    (context, url) =>
                                        const CircularProgressIndicator(),
                                errorWidget:
                                    (context, url, error) => Image.network(
                                      'https://via.assets.so/img.jpg?w=300&h=300&tc=blue&bg=#cecece',
                                      width: 50,
                                      height: 50,
                                    ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  music.musicTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(music.artistName),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadikoButtons(BuildContext context, RadioProgram program) {
    final now = DateTime.now();
    Widget leftButton;
    if (now.isAfter(program.ft) && now.isBefore(program.to)) {
      // 現在時刻がft以降でto前の場合は「今すぐ再生」ボタン
      leftButton = _buildListenNowButton(context, program);
    } else if (now.isAfter(program.to)) {
      // 現在時刻がto以降の場合は「タイムフリーを再生」ボタン
      leftButton = _buildTimeFreeButton(context, program);
    } else {
      // それ以外の場合は何も表示しない
      leftButton = const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leftButton,
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 140,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () async {
                final radikoUrl =
                    widget.openRadikoInApp
                        ? 'radiko://radiko.onelink.me/?deep_link_sub1=${program.radioChannel.id}&deep_link_sub2=${DateFormat('yyyyMMddHHmmss').format(program.ft)}&deep_link_value=${program.id}'
                        : 'https://radiko.jp/#!/ts/${program.radioChannel.id}/${DateFormat('yyyyMMddHHmmss').format(program.ft)}';
                await launchUrl(Uri.parse(radikoUrl));
              },
              child: Text('${widget.openRadikoInApp ? 'アプリ' : 'ブラウザ'}で開く'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenNowButton(BuildContext context, RadioProgram program) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        width: 200,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: () async {
            final radikoUrl =
                widget.openRadikoInApp
                    ? 'radiko://radiko.onelink.me/?deep_link_sub1=${program.radioChannel.id}&deep_link_sub2=${DateFormat('yyyyMMddHHmmss').format(program.ft)}&deep_link_value=${program.id}'
                    : 'https://radiko.jp/#!/ts/${program.radioChannel.id}/${DateFormat('yyyyMMddHHmmss').format(program.ft)}';
            await launchUrl(Uri.parse(radikoUrl));
          },
          child: const Text('今すぐ再生'),
        ),
      ),
    );
  }

  Widget _buildTimeFreeButton(BuildContext context, RadioProgram program) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        width: 140,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed:
              _isTimeFreeDownloading
                  ? null
                  : () async {
                    setState(() {
                      _isTimeFreeDownloading = true;
                    });
                    try {
                      // ダウンロードサービスを初期化
                      final downloadService = DownloadService();
                      await downloadService.init();

                      // 既にダウンロード済みかチェック
                      final existingUrl = await downloadService
                          .getDownloadedUrl(
                            program.radioChannel.id,
                            program.ft,
                          );

                      if (existingUrl != null) {
                        Navigator.pop(
                          context,
                          'downloads:${program.radioChannel.id}-${program.id}',
                        );
                        return;
                      }

                      // ダウンロードAPIにリクエストを送信
                      final url =
                          'https://asia-northeast1-hello-radiko.cloudfunctions.net/download_timefree?ft=${program.ft.toString()}%2B09:00&channel=${program.radioChannel.id}';

                      try {
                        final response = await http.get(Uri.parse(url));
                        final decodedBody = utf8.decode(response.bodyBytes);
                        final responseData = json.decode(decodedBody);

                        if (responseData['status'] == 'success') {
                          final downloadUrl = responseData['url'];

                          await downloadService.saveDownloadedAudio(
                            program: program,
                            url: downloadUrl,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(
                            context,
                            'downloads:${program.radioChannel.id}-${program.id}',
                          );
                        } else {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('エラー'),
                                content: Text(
                                  responseData['reason'] ?? 'ダウンロードに失敗しました',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('閉じる'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('エラー'),
                              content: Text('通信エラーが発生しました: $e'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('閉じる'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } finally {
                      setState(() {
                        _isTimeFreeDownloading = false;
                      });
                    }
                  },
          child:
              _isTimeFreeDownloading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('タイムフリーを再生', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
