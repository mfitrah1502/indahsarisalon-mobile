class ServiceModel {
  final int tdId;
  final int treatmentId;
  final String treatmentName;
  final String detailName;
  final String displayName;
  final String category;
  final int duration;
  final int price;

  ServiceModel({
    required this.tdId,
    required this.treatmentId,
    required this.treatmentName,
    required this.detailName,
    required this.displayName,
    required this.category,
    required this.duration,
    required this.price,
  });
}
