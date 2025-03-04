// import 'dart:math';
// import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_radiko_explorer/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'program_detail_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ListenNowPage extends StatefulWidget {
  final Function(String)? onTabSwitch;
  const ListenNowPage({super.key, this.onTabSwitch});

  @override
  State<ListenNowPage> createState() => _ListenNowPageState();
}

class RadioProgram {
  final RadioChannel radioChannel;
  final int id;
  final DateTime ft;
  final DateTime to;
  final int dur;
  final String title;
  final String? img;
  final String? info;
  final String? desc;
  final String? pfm;
  final List<OnAirMusic> onAirMusic;
  final DateTime expireAt;

  RadioProgram({
    required this.radioChannel,
    required this.id,
    required this.ft,
    required this.to,
    required this.dur,
    required this.title,
    this.img,
    this.info,
    this.desc,
    this.pfm,
    required this.onAirMusic,
    required this.expireAt,
  });

  factory RadioProgram.fromJson(Map<String, dynamic> json) {
    return RadioProgram(
      radioChannel: RadioChannel.fromJson(
        json['radio_channel'] as Map<String, dynamic>,
      ),
      id: json['id'],
      ft:
          json['ft'] is String
              ? DateTime.parse(json['ft'])
              : (json['ft'] as Timestamp).toDate(),
      to:
          json['to'] is String
              ? DateTime.parse(json['to'])
              : (json['to'] as Timestamp).toDate(),
      dur: json['dur'],
      title: json['title'],
      img: json['img'],
      info: json['info'],
      desc: json['desc'],
      pfm: json['pfm'],
      onAirMusic:
          (json['on_air_music'] as List<dynamic>)
              .map((e) => OnAirMusic.fromJson(e as Map<String, dynamic>))
              .toList(),
      expireAt:
          json['expire_at'] is String
              ? DateTime.parse(json['expire_at'])
              : (json['expire_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radio_channel': radioChannel.toJson(),
      'id': id,
      'ft': ft.toIso8601String(),
      'to': to.toIso8601String(),
      'dur': dur,
      'title': title,
      'img': img,
      'info': info,
      'desc': desc,
      'pfm': pfm,
      'on_air_music': onAirMusic.map((m) => m.toJson()).toList(),
      'expire_at': expireAt.toIso8601String(),
    };
  }
}

class RadioChannel {
  final String id;
  final String name;
  final String bannerUrl;
  final String areaId;

  RadioChannel({
    required this.id,
    required this.name,
    required this.bannerUrl,
    required this.areaId,
  });

  factory RadioChannel.fromJson(Map<String, dynamic> json) {
    return RadioChannel(
      id: json['id'],
      name: json['name'],
      bannerUrl: json['banner_url'],
      areaId: json['area_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'banner_url': bannerUrl, 'area_id': areaId};
  }
}

class OnAirMusic {
  final String artistName;
  final String artworkUrl;
  final int startTime;
  final String musicTitle;

  OnAirMusic({
    required this.artistName,
    required this.artworkUrl,
    required this.startTime,
    required this.musicTitle,
  });

  factory OnAirMusic.fromJson(Map<String, dynamic> json) {
    return OnAirMusic(
      artistName: json['artist_name'],
      artworkUrl: json['artwork_url'],
      startTime: json['start_time'],
      musicTitle: json['music_title'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'artist_name': artistName,
      'artwork_url': artworkUrl,
      'start_time': startTime,
      'music_title': musicTitle,
    };
  }
}

Future<List<(RadioProgram, String)>> getFirebaseStruct(String name) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference programsCollection = firestore.collection(
      '/hello-radiko-data/programs/$name',
    );

    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    QuerySnapshot querySnapshot =
        await programsCollection.where('to', isGreaterThan: oneWeekAgo).get();

    if (querySnapshot.docs.isNotEmpty) {
      // ドキュメントが複数存在する場合は、すべてのドキュメントをリストで返す
      List<(RadioProgram, String)> programs = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        programs.add((RadioProgram.fromJson(data), name));
      }
      return programs;
    } else {
      print('No documents found in the collection');
      return [];
    }
  } catch (e) {
    print('Error getting documents: $e');
    return [];
  }
}

class _ListenNowPageState extends State<ListenNowPage> {
  final settingsService = SettingsService();
  List<String> _selectedMembers = [];
  List<String> _selectedGroups = [];
  final List<String> _allSelectedItems = [];
  List<(RadioProgram, List<String>)> _allRadioPrograms = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await FirebaseAnalytics.instance.logEvent(
        name: "open_tab",
        parameters: {"tab_name": "listen_now"},
      );
    });

