import 'dart:convert';

enum TaskType { DAY, DATE, GAP, CONDITIONAL, PAYMENT }

String taskTypeToString(TaskType type) {
  return type.name;
}

class CreateChoreRequest {
  final String title;
  final String description;
  final TaskType taskType;
  final List<int> assigneeIds;
  final int homeId;
  final String startDate;
  final int frequency;

  CreateChoreRequest({
    required this.title,
    required this.description,
    required this.taskType,
    required this.assigneeIds,
    required this.homeId,
    required this.startDate,
    required this.frequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'taskType': taskTypeToString(taskType),
      'assigneeIds': assigneeIds,
      'homeId': homeId,
      'startDate': startDate,
      'frequency': frequency,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
