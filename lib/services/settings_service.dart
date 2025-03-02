import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  final ValueNotifier<bool> _darkMode = ValueNotifier<bool>(false);
  bool _notifications = false;
  final Map<String, bool> _memberSelections = {};
  final Map<String, bool> _groupSelections = {};
  bool _openRadikoInApp = false; // デフォルトはブラウザで開く

  // ゲッター
  ValueNotifier<bool> get darkModeNotifier => _darkMode;
  bool get notifications => _notifications;
  Map<String, bool> get memberSelections => Map.unmodifiable(_memberSelections);
  Map<String, bool> get groupSelections => Map.unmodifiable(_groupSelections);
  bool get openRadikoInApp => _openRadikoInApp;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadAllSettings();
    _initialized = true;
  }

  Future<void> _loadAllSettings() async {
    _darkMode.value = _prefs.getBool('darkMode') ?? false;
    _notifications = _prefs.getBool('notifications') ?? false;
    _openRadikoInApp =
        _prefs.getBool('openRadikoInApp') ?? kIsWeb
            ? RegExp(
              r'(iPhone|iPad|Android)',
            ).hasMatch(window.navigator.userAgent)
            : false;

    final String? memberSelectionsString = _prefs.getString('memberSelections');
    if (memberSelectionsString != null) {
      final Map<String, dynamic> memberSelectionsJson =
          jsonDecode(memberSelectionsString) as Map<String, dynamic>;
      _memberSelections.clear();
      memberSelectionsJson.forEach((key, value) {
        if (value is bool) {
          _memberSelections[key] = value;
        }
      });
    }

    final String? groupSelectionsString = _prefs.getString('groupSelections');
    if (groupSelectionsString != null) {
      final Map<String, dynamic> groupSelectionsJson =
          jsonDecode(groupSelectionsString) as Map<String, dynamic>;
      _groupSelections.clear();
      groupSelectionsJson.forEach((key, value) {
        if (value is bool) {
          _groupSelections[key] = value;
        }
      });
    }
    setDarkMode(_darkMode.value);
    setNotifications(_notifications);
    setOpenRadikoInApp(_openRadikoInApp);
    await _prefs.setString('memberSelections', jsonEncode(_memberSelections));
    await _prefs.setString('groupSelections', jsonEncode(_groupSelections));
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode.value = value;
    await _prefs.setBool('darkMode', value);
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    await _prefs.setBool('notifications', value);
  }

  Future<void> setMemberSelection(String member, bool value) async {
    if (value) {
      await FirebaseAnalytics.instance.logEvent(
        name: "member_register",
        parameters: {"member_name": member},
      );
    } else {
      await FirebaseAnalytics.instance.logEvent(
        name: "member_unregister",
        parameters: {"member_name": member},
      );
    }
    _memberSelections[member] = value;
    await _prefs.setString('memberSelections', jsonEncode(_memberSelections));
    saveSubscribedSembast();
  }

  Future<void> setGroupSelection(String group, bool value) async {
    if (value) {
      await FirebaseAnalytics.instance.logEvent(
        name: "group_register",
        parameters: {"group_name": group},
      );
    } else {
      await FirebaseAnalytics.instance.logEvent(
        name: "group_unregister",
        parameters: {"group_name": group},
      );
    }
    _groupSelections[group] = value;
    await _prefs.setString('groupSelections', jsonEncode(_groupSelections));
    saveSubscribedSembast();
  }

  Future<void> setOpenRadikoInApp(bool value) async {
    _openRadikoInApp = value;
    await _prefs.setBool('openRadikoInApp', value);
  }

  void initializeMemberSelections(Map<String, List<String>> members) {
    members.forEach((group, memberList) {
      if (!_groupSelections.containsKey(group)) {
        _groupSelections[group] = false;
      }
      for (var member in memberList) {
        if (!_memberSelections.containsKey(member)) {
          _memberSelections[member] = false;
        }
      }
    });
  }

  // Sembast (IndexedDB) を利用して、選択されたメンバーとグループをカンマ区切りの文字列で保存
  Database? _subscribedDb;
  final _subscribedStore = StoreRef<String, String>('subscribed');

  Future<Database> get _sembastDatabase async {
    if (_subscribedDb == null) {
      if (kIsWeb) {
        _subscribedDb = await databaseFactoryWeb.openDatabase('subscribed');
      } else {
        // IndexedDBはWeb専用のため、非Web環境では例外を投げます。
        throw Exception("IndexedDBはWeb環境でのみ利用可能です。");
      }
    }
    return _subscribedDb!;
  }

  Future<void> saveSubscribedSembast() async {
    final db = await _sembastDatabase;
    final selectedMembers = _memberSelections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);
    final selectedGroups = _groupSelections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);
    final csv = ([...selectedMembers, ...selectedGroups]).join(',');
    await _subscribedStore.record('subscribed').put(db, csv);
  }

  Future<String?> loadSubscribedSembast() async {
    final db = await _sembastDatabase;
    return await _subscribedStore.record('subscribed').get(db);
  }
}
