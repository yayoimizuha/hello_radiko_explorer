import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hello_radiko_explorer/services/settings_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, List<String>>> loadMembers() async {
  final String jsonString = await rootBundle.loadString('lib/members.json');
  final dynamic jsonResponse = jsonDecode(jsonString);
  return (jsonResponse as Map<String, dynamic>).map<String, List<String>>(
    (key, value) => MapEntry(key, List<String>.from(value as List)),
  );
}

enum NotifyMode { subscribe, unsubscribe }

Future<void> notificationSubscriber(NotifyMode mode, String key) async {
  final url = Uri.https(
    "register-func-rnfi7uy4qq-an.a.run.app",
    "/register_func",
    {
      "mode": mode == NotifyMode.subscribe ? "subscribe" : "unsubscribe",
      "key": key,
      "token": await FirebaseMessaging.instance.getToken(
        vapidKey:
            "BOvIveuTRfpNc0ZEzPMtEG8cV-hX2eLTO-nS3NNfe3pbi24-b_TsIQ2JNFpa7kfpeCXc4QMrKte3Arh3562BAc8",
      ),
    },
  );
  try {
    final resp = await http.get(url);
    print("${resp.statusCode},${resp.body}");
  } catch (e) {
    print("error:$e");
    print(url);
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
    Future(() async {
      await FirebaseAnalytics.instance.logEvent(
        name: "open_tab",
        parameters: {"tab_name": "settings"},
      );
    });
  }

  Future<NotificationSettings> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('ユーザーは通知を許可しました。');
      FirebaseMessaging.instance
          .getToken(
            vapidKey:
                "BOvIveuTRfpNc0ZEzPMtEG8cV-hX2eLTO-nS3NNfe3pbi24-b_TsIQ2JNFpa7kfpeCXc4QMrKte3Arh3562BAc8",
          )
          .then((token) {
            print('トークン: $token');
          });

      FirebaseMessaging.instance.onTokenRefresh.listen((tok) {
        print("token refreshed:$tok");
      });
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('ユーザーは一時的に通知を許可しました。');
    } else {
      print('ユーザーは通知を拒否しました。');
    }
    return settings;
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
              if (value) {
                NotificationSettings requestSettings =
                    await _requestNotificationPermission();
                if (requestSettings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    requestSettings.authorizationStatus ==
                        AuthorizationStatus.provisional) {
                  await _settings.setNotifications(true);
                } else {
                  await _settings.setNotifications(false);
                }
                notificationSubscriber(NotifyMode.subscribe, "notify");
              } else {
                notificationSubscriber(NotifyMode.unsubscribe, "notify");

                await _settings.setNotifications(false);
              }
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
                        if (newValue) {
                          notificationSubscriber(NotifyMode.subscribe, group);
                        } else {
                          notificationSubscriber(NotifyMode.unsubscribe, group);
                        }
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
                          if (newValue) {
                            notificationSubscriber(
                              NotifyMode.subscribe,
                              member,
                            );
                          } else {
                            notificationSubscriber(
                              NotifyMode.unsubscribe,
                              member,
                            );
                          }
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
