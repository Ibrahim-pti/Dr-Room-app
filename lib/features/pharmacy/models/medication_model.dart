class Medication {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;

  Medication({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}
