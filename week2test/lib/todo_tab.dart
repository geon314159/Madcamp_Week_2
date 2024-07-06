import 'package:flutter/material.dart';

class TodoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Tab'),
      ),
      body: Center(
        child: Text(
          'Todo Tab Content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
