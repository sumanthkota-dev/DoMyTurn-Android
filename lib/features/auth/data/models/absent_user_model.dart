class AbsentUser {
  final int userId;
  final String name;
  final bool isAbsent;

  AbsentUser({
    required this.userId,
    required this.name,
    required this.isAbsent,
  });

  factory AbsentUser.fromJson(Map<String, dynamic> json) {
    return AbsentUser(
      userId: json['userId'] as int,
      name: json['name'] ?? '',
      isAbsent: json['isAbsent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'isAbsent': isAbsent,
    };
  }
}
