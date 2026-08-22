class PharmacyOffer {
  final int id;
  final String title;
  final String? promoCode;
  final String? description;
  final double discountPercentage;
  final String? imageUrl;

  PharmacyOffer({
    required this.id,
    required this.title,
    this.promoCode,
    this.description,
    required this.discountPercentage,
    this.imageUrl,
  });

  factory PharmacyOffer.fromJson(Map<String, dynamic> json) {
    return PharmacyOffer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      promoCode: json['promo_code'],
      description: json['description'],
      discountPercentage: json['discount_percentage'] != null
          ? double.tryParse(json['discount_percentage'].toString()) ?? 0.0
          : 0.0,
      imageUrl: json['image_url'] ?? json['image_path'],
    );
  }
}