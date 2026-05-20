import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_list_model.dart';

class BookingListController {
  final _supabase = Supabase.instance.client;

  Future<List<BookingListModel>> fetchBookings() async {
    final data = await _supabase
        .from('bookings')
        .select('id, created_at, reservation_datetime, total_price, status, customer_name, customer_phone, customer_email, user_id, stylist_id, payment_method, users!bookings_stylist_id_fkey(name, avatar), customer:users!bookings_user_id_fkey(phone, email, avatar)')
        .order('created_at', ascending: false);

    final List<BookingListModel> enriched = [];
    for (final row in data) {
      final bookingId = row['id'];
      final details = await _supabase
          .from('booking_details')
          .select('price, treatment_detail_id, treatment_details(name, price, treatment_id, image_url, treatments(name, image))')
          .eq('booking_id', bookingId);

      List<String> serviceNames = [];
      for (final d in details) {
        final td = d['treatment_details'] as Map<String, dynamic>?;
        final t = td?['treatments'] as Map<String, dynamic>?;
        final tName = t?['name'] ?? '';
        final dName = td?['name'] ?? '';
        if (tName == dName || dName.isEmpty) {
          serviceNames.add(tName);
        } else {
          serviceNames.add("$tName - $dName");
        }
      }

      dynamic stylistData = row['users'];
      String stylistName = 'Unknown';
      String? stylistAvatar;
      if (stylistData != null) {
        if (stylistData is Map) {
          stylistName = stylistData['name'] ?? 'Unknown';
          stylistAvatar = stylistData['avatar'] as String?;
        } else if (stylistData is List && stylistData.isNotEmpty) {
          stylistName = stylistData[0]['name'] ?? 'Unknown';
          stylistAvatar = stylistData[0]['avatar'] as String?;
        }
      }

      Map<String, dynamic>? linkedCustomer = row['customer'] as Map<String, dynamic>?;
      String finalPhone = row['customer_phone'] ?? '-';
      String finalEmail = row['customer_email'] ?? '-';
      String? customerAvatar = linkedCustomer?['avatar'] as String?;

      if ((finalPhone == '-' || finalPhone == 'null') && linkedCustomer != null) {
        finalPhone = linkedCustomer['phone'] ?? '-';
      }
      if ((finalEmail == '-' || finalEmail == 'null') && linkedCustomer != null) {
        finalEmail = linkedCustomer['email'] ?? '-';
      }

      enriched.add(BookingListModel(
        id: bookingId,
        createdAt: row['created_at'],
        stylist: stylistName,
        stylistAvatar: stylistAvatar,
        customerAvatar: customerAvatar,
        services: serviceNames.isEmpty ? ['Booking #$bookingId'] : serviceNames,
        datetime: row['reservation_datetime'],
        totalPrice: row['total_price'],
        status: row['status'] ?? 'pending',
        customerName: row['customer_name'] ?? '-',
        customerPhone: finalPhone,
        customerEmail: finalEmail,
        paymentMethod: row['payment_method'] ?? 'Tunai',
        rawData: {
          ...row,
          'full_details': details, // Include individual prices
        },
      ));
    }

    return enriched;
  }

  Future<BookingListModel?> fetchBookingById(int id) async {
    final data = await _supabase
        .from('bookings')
        .select('id, created_at, reservation_datetime, total_price, status, customer_name, customer_phone, customer_email, user_id, stylist_id, payment_method, users!bookings_stylist_id_fkey(name, avatar), customer:users!bookings_user_id_fkey(phone, email, avatar)')
        .eq('id', id)
        .maybeSingle();
        
    if (data == null) return null;

    final details = await _supabase
        .from('booking_details')
        .select('price, treatment_detail_id, treatment_details(name, price, treatment_id, image_url, treatments(name, image))')
        .eq('booking_id', id);

    List<String> serviceNames = [];
    for (final d in details) {
      final td = d['treatment_details'] as Map<String, dynamic>?;
      final t = td?['treatments'] as Map<String, dynamic>?;
      final tName = t?['name'] ?? '';
      final dName = td?['name'] ?? '';
      if (tName == dName || dName.isEmpty) {
        serviceNames.add(tName);
      } else {
        serviceNames.add("$tName - $dName");
      }
    }

    dynamic stylistData = data['users'];
    String stylistName = 'Unknown';
    String? stylistAvatar;
    if (stylistData != null) {
      if (stylistData is Map) {
        stylistName = stylistData['name'] ?? 'Unknown';
        stylistAvatar = stylistData['avatar'] as String?;
      } else if (stylistData is List && stylistData.isNotEmpty) {
        stylistName = stylistData[0]['name'] ?? 'Unknown';
        stylistAvatar = stylistData[0]['avatar'] as String?;
      }
    }

    Map<String, dynamic>? linkedCustomer = data['customer'] as Map<String, dynamic>?;
    String finalPhone = data['customer_phone'] ?? '-';
    String finalEmail = data['customer_email'] ?? '-';
    String? customerAvatar = linkedCustomer?['avatar'] as String?;

    if ((finalPhone == '-' || finalPhone == 'null') && linkedCustomer != null) {
      finalPhone = linkedCustomer['phone'] ?? '-';
    }
    if ((finalEmail == '-' || finalEmail == 'null') && linkedCustomer != null) {
      finalEmail = linkedCustomer['email'] ?? '-';
    }

    return BookingListModel(
      id: id,
      createdAt: data['created_at'],
      stylist: stylistName,
      stylistAvatar: stylistAvatar,
      customerAvatar: customerAvatar,
      services: serviceNames.isEmpty ? ['Booking #$id'] : serviceNames,
      datetime: data['reservation_datetime'],
      totalPrice: data['total_price'],
      status: data['status'] ?? 'pending',
      customerName: data['customer_name'] ?? '-',
      customerPhone: finalPhone,
      customerEmail: finalEmail,
      paymentMethod: data['payment_method'] ?? 'Tunai',
      rawData: {
        ...data,
        'full_details': details,
      },
    );
  }

  Future<void> deleteAllBookings() async {
    await _supabase.from('booking_details').delete().neq('id', 0);
    await _supabase.from('bookings').delete().neq('id', 0);
  }
}
