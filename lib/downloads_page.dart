import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/services/download_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final DownloadService _downloadService = DownloadService();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_downloads.isEmpty) {
      return const Center(child: Text('ダウンロード済みのタイムフリーはありません'));
    }

    // 日付の降順でソート
    _downloads.sort((a, b) {
      final dateA = DateTime.parse(a['ft']);
      final dateB = DateTime.parse(b['ft']);
      return dateB.compareTo(dateA);
    });

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView.builder(
        itemCount: _downloads.length,
        itemBuilder: (context, index) {
          final download = _downloads[index];
          final ft = DateTime.parse(download['ft']);
          final downloadedAt = DateTime.parse(download['downloadedAt']);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(
                '${download['channelId']} - ${DateFormat('yyyy/MM/dd HH:mm').format(ft)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'ダウンロード日時: ${DateFormat('yyyy/MM/dd HH:mm').format(downloadedAt)}',
              ),
              trailing: const Icon(Icons.play_arrow),
              onTap: () async {
                final url = download['url'];
                if (url != null) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
