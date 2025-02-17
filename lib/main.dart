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
        // これはアプリケーションのテーマです。
        //
        // TRY THIS: "flutter run"でアプリケーションを実行してみてください。紫色のツールバーが表示されます。次に、アプリを終了せずに、
        // 下のcolorSchemeのseedColorをColors.greenに変更してみてください。
        // そして、「ホットリロード」を起動します（変更を保存するか、Flutter対応のIDEで「ホットリロード」ボタンを押すか、
        // コマンドラインを使用してアプリを起動した場合は「r」を押します）。
        //
        // カウンターがゼロにリセットされないことに注意してください。アプリケーションの状態は
        // リロード中に失われません。状態をリセットするには、代わりにホットリスタートを使用してください。
        //
        // これはコードにも当てはまります。値だけでなく、ほとんどのコードの変更は
        // ホットリロードだけでテストできます。
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // これはアプリケーションのホームページのウィジェットです。これはステートフルであり、
  // その外観に影響を与えるフィールドを含むStateオブジェクト（下記で定義）を持ちます。

  // このクラスは、状態の構成です。これは、親（この場合はAppウィジェット）によって提供され、
  // Stateのbuildメソッドで使用される値（この場合はタイトル）を保持します。Widgetサブクラスのフィールドは
  // 常に「final」とマークされています。

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

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
                      Switch(
                        value: _darkModeEnabled,
                        onChanged: _toggleDarkMode,
                      ),
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

    // このメソッドは、上記の_incrementCounterメソッドによって行われるように、setStateが呼び出されるたびに再実行されます。
    //
    // Flutterフレームワークは、buildメソッドの再実行を高速化するように最適化されているため、
    // ウィジェットのインスタンスを個別に変更するのではなく、更新が必要なものを再構築するだけで済みます。
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: ここで色を特定の色（たとえば
        // Colors.amber？）に変更し、ホットリロードをトリガーして、AppBar
        // の色が変わり、他の色が同じままであることを確認します。
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // ここでは、App.buildメソッドによって作成されたMyHomePageオブジェクトから値を取得し、
        // それを使用してappbarのタイトルを設定します。
        title: Text(widget.title),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.headphones), label: '今すぐ開く'),
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
}
