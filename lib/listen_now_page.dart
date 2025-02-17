import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ListenNowPage extends StatefulWidget {
  const ListenNowPage({Key? key}) : super(key: key);

  @override
  State<ListenNowPage> createState() => _ListenNowPageState();
}

class _ListenNowPageState extends State<ListenNowPage> {
  List<dynamic> _selectedMembers = [];
  List<dynamic> _selectedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedMembersAndGroups();
  }

  Future<void> _loadSelectedMembersAndGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberSelectionsString =
          prefs.getString('memberSelections') ?? '[]';
      final groupSelectionsString = prefs.getString('groupSelections') ?? '[]';

      print('Debug: memberSelectionsString = $memberSelectionsString');
      print('Debug: groupSelectionsString = $groupSelectionsString');

      final memberSelections = json.decode(memberSelectionsString);
      final groupSelections = json.decode(groupSelectionsString);

      print('Debug: memberSelections type = ${memberSelections.runtimeType}');
      print('Debug: groupSelections type = ${groupSelections.runtimeType}');

      // 型チェックと変換を行う
      List<dynamic> memberList =
          memberSelections is List
              ? memberSelections
              : memberSelections is Map
              ? [memberSelections]
              : [];

      List<dynamic> groupList =
          groupSelections is List
              ? groupSelections
              : groupSelections is Map
              ? [groupSelections]
              : [];

      setState(() {
        _selectedMembers = memberList;
        _selectedGroups = groupList;
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
      body: Column(
        children: [
          const Text('選択されたメンバー:'),
          _selectedMembers.isEmpty
              ? const Text('選択されたメンバーはいません')
              : Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedMembers.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_selectedMembers[index].toString()),
                    );
                  },
                ),
              ),
          const Text('選択されたグループ:'),
          _selectedGroups.isEmpty
              ? const Text('選択されたグループはいません')
              : Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedGroups.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_selectedGroups[index].toString()),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
