import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int userId;
  final int groupId;

  GroupDetailsScreen({required this.userId, required this.groupId});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class Tag {
  int id;
  String name;
  Color color;

  Tag(this.id, this.name, this.color);

  static Color intToColor(int hexColor) {
    return Color((0xFF000000 + hexColor).toUnsigned(32));
  }

  static int colorToInt(Color color) {
    return (color.value & 0xFFFFFF);
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
  int noticenumber = 3;
  int _selectedIndex = 0;
  Tag? selectedTag;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.89:80/group_details'),
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
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load group details')),
      );
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
        Uri.parse('http://172.10.7.89:80/create_team'),
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
      Container(), // 빈 페이지
      Container(), // 빈 페이지
      Container(), // 빈 페이지
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
        Uri.parse('http://172.10.7.89:80/edit_groupTags'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'group_id': widget.groupId,
          'tags': tagList.map((tag) => {
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(noticenumber, (index) {
                  return Text('Notices');
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Tags', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editTag(tag),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
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
                          }
                        }
                      },
                      child: Text('Apply Tags'),
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
            onTap: null,
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
      title: Text('Create Team'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(labelText: 'Team Name'),
            ),
            SizedBox(height: 10),
            Text('Selected Users:'),
            for (int userId in selectedUserIds)
              Text(
                widget.groupUserList.firstWhere((user) => user['user_id'] == userId)['user_name'],
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
