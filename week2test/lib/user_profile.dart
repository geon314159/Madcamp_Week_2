import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'weekly_time_table.dart'; // Import the WeeklyTimetable widget

class UserProfileScreen extends StatefulWidget {
  final int userId;

  UserProfileScreen({required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String name = '';
  String email = '';
  String profileImage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/user_details'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        name = responseData['name'];
        email = responseData['email'];
        profileImage = responseData['profile_image'];
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  void _openEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProfileDialog(
          userId: widget.userId,
          currentName: name,
          currentProfileImage: profileImage,
          onProfileUpdated: _fetchUserProfile,
        );
      },
    );
  }

  String getProfileImageUrl(String filePath) {
    return 'http://172.10.7.130:80/uploads' + filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(getProfileImageUrl(profileImage)),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 50,),
                    Text(
                      name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: _openEditDialog,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                ScheduleTable(userId: widget.userId)// Add this line
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final int userId;
  final String currentName;
  final String currentProfileImage;
  final VoidCallback onProfileUpdated;

  EditProfileDialog({
    required this.userId,
    required this.currentName,
    required this.currentProfileImage,
    required this.onProfileUpdated,
  });

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _nameController = TextEditingController();
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      isUpdating = true;
    });

    final uri = Uri.parse('http://172.10.7.130:80/update_profile');
    var request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = widget.userId.toString();
    request.fields['name'] = _nameController.text;
    if (_image != null) {
      var imageFile = await http.MultipartFile.fromPath(
        'file',
        _image!.path,
        filename: Path.basename(_image!.path),
      );
      request.files.add(imageFile);
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
      widget.onProfileUpdated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }

    setState(() {
      isUpdating = false;
    });

    Navigator.of(context).pop();
  }

  String getProfileImageUrl(String filePath) {
    return 'http://172.10.7.130:80/uploads' + filePath;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            _image == null
                ? CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(getProfileImageUrl(widget.currentProfileImage)),
            )
                : Image.file(File(_image!.path), height: 100, width: 100),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Change Profile Image'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUpdating ? null : _updateProfile,
          child: isUpdating ? CircularProgressIndicator() : Text('Save'),
        ),
      ],
    );
  }
}
