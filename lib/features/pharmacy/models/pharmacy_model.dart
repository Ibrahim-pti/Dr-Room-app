class Pharmacy {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? email;
  final String? phone;
  final String? address;
  final String? location;
  final String? city;
  final String? profileImage;
  final List<String> galleryImages;
  final double deliveryFee;
  final String deliveryTime;
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final bool isVerified;
  final String? facebookUrl;
  final double? latitude;
  final double? longitude;
  final String? bio;

  Pharmacy({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.email,
    this.phone,
    this.address,
    this.location,
    this.city,
    this.profileImage,
    this.galleryImages = const [],
    this.deliveryFee = 3000.0,
    this.deliveryTime = '۲۰-۳۰ خولەک',
    this.rating = 4.9,
    this.totalReviews = 0,
    this.isOpen = true,
    this.isVerified = true,
    this.facebookUrl,
    this.latitude,
    this.longitude,
    this.bio,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    List<String> gallery = [];
    if (json['gallery_images'] != null) {
      if (json['gallery_images'] is List) {
        gallery = (json['gallery_images'] as List).map((e) => e.toString()).toList();
      }
    }

    return Pharmacy(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'] ?? json['location'],
      location: json['location'] ?? json['address'],
      city: json['city'] ?? 'هەولێر',
      profileImage: json['profile_image'],
      galleryImages: gallery,
      deliveryFee: json['delivery_fee'] != null ? double.tryParse(json['delivery_fee'].toString()) ?? 3000.0 : 3000.0,
      deliveryTime: json['delivery_time'] ?? '۲۰-۳۰ خولەک',
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 4.9 : 4.9,
      totalReviews: json['total_reviews'] != null ? int.tryParse(json['total_reviews'].toString()) ?? 0 : 0,
      isOpen: json['is_open'] == true || json['is_open'] == 1 || json['is_open'] == '1',
      isVerified: json['is_verified'] ?? true,
      facebookUrl: json['facebook_url'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      bio: json['bio'],
    );
  }
}