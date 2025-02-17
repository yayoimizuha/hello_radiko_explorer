import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListenNowPage extends StatefulWidget {
  const ListenNowPage({Key? key}) : super(key: key);

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
      ft: (json['ft'] as Timestamp).toDate(),
      to: (json['to'] as Timestamp).toDate(),
      dur: json['dur'],
      title: json['title'],
      info: json['info'],
      desc: json['desc'],
      pfm: json['pfm'],
      onAirMusic:
          (json['on_air_music'] as List<dynamic>)
              .map((e) => OnAirMusic.fromJson(e as Map<String, dynamic>))
              .toList(),
      expireAt: (json['expire_at'] as Timestamp).toDate(),
    );
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
}

Future<List<RadioProgram>> getFirebaseStruct(String name) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference programsCollection = firestore.collection(
      '/hello-radiko-data/programs/$name',
    );

    QuerySnapshot querySnapshot = await programsCollection.get();

    if (querySnapshot.docs.isNotEmpty) {
      // ドキュメントが複数存在する場合は、すべてのドキュメントをリストで返す
      List<RadioProgram> programs = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        programs.add(RadioProgram.fromJson(data));
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
  List<String> _selectedMembers = [];
  List<String> _selectedGroups = [];
  final List<String> _allSelectedItems = [];
  List<RadioProgram> _allRadioPrograms = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedMembersAndGroups();
  }

  Future<void> _loadSelectedMembersAndGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberSelectionsString =
          prefs.getString('memberSelections') ?? '{}';
      final groupSelectionsString = prefs.getString('groupSelections') ?? '{}';

      print('Debug: memberSelectionsString = $memberSelectionsString');
      print('Debug: groupSelectionsString = $groupSelectionsString');

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

      // _allSelectedItems の内容を一つずつ getFirebaseStruct に与えて、その戻り値を _allRadioPrograms に入力
      List<RadioProgram> programs = [];
      for (var item in _allSelectedItems) {
        List<RadioProgram> radioPrograms = await getFirebaseStruct(item);
        programs.addAll(radioPrograms);
      }

      setState(() {
        _allRadioPrograms = programs;
      });
    } catch (e) {
      print('Error loading selections: $e');
      setState(() {
        _selectedMembers = [];
        _selectedGroups = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今すぐ聞く')),
      body: ListView.builder(
        itemCount: _allRadioPrograms.length,
        itemBuilder: (context, index) {
          final program = _allRadioPrograms[index];
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・チャンネル: ${program.radioChannel.name}'),
                Text('・タイトル: ${program.title}'),
                Text('・放送開始時間: ${program.ft}'),
                Text('・info: ${program.info ?? 'なし'}'),
                Text('・desc: ${program.desc ?? 'なし'}'),
                Text('・pfm: ${program.pfm ?? 'なし'}'),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
