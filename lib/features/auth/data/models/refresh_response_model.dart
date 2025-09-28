class RefreshResponse {
  final String accessToken;
  final int accessTokenExpiry;
  final int userId;

  RefreshResponse({
    required this.accessToken,
    required this.accessTokenExpiry,
    required this.userId,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'],
      accessTokenExpiry: json['accessTokenExpiry'],
      userId: json['userId'],
    );
  }
}
