import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';

class ScheduleTable extends StatefulWidget {
  final int userId;

  ScheduleTable({required this.userId});

  @override
  _ScheduleTableState createState() => _ScheduleTableState();
}

class _ScheduleTableState extends State<ScheduleTable> {
  List<WeeklySchedule> userSchedules = [];

  final List<String> timePeriods = List.generate(97, (index) {
    final hour = (index ~/ 4).toString().padLeft(2, '0');
    final minute = ((index % 4) * 15).toString().padLeft(2, '0');
    return '$hour:$minute';
  });

  final List<String> daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Map<String, Map<String, Color?>> schedule = {};
  final List<Color> colors = [
    Color(0xfff19985),
    Color(0xfff17877),
    Color(0xffAD85F1),
    Color(0xff33beb1),
    Color(0xffa0d9d3),
    Color(0xff1B6760),
  ];
  final Map<String, Color> subjectColors = {};

  @override
  void initState() {
    super.initState();
    for (var day in daysOfWeek) {
      schedule[day] = {};
      for (var time in timePeriods) {
        schedule[day]![time] = null;
      }
    }
    _fetchUserTimetable();
  }

  Future<void> _fetchUserTimetable() async {
    final url = 'http://172.10.7.130:80/get_weekly_timetable';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int>{
        'user_id': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['timetable'] as List;
      final Map<String, List<ScheduleItem>> subjectToItems = {};

      for (var item in data) {
        final subject = item['subject'];
        if (!subjectToItems.containsKey(subject)) {
          subjectToItems[subject] = [];
        }
        subjectToItems[subject]!.add(ScheduleItem.fromJson(item));
      }

      setState(() {
        userSchedules = subjectToItems.entries.map((entry) {
          final subject = entry.key;
          final color = subjectColors.putIfAbsent(
            subject,
                () => colors[subjectColors.length % colors.length],
          );
          return WeeklySchedule(
            subject: subject,
            color: color,
            scheduleItems: entry.value,
          );
        }).toList();
        _updateSchedule();
      });
    } else {
      // Handle the error accordingly
      print('Failed to load timetable');
    }
  }

  void _updateSchedule() {
    for (var scheduleItem in userSchedules) {
      final color = scheduleItem.color;
      for (var item in scheduleItem.scheduleItems) {
        final day = item.weekday;
        final startIdx = timePeriods.indexOf(item.startTime);
        final endIdx = timePeriods.indexOf(item.endTime);

        for (var i = startIdx; i <= endIdx; i++) {
          schedule[day]![timePeriods[i]] = color;
        }
      }
    }
  }

  Future<void> _manageTimetableEntries(Map<String, dynamic> data) async {
    final url = 'http://172.10.7.130:80/manage_timetable_entries';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      _fetchUserTimetable();
    } else {
      // Handle the error accordingly
      print('Failed to manage timetable entries');
    }
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedSubject;
        String newSubject = '';
        String selectedDay = daysOfWeek[0];
        String startTime = timePeriods[0];
        String endTime = timePeriods[1];

        return AlertDialog(
          title: Text('Add Schedule'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    hint: Text('Select Subject'),
                    items: [
                      ...userSchedules.map((schedule) => DropdownMenuItem<String>(
                        value: schedule.subject,
                        child: Text(schedule.subject),
                      )),
                      DropdownMenuItem<String>(
                        value: 'New Subject_',
                        child: Text('New Subject',style: TextStyle(color: Color(0xff33beb1)),),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                      });
                    },
                  ),
                  if (selectedSubject == 'New Subject_')
                    TextField(
                      decoration: InputDecoration(labelText: 'New Subject Name'),
                      onChanged: (value) {
                        newSubject = value;
                      },
                    ),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: daysOfWeek
                        .map((day) => DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDay = value!;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: startTime,
                    items: timePeriods
                        .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        startTime = value!;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: endTime,
                    items: timePeriods
                        .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        endTime = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedSubject == 'New Subject_' && newSubject.isNotEmpty) {
                  selectedSubject = newSubject;
                }
                if (selectedSubject != null && selectedSubject!.isNotEmpty) {
                  _manageTimetableEntries({
                    'user_id': widget.userId,
                    'new_entries': [
                      {
                        'weekday': selectedDay,
                        'start_time': '$startTime:00',
                        'end_time': '$endTime:00',
                        'subject': selectedSubject,
                      }
                    ],
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedSubject;
        ScheduleItem? selectedScheduleItem;
        String selectedDay = daysOfWeek[0];
        String startTime = timePeriods[0];
        String endTime = timePeriods[1];

        return AlertDialog(
          title: Text('Edit Schedule'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    hint: Text('Select Subject'),
                    items: userSchedules
                        .map((schedule) => DropdownMenuItem<String>(
                      value: schedule.subject,
                      child: Text(schedule.subject),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                        selectedScheduleItem = null; // Reset the selected schedule item when subject changes
                      });
                    },
                  ),
                  if (selectedSubject != null)
                    DropdownButtonFormField<ScheduleItem>(
                      hint: Text('Select Time Block'),
                      value: selectedScheduleItem,
                      items: userSchedules
                          .firstWhere((schedule) => schedule.subject == selectedSubject)
                          .scheduleItems
                          .map((item) => DropdownMenuItem<ScheduleItem>(
                        value: item,
                        child: Text('${item.weekday} ${item.startTime}-${item.endTime}'),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedScheduleItem = value;
                          if (value != null) {
                            selectedDay = value.weekday;
                            startTime = value.startTime;
                            endTime = value.endTime;
                          }
                        });
                      },
                    ),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: daysOfWeek
                        .map((day) => DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDay = value!;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: startTime,
                    items: timePeriods
                        .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        startTime = value!;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: endTime,
                    items: timePeriods
                        .map((time) => DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        endTime = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedSubject != null && selectedScheduleItem != null) {
                  _manageTimetableEntries({
                    'user_id': widget.userId,
                    'update_entries': [
                      {
                        'timetable_id': selectedScheduleItem!.Id,
                        'weekday': selectedDay,
                        'start_time': '$startTime:00',
                        'end_time': '$endTime:00',
                        'subject': selectedSubject,
                      }
                    ],
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 30,
                      color: Colors.grey[200],
                      child: Center(child: Text('Time')),
                    ),
                    ...daysOfWeek.map((day) => Container(
                      width: 40,
                      height: 30,
                      color: Colors.grey[200],
                      child: Center(child: Text(day)),
                    )),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: timePeriods.map((time) {
                        return Row(
                          children: [
                            Container(
                              width: 40,
                              height: 30,
                              color: Colors.grey[200],
                              child: Center(child: Text(time)),
                            ),
                            ...daysOfWeek.map((day) {
                              final cellColor = schedule[day]![time];
                              return Container(
                                width: 40,
                                height: 30,
                                color: cellColor ?? Colors.white,
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showAddScheduleDialog,
              child: Text('Add Schedule'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _showEditScheduleDialog,
              child: Text('Edit Schedule'),
            ),
          ],
        ),
      ],
    );
  }
}