    _scrollController = ScrollController();
    _loadSelectedMembersAndGroups().then((_) {
      if (!mounted) return;
      // 現在時刻を含む番組のインデックスを検索
      final now = DateTime.now();
      int initialIndex = _allRadioPrograms.indexWhere(
        (program) => now.isAfter(program.$1.ft) && now.isBefore(program.$1.to),
      );

      // 該当する番組がない場合は、次に始まる番組にする
      if (initialIndex == -1) {
        // 現在時刻より後の番組の中で、最も近い番組のインデックスを取得
        final now = DateTime.now();
        int nextIndex = _allRadioPrograms.indexWhere(
          (program) => program.$1.ft.isBefore(now),
        );
        if (nextIndex != -1) {
          initialIndex = nextIndex - 1;
        } else if (_allRadioPrograms.isNotEmpty) {
          // それでも該当する番組がない場合は、最初の番組にする
          initialIndex = 0;
        }
      }

      // スクロール位置を調整
      if (initialIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            initialIndex * 110, // 110は番組コンテナの高さ
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  Future<void> _loadSelectedMembersAndGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberSelectionsString =
          prefs.getString('memberSelections') ?? '{}';
      final groupSelectionsString = prefs.getString('groupSelections') ?? '{}';

      // print('Debug: memberSelectionsString = $memberSelectionsString');
      // print('Debug: groupSelectionsString = $groupSelectionsString');

      final memberSelections = json.decode(memberSelectionsString);
      final groupSelections = json.decode(groupSelectionsString);

      List<String> extractSelectedKeys(dynamic selections) {
        if (selections is Map<String, dynamic>) {
          return selections.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
        }
        return [];
      }

      setState(() {
        _selectedMembers = extractSelectedKeys(memberSelections);
        _selectedGroups = extractSelectedKeys(groupSelections);
        _allSelectedItems.clear();
        _allSelectedItems.addAll(_selectedGroups);
        _allSelectedItems.addAll(_selectedMembers);
      });
      if (!mounted) {
        return;
      }

      // _allSelectedItems の内容を一つずつ getFirebaseStruct に与えて、その戻り値を _allRadioPrograms に入力
      List<(RadioProgram, String)> programs_1 = [];
      for (var item in _allSelectedItems) {
        List<(RadioProgram, String)> radioPrograms = await getFirebaseStruct(
          item,
        );
        programs_1.addAll(radioPrograms);
      }
      programs_1.sort((a, b) => a.$1.id.compareTo(b.$1.id));
      List<(RadioProgram, List<String>)> programs_2 = [];
      RadioProgram? temp1;
      for (var element in programs_1) {
        if (temp1 != null) {
          if (element.$1.id == temp1.id) {
            programs_2.last.$2.add(element.$2);
          } else {
            programs_2.add((element.$1, [element.$2]));
          }
        } else {
          programs_2.add((element.$1, [element.$2]));
        }
        temp1 = element.$1;
      }
      programs_2.sort((a, b) => b.$1.ft.compareTo(a.$1.ft));

      if (mounted) {
        setState(() {
          _allRadioPrograms = programs_2;
        });
      }
    } catch (e) {
      print('Error loading selections: $e');
      if (mounted) {
        setState(() {
          _selectedMembers = [];
          _selectedGroups = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今すぐ聞く')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _allRadioPrograms.length,
        itemBuilder: (context, index) {
          final program = _allRadioPrograms[index];
          return Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 4.0,
              bottom: 4.0,
            ),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProgramDetailPage(
                          program: program.$1,
                          openRadikoInApp: settingsService.openRadikoInApp,
                        ),
                  ),
                );
                if (result != null) {
                  widget.onTabSwitch?.call(result);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        DateTime.now().isAfter(program.$1.ft) &&
                                DateTime.now().isBefore(program.$1.to)
                            ? Colors.pink.shade200
                            : Colors.grey.shade800,
                    width:
                        DateTime.now().isAfter(program.$1.ft) &&
                                DateTime.now().isBefore(program.$1.to)
                            ? 2
                            : 1,
                    style:
                        DateTime.now().isBefore(program.$1.to)
                            ? BorderStyle.none
                            : BorderStyle.solid,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 画像
                    CachedNetworkImage(
                      imageUrl:
                          "https://serveimage-rnfi7uy4qq-an.a.run.app/serveImage?url=${program.$1.img}",
                      width: 160,
                      height: 100,
                      placeholder:
                          (context, url) => const CircularProgressIndicator(),
                      errorWidget:
                          (context, url, error) => Image.network(
                            'https://via.assets.so/img.jpg?w=480&h=300&tc=blue&bg=#cecece', // デフォルト画像
                            width: 160,
                            height: 100,
                          ),
                    ),
                    const SizedBox(width: 16),
                    // 番組情報
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2.4,

                        children: [
                          Text(
                            '${program.$1.ft.month}月${program.$1.ft.day}日 ${program.$1.ft.hour.toString().padLeft(2, '0')}時${program.$1.ft.minute.toString().padLeft(2, '0')}分',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            program.$1.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(height: 4),
                          // 出演者リスト
                          Wrap(
                            children:
                                program.$2
                                    .map(
                                      (member) => SizedBox(
                                        // width: 150, // 幅を調整
                                        child: Text('・$member    '),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
