class Medication {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? category;
  final String? categoryAr;
  final String? categoryEn;
  final String? description;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final String? badge;
  final String dosageForm;
  final int stock;
  final bool requiresPrescription;
  final String? imageUrl;

  Medication({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.category,
    this.categoryAr,
    this.categoryEn,
    this.description,
    this.descriptionAr,
    this.descriptionEn,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.badge,
    this.dosageForm = 'پاکەت',
    required this.stock,
    this.requiresPrescription = false,
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      category: json['category'],
      categoryAr: json['category_ar'],
      categoryEn: json['category_en'],
      description: json['description'],
      descriptionAr: json['description_ar'],
      descriptionEn: json['description_en'],
      price: double.parse(json['price'].toString()),
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      discountPercent: json['discount_percent'] != null
          ? int.tryParse(json['discount_percent'].toString())
          : null,
      badge: json['badge'],
      dosageForm: json['dosage_form'] ?? 'پاکەت',
      stock: json['stock'] is int ? json['stock'] : int.tryParse(json['stock'].toString()) ?? 0,
      requiresPrescription: json['requires_prescription'] == true || json['requires_prescription'] == 1,
      imageUrl: json['image_url'] ?? json['image_path'],
    );
  }
}
