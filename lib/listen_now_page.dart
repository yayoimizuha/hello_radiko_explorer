import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ListenNowPage extends StatefulWidget {
  const ListenNowPage({Key? key}) : super(key: key);

  @override
  State<ListenNowPage> createState() => _ListenNowPageState();
}

void getFirebaseStruct(String name) {}

class _ListenNowPageState extends State<ListenNowPage> {
  List<String> _selectedMembers = [];
  List<String> _selectedGroups = [];
  final List<String> _allSelectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedMembersAndGroups();
  }

  Future<void> _loadSelectedMembersAndGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberSelectionsString =
          prefs.getString('memberSelections') ?? '{}';
      final groupSelectionsString = prefs.getString('groupSelections') ?? '{}';

      print('Debug: memberSelectionsString = $memberSelectionsString');
      print('Debug: groupSelectionsString = $groupSelectionsString');

      final memberSelections = json.decode(memberSelectionsString);
      final groupSelections = json.decode(groupSelectionsString);

      List<String> extractSelectedKeys(dynamic selections) {
        if (selections is Map<String, dynamic>) {
          return selections.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
        }
        return [];
      }

      setState(() {
        _selectedMembers = extractSelectedKeys(memberSelections);
        _selectedGroups = extractSelectedKeys(groupSelections);
        _allSelectedItems.addAll(_selectedGroups);
        _allSelectedItems.addAll(_selectedMembers);
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
          // const Text('選択されたメンバー:'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('選択されたアイテム:'),

              _selectedMembers.isEmpty
                  ? const Text('選択されたメンバーはいません')
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _allSelectedItems
                            .map(
                              (member) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  top: 4.0,
                                  bottom: 4.0,
                                ),
                                child: Text('・$member'),
                              ),
                            )
                            .toList(),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
