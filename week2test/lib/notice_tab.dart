import 'package:flutter/material.dart';

class NoticeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notice Tab'),
      ),
      body: Center(
        child: Text(
          'Notice Tab Content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
