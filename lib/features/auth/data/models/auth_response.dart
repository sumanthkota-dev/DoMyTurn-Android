class AuthResponse {
  final String accessToken;
  final int accessTokenExpiry;
  final String refreshToken;
  final int refreshTokenExpiry;
  final int userId;

  AuthResponse({
    required this.accessToken,
    required this.accessTokenExpiry,
    required this.refreshToken,
    required this.refreshTokenExpiry,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      accessTokenExpiry: json['accessTokenExpiry'] is int
          ? json['accessTokenExpiry']
          : int.parse(json['accessTokenExpiry'].toString()),
      refreshToken: json['refreshToken'],
      refreshTokenExpiry: json['refreshTokenExpiry'] is int
          ? json['refreshTokenExpiry']
          : int.parse(json['refreshTokenExpiry'].toString()),
      userId: json['userId'] is int
          ? json['userId']
          : int.parse(json['userId'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'accessTokenExpiry': accessTokenExpiry,
      'refreshToken': refreshToken,
      'refreshTokenExpiry': refreshTokenExpiry,
      'userId': userId,
    };
  }
}
