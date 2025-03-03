import 'package:flutter/material.dart';
import 'package:hello_radiko_explorer/firebase_options.dart';
import 'package:hello_radiko_explorer/services/settings_service.dart';
import 'package:hello_radiko_explorer/services/download_service.dart';
import 'listen_now_page.dart';
import 'downloads_page.dart';
import 'widgets/settings_screen.dart';
import 'widgets/audio_controller.dart';
import 'package:hello_radiko_explorer/services/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await FirebaseAnalytics.instance.logAppOpen();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // FirebaseMessaging.instance.getToken(
  //   vapidKey:
  //       "BOvIveuTRfpNc0ZEzPMtEG8cV-hX2eLTO-nS3NNfe3pbi24-b_TsIQ2JNFpa7kfpeCXc4QMrKte3Arh3562BAc8",
  // );

  await SettingsService().init();
  await DownloadService().init(); // DownloadServiceを初期化
  await AudioService.init(); // AudioServiceを初期化
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
          title: 'H!P radiko',
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
          home: const MyHomePage(title: 'Hello!Project radiko App'),
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
  String? _downloadProgramId;
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SettingsService().loadSubscribedSembast().then((member) {
        final subscribedMembers = member!.split(",");
        List<String> matchedMembers = [];
        for (var targetMember in message.data["target"].split(",")) {
          if (subscribedMembers.contains(targetMember)) {
            matchedMembers.add(targetMember);
          }
        }
        if (matchedMembers.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            snackBarAnimationStyle: AnimationStyle(duration: Durations.medium4),
            SnackBar(
              content: Text(
                "${message.data["title"]}が間もなく始まります。\n${matchedMembers.join(",")}が出演します。\n放送開始時刻:${message.data["ft"]}～",
              ),
            ),
          );
        }
      });
    });
  }

  void _onItemTapped(int index) {
    print('Tab tapped: $index');
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _downloadProgramId = null;
      }
    });
  }

  void _handleTabSwitch(String programId) {
    setState(() {
      _downloadProgramId = programId;
      _selectedIndex = 1;
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
          bottomSheet: const AudioController(),
        );
      },
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ListenNowPage(onTabSwitch: _handleTabSwitch);
      case 1:
        return DownloadsPage(programId: _downloadProgramId);
      case 2:
        return const SettingsPage();
      default:
        return const Center(child: Text('エラー'));
    }
  }
}
