import 'package:flutter/material.dart';

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
      home: MyHomePage(title: 'Hello!Project radiko', darkModeEnabled: false),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.darkModeEnabled,
  });

  final String title;
  final bool darkModeEnabled;

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
    _darkModeEnabled = widget.darkModeEnabled;
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('通知:'),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleGlobalNotifications,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ダークモード:'),
                    Switch(value: _darkModeEnabled, onChanged: _toggleDarkMode),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text('エラー'));
    }
  }
}
