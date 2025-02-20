import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'listen_now_page.dart';
import 'package:intl/intl.dart';

class ProgramDetailPage extends StatelessWidget {
  final RadioProgram program;

  const ProgramDetailPage({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    print(program.info?.replaceAll(RegExp(r'^\s+', multiLine: true), '\n'));
    print(program.desc?.replaceAll(RegExp(r'^\s+', multiLine: true), '\n'));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(program.title, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final radikoUrl =
                    'radiko://radiko.onelink.me/?deep_link_sub1=${program.radioChannel.id}&deep_link_sub2=${DateFormat('yyyyMMddHHmmss').format(program.ft)}&deep_link_value=${program.id}';
                final webUrl =
                    'https://radiko.jp/#!/ts/${program.radioChannel.id}/${DateFormat('yyyyMMddHHmmss').format(program.ft)}';

                // if (await canLaunchUrl(Uri.parse(radikoUrl))) {
                await launchUrl(Uri.parse(radikoUrl));
                // } else {
                if (await canLaunchUrl(Uri.parse(webUrl))) {
                  await launchUrl(Uri.parse(webUrl));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Radikoアプリもブラウザも開けませんでした。')),
                  );
                }
                // }
              },
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
                        "https://getimagebase64-rnfi7uy4qq-uc.a.run.app/getImageBase64?url=${program.img}",
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
                                imageUrl: music.artworkUrl,
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
}
