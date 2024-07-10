import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'team_details_notice.dart';
import 'models.dart';

class TeamDetailsScreen extends StatefulWidget {
  final int userGroupId;
  List<Tag> tagList = [];

  TeamDetailsScreen({required this.userGroupId, required this.tagList});

  @override
  _TeamDetailsScreenState createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  List<Map<String, dynamic>> teams = [];
  String groupName = '';

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/team_info'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_group_id': widget.userGroupId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        teams = List<Map<String, dynamic>>.from(responseData['teams']);
        groupName = responseData['group_name'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load team details')),
      );
    }
  }
  String getProfileImageUrl(String filePath) {
    // filePath가 /root/Madcamp_Week_2/uploads/photos/test.png 형식일 때, 서버 URL로 변환
    return 'http://172.10.7.130:80/uploads' + filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfff6f6f6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text('Your Teams', style: TextStyle(fontSize: 28, color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final leader = team['members'].firstWhere((member) => member['user_id'] == team['leader_id'], orElse: () => null);
                final leaderImage = leader != null ? leader['profile_image'] : null;
                final leader_id = team['leader_id'];

                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.0,
                          spreadRadius: 3,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: leaderImage != null ? NetworkImage(getProfileImageUrl(leaderImage)) : AssetImage('assets/default_profile.png'),
                      ),
                      title: Row(
                        children: [
                          Text(team['team_name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (leader_id == userId)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: Color(0xffAD85F1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text('Leader', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                      //subtitle: Text('Team for Guitar..'),
                      trailing: Text('${team['members'].length} members'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TeamDetailsNoticeScreen(
                            userId: team['leader_id'],
                            teamId: team['team_id'],
                            tagList: widget.tagList,
                          ),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
