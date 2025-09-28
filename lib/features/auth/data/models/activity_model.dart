class Activity {
  final String action;
  final DateTime timestamp;

  Activity({
    required this.action,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
