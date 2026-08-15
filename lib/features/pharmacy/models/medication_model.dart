class Medication {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final int stock;
  final String? imageUrl;

  Medication({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.stock,
    this.imageUrl,
  });

  bool get isOutOfStock => stock <= 0;
  bool get hasDiscount =>
      (originalPrice != null && originalPrice! > price) ||
      (discountPercent != null && discountPercent! > 0);

  int get calculatedDiscountPercent {
    if (discountPercent != null && discountPercent! > 0) {
      return discountPercent!;
    }
    if (originalPrice != null && originalPrice! > price) {
      return (((originalPrice! - price) / originalPrice!) * 100).round();
    }
    return 0;
  }

  double get effectiveOriginalPrice {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice!;
    }
    if (discountPercent != null && discountPercent! > 0) {
      return (price / (1 - (discountPercent! / 100.0)));
    }
    return price;
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.parse(json['price'].toString()),
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      discountPercent: json['discount_percent'] != null
          ? int.tryParse(json['discount_percent'].toString())
          : null,
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}
