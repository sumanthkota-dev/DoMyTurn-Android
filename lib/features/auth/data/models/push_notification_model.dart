class PushNotification {
  final String title;
  final String body;
  final String token;

  PushNotification({
    required this.title,
    required this.body,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'token': token,
  };
}
