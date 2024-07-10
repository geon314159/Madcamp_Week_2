import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'group_details.dart'; // Import Tag class from group_details.dart
import 'models.dart';
import 'package:path/path.dart' as Path;

class CreateGroupPostScreen extends StatefulWidget {
  final int groupId;
  final int userId;
  final int teamId;
  final List<Tag> tagList; // Add tagList to the constructor

  CreateGroupPostScreen({required this.groupId, required this.teamId, required this.userId, required this.tagList});

  @override
  _CreateGroupPostScreenState createState() => _CreateGroupPostScreenState();
}

class _CreateGroupPostScreenState extends State<CreateGroupPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  List<Tag> selectedTags = [];
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  Future<void> _pickImage() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles);
      });
    }
  }

  Future<void> _createPost() async {
    setState(() {
      _isLoading = true;
    });
    List<int> selectedIds = selectedTags.map((tag) => tag.id).toList();
    print('selectedtags: $selectedIds');

    final uri = widget.teamId == -1
        ? Uri.parse('http://172.10.7.130:80/create_group_notice')
        : Uri.parse('http://172.10.7.130:80/create_team_notice');

    var request = http.MultipartRequest('POST', uri);
    request.fields['user_group_id'] = widget.groupId.toString();
    request.fields['user_team_id'] = widget.teamId.toString();
    request.fields['user_id'] = widget.userId.toString();
    request.fields['title'] = _titleController.text;
    request.fields['content'] = _contentController.text;
    request.fields['tag_ids'] = jsonEncode(selectedIds);

    // Adding images as a list
    for (var imageFile in _imageFiles) {
      var file = await http.MultipartFile.fromPath(
        'images',
        imageFile.path,
        filename: Path.basename(imageFile.path),
      );
      request.files.add(file);
    }

    final response = await request.send();

    print(response.reasonPhrase);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      Fluttertoast.showToast(
        msg: "Post created successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.of(context).pop();
    } else {
      Fluttertoast.showToast(
        msg: "Failed to create post",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text('Create new Post', style: TextStyle(fontSize: 25, color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
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
                hintText: 'write here..',
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
                hintText: 'write here..',
                border: OutlineInputBorder(),
              ),
              maxLines: 5, // Larger input area for content
            ),
            SizedBox(height: 20),
            Text(
              'Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Images'),
            ),
            SizedBox(height: 8),
            _imageFiles.isNotEmpty
                ? Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _imageFiles.map((file) {
                return Image.file(
                  File(file.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                );
              }).toList(),
            )
                : Text('No images selected'),
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
                    child: Container(child: _generateTagsForFilter(tag.color, tag.name, isSelected, tag)),
                  );
                },
              ),
            ),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _createPost,
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
