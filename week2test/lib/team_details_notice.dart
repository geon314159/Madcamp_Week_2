import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'create_groupPost.dart'; // Reuse this for creating posts
import 'edit_groupPost.dart'; // Reuse this for editing posts
import 'models.dart'; // Import the shared models
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TeamDetailsNoticeScreen extends StatefulWidget {
  final int userId;
  final int teamId;
  List<Tag> tagList = [];

  TeamDetailsNoticeScreen({required this.userId, required this.teamId, required this.tagList});

  @override
  _TeamDetailsNoticeScreenState createState() => _TeamDetailsNoticeScreenState();
}

class _TeamDetailsNoticeScreenState extends State<TeamDetailsNoticeScreen> {
  String teamName = '';
  int leaderId = 0;
  List<Tag> appliedtagList = [];
  List<Post> teamPosts = [];
  List<Post> filteredPosts = []; // Add a new list for filtered posts
  Tag? selectedTag;
  bool isLoading = false; // Add a loading flag

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/team_details'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': widget.userId,
        'team_id': widget.teamId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        teamName = responseData['team_name'];
        leaderId = responseData['leader_id'];
        widget.tagList = List<Tag>.from(responseData['tag_list'].map((tag) => Tag(
          tag[0],
          tag[1],
          Tag.intToColor(tag[2]),
        )));
        teamPosts = List<Post>.from(responseData['notice_list'].map((notice) => Post(
            notice['id'],
            -1, // group_id는 null로 설정
            widget.teamId,
            notice['author_id'],
            notice['author_profile_image'] ?? '',
            notice['title'],
            notice['content'],
            notice['tags'] != null ? List<Tag>.from(notice['tags'].map((tag) => Tag(
              tag['tag_id'],
              tag['tag_name'],
              Tag.intToColor(tag['color_hex']),
            ))) : [],
            List<String>.from(notice['images']) // Add image URLs here
        )));
        filteredPosts = teamPosts; // Initialize filteredPosts with all posts
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load team details')),
      );
    }
  }

  String getProfileImageUrl(String filePath) {
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
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
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
                            groupId: -1,
                            teamId: widget.teamId,
                            userId: widget.userId,
                            tagList: widget.tagList,
                          ),
                        ));
                        if (result == true) {
                          _fetchTeamDetails(); // Refresh the posts if an update occurred
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

  Widget _buildTeamDetails() {
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
                      itemCount: widget.tagList.length,
                      itemBuilder: (BuildContext context, int index) {
                        Tag tag = widget.tagList[index];
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
                            /*IconButton(
                              icon: Icon(Icons.more_horiz),
                              onPressed: () => _editTag(tag),
                            ),*/
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyTagFilter() {
    setState(() {
      isLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        filteredPosts = teamPosts.where((post) {
          return appliedtagList.every((tag) => post.postTags.any((postTag) => postTag.id == tag.id));
        }).toList();
        isLoading = false;
      });
    });
  }

  void _editTag(Tag tag) {
    TextEditingController tagNameController = TextEditingController(text: tag.name);
    Color selectedColor = tag.color;

    Future<void> _updateTeamTags() async {
      final response = await http.post(
        Uri.parse('http://172.10.7.130:80/edit_teamTags'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'team_id': widget.teamId,
          'tags': widget.tagList.map((tag) => {
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
                _updateTeamTags();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text('$teamName', style: TextStyle(fontSize: 28, color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
      ),
      body: _buildTeamDetails(),
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
            child: Icon(Icons.comment, size: 24.0),
            backgroundColor: Color(0xffa0d9d3),
            label: 'Create Notice',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            labelStyle: TextStyle(fontSize: 13.0),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreateGroupPostScreen(groupId: -1, teamId: widget.teamId, userId: widget.userId, tagList: widget.tagList),
              ));
            },
          ),
        ],
      )
          : null,
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
