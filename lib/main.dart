import 'package:flutter/material.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // これはアプリケーションのルートウィジェットです。
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
      home: MyHomePage(title: 'Hello!Project radiko'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = (prefs.getBool('darkMode') ?? false);
    });
  }

  Future<void> _saveThemeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

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

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
    _saveThemeMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            widget.title,
            style:
                _darkModeEnabled
                    ? TextStyle(color: Colors.cyanAccent)
                    : TextStyle(color: Colors.lime),
          ),
        ),
        body: _getPage(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones),
              label: '今すぐ開く',
            ),
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
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const Center(child: Text('今すぐ開く'));
      case 1:
        return const Center(child: Text('ダウンロード済み'));
      case 2:
        return SettingsPage();
      default:
        return const Center(child: Text('エラー'));
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = (prefs.getBool('darkMode') ?? false);
      _notificationsEnabled = (prefs.getBool('notifications') ?? false);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkModeEnabled);
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    _saveSettings();
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
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
            value: _darkModeEnabled,
            onChanged: _toggleDarkMode,
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
  const MembersPage({Key? key}) : super(key: key);

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late Future<Map<String, List<String>>> _membersData;
  Map<String, bool> _memberSelections = {};
  Map<String, bool> _groupSelections = {}; // グループ選択の状態を保持

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
