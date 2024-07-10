import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GroupScheduleTab extends StatefulWidget {
  final int groupId;

  GroupScheduleTab({required this.groupId});

  @override
  _GroupScheduleTabState createState() => _GroupScheduleTabState();
}

class _GroupScheduleTabState extends State<GroupScheduleTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  final DateFormat _dateFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");

  @override
  void initState() {
    super.initState();
    _fetchGroupSchedule();
  }

  Future<void> _fetchGroupSchedule() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/get_group_calendar'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_group_id': widget.groupId,
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _events = _parseEvents(responseData);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load group schedule')),
      );
    }
  }

  Map<DateTime, List<dynamic>> _parseEvents(Map<String, dynamic> data) {
    Map<DateTime, List<dynamic>> events = {};

    for (var event in data['group_calendar']) {
      DateTime startDateTime = _dateFormat.parse(event['start_datetime']);
      DateTime eventDate = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      event['type'] = 'group';
      if (events.containsKey(eventDate)) {
        events[eventDate]?.add(event);
      } else {
        events[eventDate] = [event];
      }
    }

    for (var event in data['team_calendars']) {
      DateTime startDateTime = _dateFormat.parse(event['start_datetime']);
      DateTime eventDate = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      event['type'] = 'team';
      if (events.containsKey(eventDate)) {
        events[eventDate]?.add(event);
      } else {
        events[eventDate] = [event];
      }
    }

    return events;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _editMeeting(dynamic event) async {
    TextEditingController titleController = TextEditingController(text: event['title']);
    DateTime startDateTime = _dateFormat.parse(event['start_datetime']);
    DateTime endDateTime = _dateFormat.parse(event['end_datetime']);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Meeting', style: TextStyle(color: Color(0xff33beb1), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: startDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startDateTime),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        startDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                      });
                    }
                  }
                },
                child: Text('Start: ${DateFormat('yyyy-MM-dd HH:mm').format(startDateTime)}'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: endDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endDateTime),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        endDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                      });
                    }
                  }
                },
                child: Text('End: ${DateFormat('yyyy-MM-dd HH:mm').format(endDateTime)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xff33beb1))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save', style: TextStyle(color: Color(0xfff1ead0))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff33beb1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop({
                  'meeting_id': event['meeting_id'],
                  'title': titleController.text,
                  'start_datetime': DateFormat('yyyy-MM-dd HH:mm:ss').format(startDateTime),
                  'end_datetime': DateFormat('yyyy-MM-dd HH:mm:ss').format(endDateTime),
                });
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final response = await http.post(
        Uri.parse('http://172.10.7.130:80/update_meeting'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'meeting_id': result['meeting_id'],
          'title': result['title'],
          'start_datetime': result['start_datetime'],
          'end_datetime': result['end_datetime'],
          'user_ids': [], // You can update this with the relevant user IDs if needed
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meeting successfully updated')),
        );
        _fetchGroupSchedule();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update meeting')),
        );
      }
    }
  }

  void _deleteMeeting(dynamic event) async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/delete_meeting'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'meeting_id': event['meeting_id'],
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting successfully deleted')),
      );
      _fetchGroupSchedule();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete meeting')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          ..._getEventsForDay(_selectedDay ?? _focusedDay).map((event) => ListTile(
            title: Text(event['title']),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_dateFormat.parse(event['start_datetime'])) +
                ' - ' +
                DateFormat('HH:mm').format(_dateFormat.parse(event['end_datetime']))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editMeeting(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteMeeting(event),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
