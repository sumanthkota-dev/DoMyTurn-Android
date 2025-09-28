import 'dart:convert';

enum TaskType { DAY, DATE, GAP}
class Chore {
  static String taskTypeToString(TaskType type) => type.name;

  static TaskType stringToTaskType(String value) =>
  TaskType.values.firstWhere((e) => e.name == value, orElse: () {
  throw Exception("Invalid TaskType: $value");
  });
  final int? id;
  final String title;
  final int homeId;
  final String description;
  final List<int> assignees;
  final TaskType taskType;
  final Set<int> completedUsers;
  final int? lastCompletedBy;
  final int? performer;
  final DateTime? startDate;
  final DateTime? dueDate;
  final bool repeatIfAbsent;
  final bool isOverDue;
  final int? frequency;
  final bool paymentTask;


  Chore({
    this.id,
    required this.title,
    required this.homeId,
    required this.description,
    required this.assignees,
    required this.taskType,
    this.completedUsers = const {},
    this.lastCompletedBy,
    this.performer,
    this.startDate,
    this.dueDate,
    required this.repeatIfAbsent,
    required this.isOverDue,
    this.frequency,
    this.paymentTask = false, // ✅ default to false
  });

  factory Chore.fromJson(Map<String, dynamic> json) {
    return Chore(
      id: json['id'],
      title: json['title'],
      homeId: json['homeId'],
      description: json['description'],
      assignees: List<int>.from(json['assignees']),
      taskType: stringToTaskType(json['taskType']),
      completedUsers: json['completedUsers'] != null
          ? Set<int>.from(json['completedUsers'])
          : {},
      lastCompletedBy: json['lastCompletedBy'],
      performer: json['performer'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      repeatIfAbsent: json['repeatIfAbsent'],
      isOverDue: json['isOverDue'] ?? false,
      frequency: json['frequency'], // ✅ add this line
      paymentTask: json['paymentTask'] ?? false,
    );
  }


  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'homeId': homeId,
      'description': description,
      'assignees': assignees,
      'taskType': taskTypeToString(taskType),
      'completedUsers': completedUsers.toList(),
      'lastCompletedBy': lastCompletedBy,
      'performer': performer,
      'startDate': startDate?.toIso8601String().split('T').first,
      'dueDate': dueDate?.toIso8601String().split('T').first,
      'repeatIfAbsent': repeatIfAbsent,
      'isOverDue': isOverDue,
      'frequency': frequency, // ✅ add this line
      'paymentTask' : paymentTask,
    };
  }

  Chore copyWith({
    int? id,
    String? title,
    int? homeId,
    String? description,
    List<int>? assignees,
    TaskType? taskType,
    Set<int>? completedUsers,
    int? lastCompletedBy,
    int? performer,
    DateTime? startDate,
    DateTime? dueDate,
    bool? repeatIfAbsent,
    bool? isOverDue,
    int? frequency, // ✅ Add frequency
    bool? paymentTask,
  }) {
    return Chore(
      id: id ?? this.id,
      title: title ?? this.title,
      homeId: homeId ?? this.homeId,
      description: description ?? this.description,
      assignees: assignees ?? this.assignees,
      taskType: taskType ?? this.taskType,
      completedUsers: completedUsers ?? this.completedUsers,
      lastCompletedBy: lastCompletedBy ?? this.lastCompletedBy,
      performer: performer ?? this.performer,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      repeatIfAbsent: repeatIfAbsent ?? this.repeatIfAbsent,
      isOverDue: isOverDue ?? this.isOverDue,
      frequency: frequency ?? this.frequency, // ✅ Add this line
      paymentTask: paymentTask ?? this.paymentTask,
    );
  }


}
