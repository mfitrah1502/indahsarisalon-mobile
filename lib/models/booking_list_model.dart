class BookingListModel {
  final int id;
  final String createdAt;
  final String stylist;
  final List<String> services;
  final String datetime;
  final num totalPrice;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final Map<String, dynamic> rawData;
  
  BookingListModel({
    required this.id,
    required this.createdAt,
    required this.stylist,
    required this.services,
    required this.datetime,
    required this.totalPrice,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.rawData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt,
      'stylist': stylist,
      'services': services,
      'datetime': datetime,
      'total_price': totalPrice,
      'status': status,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      ...rawData,
    };
  }
}
