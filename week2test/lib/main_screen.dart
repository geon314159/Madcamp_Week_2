import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'notice_tab.dart';
import 'schedule_tab.dart';
import 'todo_tab.dart';
import 'group_details.dart';
import 'user_profile.dart'; // 추가

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String name = '';
  String email = '';
  String user_profile = '';
  List<Map<String, dynamic>> groupsInfo = [];
  double backdropOpacity = 0.0;
  double buttonOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/user_info'),
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
        user_profile = responseData['profile_image'];
        groupsInfo = List<Map<String, dynamic>>.from(responseData['groups_info']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user info')),
      );
    }
    print(groupsInfo);
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
        Uri.parse('http://172.10.7.130:80/create_group'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'user_id': userId!,
          'group_name': result['group_name'],
          'description': result['description'],
        }),
      );
      print(response.body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        String inviteCode = responseData['invite_code'];

        // 그룹 생성 후 groupsInfo 업데이트
        setState(() {
          groupsInfo.add({
            'group_id': responseData['group_id'],
            'group_name': result['group_name'],
            'description': result['description'],
            'member_count': 1, // 새로운 그룹의 멤버는 처음에 1명
          });
        });

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
        Uri.parse('http://172.10.7.130:80/join_group'),
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
        _fetchUserInfo(); // 그룹 가입 후 정보를 다시 가져옴
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

  void _navigateToGroupDetails(BuildContext context, int groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(userId: userId!, groupId: groupId),
      ),
    );
  }

  bool _isVisible = true;
  bool _isOpaque = true;

  String getProfileImageUrl(String filePath) {
    // filePath가 /root/Madcamp_Week_2/uploads/photos/test.png 형식일 때, 서버 URL로 변환
    return 'http://172.10.7.130:80/uploads' + filePath;
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
                padding: const EdgeInsets.only(left: 16, right: 16, top: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // 변경: center에서 start로
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(getProfileImageUrl(user_profile)),
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.55,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$name",
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          Text("$email", style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                    //Spacer(), // 변경: 오른쪽으로 밀어주기 위해 Spacer 추가
                    IconButton(
                      icon: const Icon(Icons.navigate_next_outlined),
                      onPressed: () {
                        print('pushed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(userId: userId!), // UserProfile 화면으로 이동
                          ),
                        );
                      },
                      color: Colors.black,
                      iconSize: 30,
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
            onEnd: (){
                setState((){
                  //_isVisible = false;
                });
            },
            child: Visibility(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
              visible: _isVisible,
            )
          ),
          // 슬라이드 가능한 컨테이너
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                backdropOpacity = notification.extent > 0.85 ? 1.0 : 0.0;
                buttonOpacity = notification.extent > 0.85 ? 1.0 : 0.0;
                if(notification.extent > 0.75) _isVisible = true;
                if(notification.extent == 0.75) _isVisible = false;
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
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8.0,
                        spreadRadius: 10.0,
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(25.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2열 그리드
                      crossAxisSpacing: 25.0,
                      mainAxisSpacing: 25.0,
                      childAspectRatio: 1.0, // 정사각형 모양
                    ),
                    itemCount: groupsInfo.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () => _navigateToGroupDetails(context, groupsInfo[index]['group_id']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xfff6f6f6),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5.0,
                                  spreadRadius: 3,
                                  offset: Offset(0,7)
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        groupsInfo[index]['group_name'],
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff33beb1)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.person_2_outlined, color: Colors.grey,size: 15,),
                                        Text("${groupsInfo[index]['member_count']}",style: TextStyle(fontSize: 13),)
                                      ],
                                    )
                                  ],
                                ),
                                //SizedBox(height: 10),
                                Visibility(
                                    visible: groupsInfo[index]['leader_id'] == userId,
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xccAD85F1), // 슬라이드 컨테이너와 동일한 배경색
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child:
                                        Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Text(
                                            'Leader',
                                            style: TextStyle(fontSize:8, fontWeight: FontWeight.bold, color: Color(0xfff1ead0)),
                                          ),
                                        )
                                    )
                                ),
                                Visibility(
                                    visible: groupsInfo[index]['leader_id'] != userId,
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xccf19985),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child:
                                        Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Text(
                                            'Member',
                                            style: TextStyle(fontSize:8, fontWeight: FontWeight.bold, color: Color(0xfff1ead0)),
                                          ),
                                        )
                                    )
                                ),
                                SizedBox(height: 10),
                                Text(
                                  groupsInfo[index]['description'],
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // 페이드인되면서 올라오는 버튼들
          // 페이드인되면서 올라오는 버튼들
          Positioned(
            bottom: 10, // BottomNavigationBar 위로
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: buttonOpacity,
              duration: Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: buttonOpacity == 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create',
                          style: TextStyle(
                            color: Color(0xff4B4A4A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        FloatingActionButton(
                          heroTag: 'creategroup',
                          onPressed: _createGroup,
                          child: Icon(Icons.add),
                          backgroundColor: Color(0xffD0EAEF),
                          foregroundColor: Color(0xff4B4A4A),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.3),
                  Visibility(
                    visible: buttonOpacity == 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Join',
                          style: TextStyle(
                            color: Color(0xff4B4A4A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        FloatingActionButton(
                          heroTag: 'joingroup',
                          onPressed: _joinGroup,
                          child: Icon(Icons.add),
                          backgroundColor: Color(0xffD0EAEF),
                          foregroundColor: Color(0xff4B4A4A),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xffffffff), // 슬라이드 컨테이너와 동일한 배경색
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
