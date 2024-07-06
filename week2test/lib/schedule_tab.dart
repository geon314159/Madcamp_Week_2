import 'package:flutter/material.dart';

class ScheduleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Tab'),
      ),
      body: Center(
        child: Text(
          'Schedule Tab Content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
