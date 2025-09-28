class HomeUpdateDto {
  final String name;
  final String address;
  final String? district;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;


  HomeUpdateDto({
    required this.name,
    required this.address,
    this.district,
    this.city,
    this.state,
    this.country,
    this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }
}
