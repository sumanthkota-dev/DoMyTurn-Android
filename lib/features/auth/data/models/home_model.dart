import 'package:domyturn/features/auth/data/models/user_model.dart';

class Home {
  final int id;
  final String name;
  final String address;
  final String? city;
  final String? district;
  final String? state;
  final String? country;
  final String? pincode;
  final int creatorId;
  final List<User> users;

  Home({
    required this.id,
    required this.name,
    required this.address,
    this.district,
    this.city,
    this.state,
    this.country,
    this.pincode,
    required this.creatorId,
    required this.users,
  });

  factory Home.fromJson(Map<String, dynamic> json) {
    return Home(
      id: json['homeId'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      creatorId: json['creatorId'] ?? 0,
      users: (json['users'] as List<dynamic>?)
          ?.map((u) => User.fromJson(u))
          .toList() ??
          [],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'creatorId': creatorId,
      'users': users.map((u) => u.toJson()).toList(),
    };
  }
}
