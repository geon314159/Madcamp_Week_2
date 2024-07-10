import 'package:flutter/material.dart';

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

class Post {
  int id;
  int group_id;
  int team_id;
  int author_id;
  String title;
  String content;
  List<Tag> postTags;
  String author_profile_url;
  List<dynamic> imageLists;

  Post(this.id, this.group_id, this.team_id, this.author_id, this.author_profile_url, this.title, this.content, this.postTags, this.imageLists);
}

class WeeklySchedule {
  String subject;
  Color color;
  List<ScheduleItem> scheduleItems;

  WeeklySchedule({
    required this.subject,
    required this.color,
    required this.scheduleItems,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      subject: json['subject'],
      color: Colors.transparent, // Temporary, to be assigned later
      scheduleItems: (json['schedule_items'] as List)
          .map((item) => ScheduleItem.fromJson(item))
          .toList(),
    );
  }
}

class ScheduleItem {
  String weekday;
  String startTime;
  String endTime;
  int Id;

  ScheduleItem({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.Id,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      weekday: json['weekday'],
      startTime: json['start_time'].substring(0, 5),
      endTime: json['end_time'].substring(0, 5),
      Id: json['id'],
    );
  }
}
