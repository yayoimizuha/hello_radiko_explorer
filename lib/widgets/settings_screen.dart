import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hello_radiko_explorer/services/settings_service.dart';

Future<Map<String, List<String>>> loadMembers() async {
  final String jsonString = await rootBundle.loadString('lib/members.json');
  final dynamic jsonResponse = jsonDecode(jsonString);
  return (jsonResponse as Map<String, dynamic>).map<String, List<String>>(
      (key, value) => MapEntry(key, List<String>.from(value as List)));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService();
  @override
  void initState() {
    super.initState();
    _settings.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('通知'),
            value: _settings.notifications,
            onChanged: (bool value) async {
              await _settings.setNotifications(value);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('ダークモード'),
            value: _settings.darkModeNotifier.value,
            onChanged: (bool value) async {
              await _settings.setDarkMode(value);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('radikoリンクをアプリで開く'),
            value: _settings.openRadikoInApp,
            onChanged: (bool value) async {
              await _settings.setOpenRadikoInApp(value);
              setState(() {});
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MembersPage()),
              );
            },
            child: const Text('メンバー選択'),
          ),
        ],
      ),
    );
  }
}

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _settings = SettingsService();
  late Future<Map<String, List<String>>> _membersData;

  @override
  void initState() {
    super.initState();
    _membersData = loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メンバー選択')),
      body: FutureBuilder<Map<String, List<String>>>(
        future: _membersData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final members = snapshot.data!;
            _settings.initializeMemberSelections(members);
            return ListView(
              children: [
                for (var group in members.keys) ...[
                  CheckboxListTile(
                    title: Text(
                      group,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _settings.groupSelections[group] ?? false,
                    onChanged: (bool? newValue) async {
                      if (newValue != null) {
                        await _settings.setGroupSelection(group, newValue);
                        setState(() {});
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  for (var member in members[group]!)
                    CheckboxListTile(
                      title: Text(member),
                      value: _settings.memberSelections[member] ?? false,
                      onChanged: (bool? newValue) async {
                        if (newValue != null) {
                          await _settings.setMemberSelection(member, newValue);
                          setState(() {});
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.only(left: 40.0),
                    ),
                ],
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}