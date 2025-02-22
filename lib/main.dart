import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/firebase_options.dart';
import 'package:hello_radiko_explorer/services/settings_service.dart';
import 'listen_now_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await SettingsService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.darkModeNotifier,
      builder: (context, darkMode, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            fontFamily: 'MPLUS2',
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: 'MPLUS2',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MyHomePage(title: 'Hello!Project radiko'),
        );
      },
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
  final _settings = SettingsService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.darkModeNotifier,
      builder: (context, darkMode, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor:
                darkMode
                    ? const Color.fromARGB(255, 16, 74, 111)
                    : Colors.blueAccent,
            title: Text(
              widget.title,
              style:
                  darkMode
                      ? const TextStyle(
                        color: Color.fromARGB(255, 221, 144, 27),
                      )
                      : const TextStyle(color: Colors.lime),
            ),
          ),
          body: _getPage(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.headphones),
                label: '今すぐ聞く',
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
        );
      },
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ListenNowPage();
      case 1:
        return const Center(child: Text('ダウンロード済み'));
      case 2:
        return const SettingsPage();
      default:
        return const Center(child: Text('エラー'));
    }
  }
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
