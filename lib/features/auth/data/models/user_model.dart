class User {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String gender;
  final DateTime? dateOfBirth;
  final String address;
  final String city;
  final String country;
  final String? avatarSvg;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.gender,
    this.dateOfBirth,
    required this.address,
    required this.city,
    required this.country,
    required this.avatarSvg,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      avatarSvg: json['avatarSvg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'avatarSvg': avatarSvg,
    };
  }

  // ✅ Add this method
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? mobile,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
    String? avatarSvg,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      avatarSvg: avatarSvg ?? this.avatarSvg,
    );
  }
}
