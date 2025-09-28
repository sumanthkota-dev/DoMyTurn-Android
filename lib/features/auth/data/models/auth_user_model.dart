class AuthUser {
  // final int id;
  final String email;
  // final String userName;
  final bool isVerified;

  AuthUser({
    // required this.id,
    required this.email,
    // required this.userName,
    required this.isVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      // id: json['id'],
      email: json['email'],
      // userName: json['userName'],
      isVerified: json['isVerified'] ?? false,
    );
  }
}
