class RegisterRequest {
  final String userName;
  final String email;
  final String mobile;
  final String password;
  final String avatarSvg;

  RegisterRequest({
    required this.userName,
    required this.email,
    required this.mobile,
    required this.password,
    required this.avatarSvg,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'email': email,
    'mobile': mobile,
    'password': password,
    'avatarSvg': avatarSvg,
  };
}
