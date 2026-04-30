class PromoModel {
  final int? id;
  final String title;
  final String? description;
  final int price;
  final String? imageUrl;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;

  PromoModel({
    this.id,
    required this.title,
    this.description,
    required this.price,
    this.imageUrl,
    required this.startAt,
    required this.endAt,
    required this.isActive,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Promo Menarik',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
