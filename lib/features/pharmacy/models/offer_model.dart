class PharmacyOffer {
  final int id;
  final String title;
  final String? description;
  final double discountPercentage;
  final String? imageUrl;

  PharmacyOffer({
    required this.id,
    required this.title,
    this.description,
    required this.discountPercentage,
    this.imageUrl,
  });

  factory PharmacyOffer.fromJson(Map<String, dynamic> json) {
    return PharmacyOffer(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      discountPercentage: double.parse(json['discount_percentage'].toString()),
      imageUrl: json['image_url'],
    );
  }
}
