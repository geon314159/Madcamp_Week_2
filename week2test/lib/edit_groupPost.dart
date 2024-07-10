import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:week2test/main.dart';
import 'group_details.dart'; // Import Tag class from group_details.dart
import 'models.dart';

class EditGroupPostScreen extends StatefulWidget {
  final Post post;
  final int groupId;
  final int teamId;
  final int userId;
  final List<Tag> tagList;

  EditGroupPostScreen({required this.post, required this.groupId, required this.teamId, required this.userId, required this.tagList});

  @override
  _EditGroupPostScreenState createState() => _EditGroupPostScreenState();
}

class _EditGroupPostScreenState extends State<EditGroupPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  List<Tag> selectedTags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    selectedTags = widget.post.postTags;
  }

  Future<void> _updatePost() async {
    setState(() {
      _isLoading = true;
    });

    late final response;

    if(widget.teamId == -1)
    {
      //print("here");
      response = await http.put(
        Uri.parse('http://172.10.7.130:80/update_group_notice'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'group_notice_id': widget.post.id,
          'user_id' : userId,
          'title': _titleController.text,
          'content': _contentController.text,
          'tag_ids': selectedTags.map((tag) => tag.id).toList(),
          //'images' : []
        }),
      );
    }
    else
    {
      response = await http.put(
        Uri.parse('http://172.10.7.130:80/update_team_notice'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'team_notice_id': widget.post.id,
          'user_id' : userId,
          'title': _titleController.text,
          'content': _contentController.text,
          'tag_ids': selectedTags.map((tag) => tag.id).toList(),
          'images' : []
        }),
      );
    }

    print(response.body);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "Post updated successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(
        msg: "Failed to update post",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deletePost() async {

    late final response;
    if(widget.teamId == -1)
      {
        response = await http.delete(
          Uri.parse('http://172.10.7.130:80/delete_group_notice'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'group_notice_id': widget.post.id,
          }),
        );
      }
    else {
      response = await http.delete(
        Uri.parse('http://172.10.7.130:80/delete_team_notice'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'team_notice_id': widget.post.id,
        }),
      );
    }

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "Post deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(
        msg: "Failed to delete post",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _generateTagsForFilter(Color? c, String s, bool isSelected, Tag tag) {
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
                    selectedTags.remove(tag);
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

  Future<void> _confirmDeletePost() async {
    final bool? result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deletePost();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text('Edit Post', style: TextStyle(fontSize: 25, color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _confirmDeletePost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Edit title here..',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Contents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Edit contents here..',
                border: OutlineInputBorder(),
              ),
              maxLines: 5, // Larger input area for content
            ),
            SizedBox(height: 20),
            Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedTags.length,
                itemBuilder: (context, index) {
                  Tag tag = selectedTags[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _generateTagsForFilter(tag.color, tag.name, true, tag),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Available Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.tagList.length,
                itemBuilder: (context, index) {
                  Tag tag = widget.tagList[index];
                  bool isSelected = selectedTags.contains(tag);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedTags.remove(tag);
                        } else {
                          selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: _generateTagsForFilter(tag.color, tag.name, isSelected, tag),
                    ),
                  );
                },
              ),
            ),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _updatePost,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
