import 'package:flutter/material.dart';
import 'listen_now_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, List<String>>> loadMembers() async {
  final String jsonString = await rootBundle.loadString('lib/members.json');
  final dynamic jsonResponse = jsonDecode(jsonString);
  return (jsonResponse as Map<String, dynamic>).map<String, List<String>>((
    key,
    value,
  ) {
    return MapEntry(key, List<String>.from(value as List));
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkModeEnabled = (prefs.getBool('darkMode') ?? false);
    });
  }

  Future<void> _saveThemeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  void toggleDarkMode(bool value) {
    setState(() {
      darkModeEnabled = value;
    });
    _saveThemeMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'Hello!Project radiko',
        toggleDarkMode: toggleDarkMode,
        darkModeEnabled: darkModeEnabled,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.toggleDarkMode,
    required this.darkModeEnabled,
  });

  final String title;
  final Function(bool) toggleDarkMode;
  final bool darkModeEnabled;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleGlobalNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            widget.darkModeEnabled
                ? const Color.fromARGB(255, 16, 74, 111)
                : Colors.blueAccent,
        title: Text(
          widget.title,
          style:
              widget.darkModeEnabled
                  ? const TextStyle(color: Color.fromARGB(255, 221, 144, 27))
                  : const TextStyle(color: Colors.lime),
        ),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.headphones), label: '今すぐ聞く'),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'ダウンロード済み',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ListenNowPage();
      case 1:
        return const Center(child: Text('ダウンロード済み'));
      case 2:
        return SettingsPage(
          darkModeEnabled: widget.darkModeEnabled,
          toggleDarkMode: widget.toggleDarkMode,
        );
      default:
        return const Center(child: Text('エラー'));
    }
  }
}

class SettingsPage extends StatefulWidget {
  final bool darkModeEnabled;
  final ValueChanged<bool> toggleDarkMode;
  const SettingsPage({
    super.key,
    required this.darkModeEnabled,
    required this.toggleDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = (prefs.getBool('notifications') ?? false);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('通知'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          SwitchListTile(
            title: const Text('ダークモード'),
            value: widget.darkModeEnabled,
            onChanged: widget.toggleDarkMode,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MembersPage()),
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
  late Future<Map<String, List<String>>> _membersData;
  final Map<String, bool> _memberSelections = {};
  final Map<String, bool> _groupSelections = {}; // グループ選択の状態を保持

  @override
  void initState() {
    super.initState();
    _membersData = loadMembers();
    _loadMemberSelections();
    _loadGroupSelections();
  }

  Future<void> _loadGroupSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? groupSelectionsString = prefs.getString('groupSelections');
    if (groupSelectionsString != null) {
      final Map<String, dynamic> groupSelectionsJson =
          jsonDecode(groupSelectionsString) as Map<String, dynamic>;
      setState(() {
        _groupSelections.clear();
        groupSelectionsJson.forEach((key, value) {
          if (value is bool) {
            _groupSelections[key] = value;
          }
        });
      });
    }
  }

  Future<void> _saveGroupSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final String groupSelectionsString = jsonEncode(_groupSelections);
    await prefs.setString('groupSelections', groupSelectionsString);
  }

  Future<void> _loadMemberSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? memberSelectionsString = prefs.getString('memberSelections');
    if (memberSelectionsString != null) {
      final Map<String, dynamic> memberSelectionsJson =
          jsonDecode(memberSelectionsString) as Map<String, dynamic>;
      setState(() {
        _memberSelections.clear();
        memberSelectionsJson.forEach((key, value) {
          if (value is bool) {
            _memberSelections[key] = value;
          }
        });
      });
    }
  }

  Future<void> _saveMemberSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final String memberSelectionsString = jsonEncode(_memberSelections);
    await prefs.setString('memberSelections', memberSelectionsString);
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
            // Initialize selection map if empty
            if (_memberSelections.isEmpty) {
              members.forEach((group, memberList) {
                _groupSelections[group] = false; // グループの選択状態を初期化
                for (var member in memberList) {
                  _memberSelections['$group - $member'] = false;
                }
              });
            }

            return ListView(
              children: [
                for (var group in members.keys) ...[
                  CheckboxListTile(
                    // グループ選択のチェックボックス
                    title: Text(
                      group,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _groupSelections[group] ?? false,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _groupSelections[group] = newValue!;
                        // グループの選択状態に応じてメンバーの選択状態を更新
                      });
                      _saveGroupSelections();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  for (var member in members[group]!)
                    CheckboxListTile(
                      title: Text(member),
                      value: _memberSelections['$group - $member'] ?? false,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _memberSelections['$group - $member'] = newValue!;
                        });
                        _saveMemberSelections();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.only(
                        left: 40.0,
                      ), // インデント
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
