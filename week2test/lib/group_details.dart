import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:intl/intl.dart';

import 'create_groupPost.dart';
import 'edit_groupPost.dart';
import 'team_details.dart';
import 'models.dart';
import 'group_calendar.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int userId;
  final int groupId;

  GroupDetailsScreen({required this.userId, required this.groupId});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

Future<File> getImageFileFromAssets(String path) async {
  final byteData = await rootBundle.load('assets/$path');

  final file = File('${(await getTemporaryDirectory()).path}/$path');
  await file.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}

Future<File> downloadImage(String url, String filename) async {
  final response = await http.get(Uri.parse('http://172.10.7.130:80$url'));
  final documentDirectory = await getApplicationDocumentsDirectory();
  final file = File('${documentDirectory.path}/$filename');

  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
    return file;
  } else {
    throw Exception('Failed to download image, http://172.10.7.130:80$url');
  }
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  String groupName = '';
  int leaderId = 0;
  List<Map<String, dynamic>> teamList = [];
  List<int> userTeamIds = [];
  List<Map<String, dynamic>> groupUserList = [];
  List<Tag> tagList = [];
  List<Tag> appliedtagList = [];
  int _selectedIndex = 0;
  List<String> imageLists = [];
  late File sample_profile;

  List<Post> groupPosts = [];
  List<Post> filteredPosts = []; // Add a new list for filtered posts
  Tag? selectedTag;
  bool isLoading = false; // Add a loading flag

  void _createnewPost() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CreateGroupPostScreen(groupId: widget.groupId, teamId: -1, userId: widget.userId, tagList: tagList),
    ));
  }

  Future<void> _loadImage() async {
    File file = await getImageFileFromAssets('sample_profile.png');
    setState(() {
      sample_profile = file;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    _loadImage();
  }

  Future<void> _fetchGroupDetails() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/group_details'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': widget.userId,
        'group_id': widget.groupId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        groupName = responseData['group_name'];
        leaderId = responseData['leader_id'];
        teamList = List<Map<String, dynamic>>.from(responseData['team_list'].map((team) => {
          'team_id': team[0],
          'team_name': team[1],
        }));
        userTeamIds = List<int>.from(responseData['user_team_ids']);
        groupUserList = List<Map<String, dynamic>>.from(responseData['group_user_list'].map((user) => {
          'user_id': user[0],
          'user_name': user[1],
        }));
        tagList = List<Tag>.from(responseData['tag_list'].map((tag) => Tag(
          tag[0],
          tag[1],
          Tag.intToColor(tag[2]),
        )));
        groupPosts = List<Post>.from(responseData['notice_list'].map((notice) => Post(
            notice['id'],
            widget.groupId,
            -1,  // team_id는 null로 설정
            notice['author_id'],
            notice['author_profile_image'] ?? '',
            notice['title'],
            notice['content'],
            notice['tags'] != null ?  List<Tag>.from(notice['tags'].map((tag) => Tag(
              tag['tag_id'],
              tag['tag_name'],
              Tag.intToColor(tag['color_hex']),))
            ) : [],
            List<String>.from(notice['images'])
        )));
        filteredPosts = groupPosts; // Initialize filteredPosts with all posts
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load group details')),
      );
    }
  }

  Future<File> _downloadAndSaveProfileImage(String url, int authorId) async {
    try {
      File file = await downloadImage(url, 'profile_$authorId.png');
      return file;
    } catch (e) {
      print(url);
      print('Error downloading image: $e');
      return sample_profile; // return a default profile image in case of error
    }
  }

  Future<void> _createTeam() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return CreateTeamDialog(groupUserList: groupUserList);
      },
    );

    if (result != null) {
      final response = await http.post(
        Uri.parse('http://172.10.7.130:80/create_team'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'group_id': widget.groupId,
          'user_ids': result['user_ids'],
          'team_name': result['team_name'],
          'team_leader_id': result['team_leader_id'],
        }),
      );
      print(response.body);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully created team')),
        );
        _fetchGroupDetails(); // 팀 생성 후 그룹 상세 정보를 다시 가져옴
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create team')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _pages() {
    return [
      _buildGroupDetails(),
      GroupScheduleTab(groupId: widget.groupId), // 빈 페이지
      Container(), // 빈 페이지
      TeamDetailsScreen(userGroupId: widget.groupId, tagList: tagList,), // 빈 페이지
    ];
  }

  Widget _generateTagsForScrollView(Color? c, String s, bool isSelected, Tag tag) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: c,
        border: isSelected ? Border.all(color: Colors.blue, width: 2.0) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              s,
              style: TextStyle(color: Color(0xffF1EAD0)),
            ),
            SizedBox(width: 3.0),
            Container(
              width: 13,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  setState(() {
                    appliedtagList.remove(tag);
                    _applyTagFilter();
                  });
                },
                icon: const Icon(Icons.cancel, size: 15, color: Color(0xffF1EAD0)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _generateTagsForFilter(Color? c, String s, bool isSelected) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: c,
        border: isSelected ? Border.all(color: Colors.blue, width: 2.0) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              s,
              style: TextStyle(color: Color(0xffF1EAD0)),
            ),
            SizedBox(width: 3.0),
            Container(
              width: 13,
              child: IconButton(
                padding: EdgeInsets.zero, // 패딩 설정
                constraints: BoxConstraints(),
                onPressed: null,
                icon: const Icon(Icons.cancel, size: 15, color: Color(0xffF1EAD0)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _editTag(Tag tag) {
    TextEditingController tagNameController = TextEditingController(text: tag.name);
    Color selectedColor = tag.color;

    Future<void> _updateGroupTags() async {
      final response = await http.post(
        Uri.parse('http://172.10.7.130:80/edit_groupTags'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'group_id': widget.groupId,
          'tags': tagList.map((tag) => {
            'id': tag.id,  // 태그 ID를 포함하도록 수정
            'name': tag.name,
            'color': Tag.colorToInt(tag.color),
          }).toList(),
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tags successfully updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update tags')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagNameController,
                decoration: InputDecoration(labelText: 'Tag Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Color color = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ColorPickerDialog(currentColor: selectedColor);
                    },
                  );
                  if (color != null) {
                    setState(() {
                      selectedColor = color;
                    });
                  }
                },
                child: Text('Select Color'),
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
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  tag.name = tagNameController.text;
                  tag.color = selectedColor;
                });
                this.setState(() {
                });
                _updateGroupTags();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String getProfileImageUrl(String filePath) {
    // filePath가 /root/Madcamp_Week_2/uploads/photos/test.png 형식일 때, 서버 URL로 변환
    return 'http://172.10.7.130:80/uploads' + filePath;
  }

  Widget _createPost(Post cur_post) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
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
        child: Padding(
          padding: const EdgeInsets.only(
              top: 20, left: 20, right: 20, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(getProfileImageUrl(cur_post.author_profile_url)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 5.0),
                      Container(
                          width: MediaQuery.of(context).size.width*0.5,
                          child:Text(
                            cur_post.title,
                            style: TextStyle(
                              color: Color(0xff33beb1),
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ],
                  ),
                  if (leaderId == widget.userId)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: Color(0xff4B4A4A)),
                      onPressed: () async {
                        final result = await Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => EditGroupPostScreen(
                            post: cur_post,
                            groupId: widget.groupId,
                            teamId: -1,
                            userId: widget.userId,
                            tagList: tagList,
                          ),
                        ));
                        if (result == true) {
                          _fetchGroupDetails(); // Refresh the posts if an update occurred
                        }
                      },
                    ),
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 100,
                color: Colors.transparent,
                child: Text(cur_post.content),
              ),
              if (cur_post.imageLists.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cur_post.imageLists.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(getProfileImageUrl(cur_post.imageLists[index])),
                      );
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(cur_post.postTags.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3.0)),
                        color: cur_post.postTags[index].color,
                      ),
                      height: 15,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, right: 5.0, top: 1, bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              cur_post.postTags[index].name,
                              style: TextStyle(
                                  color: Color(0xffF1EAD0), fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.88,
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: appliedtagList.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _generateTagsForScrollView(tag.color, tag.name, false, tag),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Flexible(
                  child: IconButton(
                    onPressed: _showTagFilter,
                    icon: FaIcon(
                      FontAwesomeIcons.filter,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Color(0xffBBBBBB),
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            height: 2,
          ),
          isLoading
              ? Center(child: CircularProgressIndicator()) // Show loading indicator
              : Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(filteredPosts.length, (index) {
                  return _createPost(filteredPosts[index]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagFilter() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Tags', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tagList.length,
                      itemBuilder: (BuildContext context, int index) {
                        Tag tag = tagList[index];
                        bool isSelected = tag == selectedTag;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTag = tag;
                                });
                              },
                              child: _generateTagsForFilter(tag.color, tag.name, isSelected),
                            ),
                            if (leaderId == widget.userId)
                              IconButton(
                                icon: Icon(Icons.more_horiz),
                                onPressed: () => _editTag(tag),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff33beb1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      onPressed: () {
                        if (selectedTag != null) {
                          if (appliedtagList.any((tag) => tag.id == selectedTag!.id)) {
                            Fluttertoast.showToast(
                              msg: "Tag already applied",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Color(0xfff19985),
                              textColor: Color(0xfff1ead0),
                              fontSize: 10.0,
                            );
                          } else {
                            setState(() {
                              appliedtagList.add(selectedTag!);
                            });
                            this.setState(() {});
                            Navigator.of(context).pop();
                            _applyTagFilter();
                          }
                        }
                      },
                      child: Text('Apply Tags', style: TextStyle(color: Color(0xfff1ead0))),
                    ),
                  ),
                  if (leaderId == widget.userId)
                    SizedBox(height: 10),
                  if (leaderId == widget.userId)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff33beb1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showAddTagDialog();
                        },
                        child: Text('Add Tag', style: TextStyle(color: Color(0xfff1ead0))),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTagDialog() {
    TextEditingController tagNameController = TextEditingController();
    Color selectedColor = Colors.blue; // Default color

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagNameController,
                decoration: InputDecoration(labelText: 'Tag Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Color color = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ColorPickerDialog(currentColor: selectedColor);
                    },
                  );
                  if (color != null) {
                    setState(() {
                      selectedColor = color;
                    });
                  }
                },
                child: Text('Select Color'),
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
              child: Text('Add'),
              onPressed: () {
                _createTag(tagNameController.text, selectedColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTag(String tagName, Color color) async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/create_tag'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user_group_id': widget.groupId,
        'tag_name': tagName,
        'color_hex': color.value.toRadixString(16),
      }),
    );

    print(response.body);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag successfully created')),
      );
      _fetchGroupDetails(); // Refresh tags after creation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create tag')),
      );
    }
  }

  void _applyTagFilter() {
    setState(() {
      isLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        filteredPosts = groupPosts.where((post) {
          return appliedtagList.every((tag) => post.postTags.any((postTag) => postTag.id == tag.id));
        }).toList();
        isLoading = false;
      });
    });
  }

  void _createMeeting() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return CreateMeetingDialog(groupUserList: groupUserList);
      },
    );

    print(result);

    if (result != null) {
      final response = await http.post(
        Uri.parse('http://172.10.7.130:80/add_meeting'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'user_group_id': widget.groupId,
          //'user_team_id': null,
          'title': result['title'],
          'start_datetime': result['start_datetime'],
          'end_datetime': result['end_datetime'],
          'user_ids': result['user_ids'],
        }),
      );

      print(response.body);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meeting successfully created')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create meeting')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text('$groupName', style: TextStyle(fontSize: 28, color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
      ),
      body: _pages()[_selectedIndex],
      floatingActionButton: leaderId == widget.userId
          ? SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Color(0xff33beb1),
        foregroundColor: Color(0xff1B6760),
        activeBackgroundColor: Color(0xff33beb1),
        activeForegroundColor: Color(0xff1B6760),
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spaceBetweenChildren: 0.2,
        children: [
          SpeedDialChild(
            child: Icon(Icons.group_add, size: 24.0),
            backgroundColor: Color(0xffa0d9d3),
            label: 'Edit Teams',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            labelStyle: TextStyle(fontSize: 13.0),
            onTap: _createTeam,
          ),
          SpeedDialChild(
            child: Icon(Icons.comment, size: 24.0),
            backgroundColor: Color(0xffa0d9d3),
            label: 'Create Notice',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            labelStyle: TextStyle(fontSize: 13.0),
            onTap: _createnewPost,
          ),
          SpeedDialChild(
            child: Icon(FontAwesomeIcons.calendar, size: 24.0),
            backgroundColor: Color(0xffa0d9d3),
            label: 'Create meeting',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            labelStyle: TextStyle(fontSize: 13.0),
            onTap: _createMeeting,
          ),
        ],
      )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xfff6f6f6),
          border: Border(
            top: BorderSide(
              color: Colors.transparent,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.comment),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'Todo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Teams',
            ),
          ],
          selectedItemColor: Colors.black,
          backgroundColor: Color(0xfff6f6f6),
          unselectedItemColor: Colors.black,
          showUnselectedLabels: true,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class CreateTeamDialog extends StatefulWidget {
  final List<Map<String, dynamic>> groupUserList;

  CreateTeamDialog({required this.groupUserList});

  @override
  _CreateTeamDialogState createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  TextEditingController teamNameController = TextEditingController();
  List<int> selectedUserIds = [];
  int? selectedTeamLeaderId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Team', style: TextStyle(color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(
                labelText: 'Team Name',
              ),
            ),
            SizedBox(height: 10),
            Text('Selected Users:'),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedUserIds.map((userId) {
                  String userName = widget.groupUserList.firstWhere((user) => user['user_id'] == userId)['user_name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(userName),
                      deleteIcon: Icon(Icons.remove),
                      onDeleted: () {
                        setState(() {
                          selectedUserIds.remove(userId);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(),
            Text('All Users:'),
            Container(
              height: MediaQuery.of(context).size.width * 0.5,
              width: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.groupUserList.length,
                itemBuilder: (context, index) {
                  final user = widget.groupUserList[index];
                  return ListTile(
                    title: Text(user['user_name']),
                    trailing: IconButton(
                      icon: Icon(
                        selectedUserIds.contains(user['user_id']) ? Icons.remove : Icons.add,
                      ),
                      onPressed: () {
                        setState(() {
                          if (selectedUserIds.contains(user['user_id'])) {
                            selectedUserIds.remove(user['user_id']);
                          } else {
                            selectedUserIds.add(user['user_id']);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Divider(),
            DropdownButton<int>(
              hint: Text('Select Team Leader'),
              value: selectedTeamLeaderId,
              onChanged: (int? newValue) {
                setState(() {
                  selectedTeamLeaderId = newValue;
                });
              },
              items: selectedUserIds.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(widget.groupUserList.firstWhere((user) => user['user_id'] == value)['user_name']),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          child: Text('Cancel', style: TextStyle(color: Color(0xff33beb1))),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            side: BorderSide(color: Color(0xff33beb1)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Create', style: TextStyle(color: Color(0xfff1ead0))),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff33beb1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop({
              'team_name': teamNameController.text,
              'user_ids': selectedUserIds,
              'team_leader_id': selectedTeamLeaderId,
            });
          },
        ),
      ],
    );
  }
}

class CreateMeetingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> groupUserList;

  CreateMeetingDialog({required this.groupUserList});

  @override
  _CreateMeetingDialogState createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<CreateMeetingDialog> {
  TextEditingController titleController = TextEditingController();
  DateTime? startDateTime;
  DateTime? endDateTime;
  List<int> selectedUserIds = [];
  int durationHours = 0;
  int durationMinutes = 0;

  Future<void> _pickDateTime(bool isStart) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        if (finalDateTime.minute % 15 != 0) {
          Fluttertoast.showToast(
            msg: "Minutes should be multiples of 15 (00, 15, 30, 45)",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }
        setState(() {
          if (isStart) {
            startDateTime = finalDateTime;
          } else {
            endDateTime = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _pickDuration() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('Hours'),
                      NumberPicker(
                        value: durationHours,
                        minValue: 0,
                        maxValue: 99,
                        onChanged: (value) => setState(() => durationHours = value),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Minutes'),
                      NumberPicker(
                        value: durationMinutes,
                        minValue: 0,
                        maxValue: 45,
                        step: 15,
                        onChanged: (value) => setState(() => durationMinutes = value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

  Future<void> _checkAvailableSlots() async {
    int totalDurationMinutes = (durationHours * 60) + durationMinutes;
    String upperLimitDatetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDateTime!);
    String lowerLimitDatetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDateTime!);

    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/available_slots'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user_ids': selectedUserIds,
        'upper_limit_datetime': upperLimitDatetime,
        'lower_limit_datetime': lowerLimitDatetime,
        'duration_minutes': totalDurationMinutes,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List availableSlots = responseData['available_slots'];
      print(availableSlots);
      if (availableSlots.isEmpty) {
        Fluttertoast.showToast(
          msg: "No available slots found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        String selectedSlot = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Available Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableSlots.map<Widget>((slot) {
                    return ListTile(
                      title: Text("${slot['start_time']} - ${slot['end_time']}"),
                      onTap: () {
                        Navigator.of(context).pop(slot['start_time']);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );

        if (selectedSlot != null) {
          DateTime selectedStart = DateTime.parse(selectedSlot);
          DateTime selectedEnd = selectedStart.add(Duration(minutes: totalDurationMinutes));
          String formattedStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedStart);
          String formattedEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedEnd);

          Navigator.of(context).pop({
            'title': titleController.text,
            'start_datetime': formattedStart,
            'end_datetime': formattedEnd,
            'user_ids': selectedUserIds,
          });
        }
      }
    } else {
      Fluttertoast.showToast(
        msg: "Failed to fetch available slots",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Meeting', style: TextStyle(color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => _pickDateTime(true),
              child: Text(startDateTime == null ? 'Select Start DateTime' : 'Start: ${startDateTime.toString()}'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => _pickDateTime(false),
              child: Text(endDateTime == null ? 'Select End DateTime' : 'End: ${endDateTime.toString()}'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _pickDuration,
              child: Text('Select Duration'),
            ),
            SizedBox(height: 10),
            Text('Select Users:'),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedUserIds.map((userId) {
                  String userName = widget.groupUserList.firstWhere((user) => user['user_id'] == userId)['user_name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(userName),
                      deleteIcon: Icon(Icons.remove),
                      onDeleted: () {
                        setState(() {
                          selectedUserIds.remove(userId);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(),
            Text('All Users:'),
            Container(
              height: MediaQuery.of(context).size.width * 0.5,
              width: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.groupUserList.length,
                itemBuilder: (context, index) {
                  final user = widget.groupUserList[index];
                  return ListTile(
                    title: Text(user['user_name']),
                    trailing: IconButton(
                      icon: Icon(
                        selectedUserIds.contains(user['user_id']) ? Icons.remove : Icons.add,
                      ),
                      onPressed: () {
                        setState(() {
                          if (selectedUserIds.contains(user['user_id'])) {
                            selectedUserIds.remove(user['user_id']);
                          } else {
                            selectedUserIds.add(user['user_id']);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          child: Text('Cancel', style: TextStyle(color: Color(0xff33beb1))),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            side: BorderSide(color: Color(0xff33beb1)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Check Availability', style: TextStyle(color: Color(0xfff1ead0))),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff33beb1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          onPressed: () {
            if (startDateTime == null || endDateTime == null) {
              Fluttertoast.showToast(
                msg: "Please select start and end date and time",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0,
              );
              return;
            }
            _checkAvailableSlots();
          },
        ),
      ],
    );
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color currentColor;

  ColorPickerDialog({required this.currentColor});

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  Color _selectedColor = Color(0xfff17877);

  final List<Color> _presetColors = [
    Color(0xfff17877),
    Color(0xffAD85F1),
    Color(0xff8596F1),
    Color(0xffF185ED),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
            this.setState(() {
            });
          },
          availableColors: _presetColors,
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Select'),
          onPressed: () {
            Navigator.of(context).pop(_selectedColor);
          },
        ),
      ],
    );
  }
}
