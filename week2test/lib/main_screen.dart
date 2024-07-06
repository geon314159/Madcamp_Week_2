import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'notice_tab.dart';
import 'schedule_tab.dart';
import 'todo_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String name = '';
  String email = '';
  List<int> groupIds = [];
  double backdropOpacity = 0.0;
  double buttonOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.89:80/user_info'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': userId!,
      }),
    );
    print(userId!);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        name = responseData['name'];
        email = responseData['email'];
        groupIds = List<int>.from(responseData['group_ids']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user info')),
      );
    }
  }

  Future<void> _createGroup() async {
    TextEditingController groupNameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groupNameController,
                decoration: InputDecoration(labelText: 'Group Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                Navigator.of(context).pop({
                  'group_name': groupNameController.text,
                  'description': descriptionController.text,
                });
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final response = await http.post(
        Uri.parse('http://172.10.7.89:80/create_group'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'user_id': userId!,
          'group_name': result['group_name'],
          'description': result['description'],
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        String inviteCode = responseData['invite_code'];
        _showInviteCodeDialog(inviteCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group')),
        );
      }
    }
  }

  Future<void> _joinGroup() async {
    TextEditingController inviteCodeController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Group'),
          content: TextField(
            controller: inviteCodeController,
            decoration: InputDecoration(labelText: 'Invite Code'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Join'),
              onPressed: () {
                Navigator.of(context).pop(inviteCodeController.text);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final response = await http.post(
        Uri.parse('http://172.10.7.89:80/join_group'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'user_id': userId!,
          'invite_code': result,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined group')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join group')),
        );
      }
    }
  }

  void _showInviteCodeDialog(String inviteCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invite Code'),
          content: Text('Group successfully created. Invite Code: $inviteCode'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoticeTab()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScheduleTab()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TodoTab()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa0d9d3),
      body: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 5),
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.settings, color: Colors.black),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 70),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.person, size: 80),
                          SizedBox(width: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$name",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text("$email", style: TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.navigate_next_outlined),
                                onPressed: null,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 어두운 배경
          AnimatedOpacity(
            opacity: backdropOpacity,
            duration: Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  backdropOpacity = 0.0;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // 슬라이드 가능한 컨테이너
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                backdropOpacity = notification.extent > 0.85 ? 1.0 : 0.0;
                buttonOpacity = notification.extent > 0.85 ? 1.0 : 0.0;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.75, // 초기 크기
              minChildSize: 0.75, // 최소 크기
              maxChildSize: 0.9, // 최대 크기
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xfff6f6f6),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.0,
                        spreadRadius: 5.0,
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('Slide Me Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            // 추가 컨텐츠
                            Text('More content here...'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 페이드인되면서 올라오는 버튼들
          Positioned(
            bottom: 70, // BottomNavigationBar 위로
            left: MediaQuery.of(context).size.width * 0.2,
            child: AnimatedOpacity(
              opacity: buttonOpacity,
              duration: Duration(milliseconds: 300),
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: _createGroup,
                    child: Icon(Icons.add),
                  ),
                  SizedBox(width: 20),
                  FloatingActionButton(
                    onPressed: _joinGroup,
                    child: Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xfff6f6f6), // 슬라이드 컨테이너와 동일한 배경색
          border: Border(
            top: BorderSide(
              color: Colors.transparent, // 투명한 테두리
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.announcement),
              label: 'Notice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'Todo',
            ),
          ],
          selectedItemColor: Colors.black,
          backgroundColor: Colors.transparent, // 배경색을 투명하게 설정하여 Container의 색상이 적용됨
          unselectedItemColor: Colors.black,
          showUnselectedLabels: true,
          elevation: 0, // 테두리 없앰
          onTap: (index) {
            _navigateToTab(context, index);
          },
        ),
      ),
    );
  }
}
