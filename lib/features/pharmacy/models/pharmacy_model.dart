class Pharmacy {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImage;
  final double deliveryFee;
  final double rating;
  final bool isOpen;

  Pharmacy({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profileImage,
    this.deliveryFee = 0.0,
    this.rating = 0.0,
    this.isOpen = false,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      deliveryFee: (json['delivery_fee'] ?? 3000).toDouble(),
      rating: (json['rating'] ?? 5.0).toDouble(),
      isOpen: json['is_open'] ?? true,
    );
  }
}
