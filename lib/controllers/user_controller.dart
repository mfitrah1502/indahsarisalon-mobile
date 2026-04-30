import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserController {
  final _supabase = Supabase.instance.client;

  Future<List<UserModel>> fetchAvailableStylists(DateTime selectedDate) async {
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

    // Get active users
    final userData = await _supabase
        .from('users')
        .select('id, username, name, type, role, status, email, password, avatar, phone')
        .eq('type', 'karyawan')
        .neq('role', 'pelanggan')
        .eq('status', 'aktif');
        
    // Get absensi for date
    final absensiData = await _supabase
        .from('absensi')
        .select('user_id, status')
        .eq('tanggal', dateStr);

    final offUserIds = <int>{};
    for (var row in absensiData) {
      if (row['status'] == 'off') {
        offUserIds.add(row['user_id'] as int);
      }
    }
    
    final availableStylists = <UserModel>[];
    for (var u in userData) {
      if (!offUserIds.contains(u['id'])) {
        availableStylists.add(UserModel.fromJson(u));
      }
    }
    
    return availableStylists;
  }

  Future<List<UserModel>> fetchAllStylists() async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('type', 'karyawan')
        .neq('role', 'pelanggan')
        .order('name');
        
    return (data as List<dynamic>).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> deleteStylist(int id) async {
    await _supabase.from('users').delete().eq('id', id);
  }

  Future<void> saveStylist(Map<String, dynamic> payload, {int? id}) async {
    if (id != null) {
      await _supabase.from('users').update(payload).eq('id', id);
    } else {
      await _supabase.from('users').insert(payload);
    }
  }

  Future<List<UserModel>> fetchCustomers() async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('role', 'pelanggan')
        .order('name');
        
    return (data as List<dynamic>).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCustomersWithSpend() async {
    final usersData = await _supabase
        .from('users')
        .select('id, name, email, phone, is_colour_circle, colour_circle_expired_at')
        .eq('role', 'pelanggan');

    final bookingsData = await _supabase
        .from('bookings')
        .select('customer_name, customer_phone, customer_email, total_price, status, user_id');
        
    final Map<String, Map<String, dynamic>> map = {};
    
    for (final user in usersData) {
      final name = (user['name'] ?? 'Customer').toString().trim();
      final phone = (user['phone'] ?? '').toString().trim();
      final email = (user['email'] ?? '').toString().trim();
      
      final key = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : "id_${user['id']}");
      
      map[key] = {
        'id': user['id'],
        'name': name,
        'phone': phone,
        'email': email,
        'spend': 0,
        'key': key,
        'is_colour_circle': user['is_colour_circle'] ?? false,
        'colour_circle_expired_at': user['colour_circle_expired_at'],
      };
    }

    for (final row in bookingsData) {
      final name = (row['customer_name'] ?? 'Customer').toString().trim();
      final phone = (row['customer_phone'] ?? '').toString().trim();
      final email = (row['customer_email'] ?? '').toString().trim();
      final userId = row['user_id'];
      
      String? key;
      if (phone.isNotEmpty) {
        key = phone;
      } else if (email.isNotEmpty) {
        key = email;
      }

      if (key == null && userId != null) {
        try {
          key = map.entries.firstWhere((e) => e.value['id'] == userId).key;
        } catch (_) {
          key = "id_$userId";
        }
      }

      if (key == null) continue;

      if (!map.containsKey(key)) {
        map[key] = {
          'name': name,
          'phone': phone,
          'email': email,
          'spend': 0,
          'key': key,
          'is_colour_circle': false,
          'colour_circle_expired_at': null,
        };
      }
      
      if (row['status'] != 'dibatalkan') {
        map[key]!['spend'] += (row['total_price'] as num?)?.toInt() ?? 0;
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => (b['spend'] as int).compareTo(a['spend'] as int));
    return list;
  }

  Future<void> deleteCustomers(List<Map<String, dynamic>> customersToDelete) async {
    List<int> userIds = [];
    List<String> phones = [];
    List<String> emails = [];

    for (var cust in customersToDelete) {
      if (cust['id'] != null) {
        userIds.add(cust['id'] as int);
      }
      if (cust['phone'] != null && cust['phone'].toString().isNotEmpty) {
        phones.add(cust['phone'].toString());
      }
      if (cust['email'] != null && cust['email'].toString().isNotEmpty) {
        emails.add(cust['email'].toString());
      }
    }

    List<int> bookingIds = [];
    
    if (userIds.isNotEmpty) {
      final res = await _supabase.from('bookings').select('id').inFilter('user_id', userIds);
      bookingIds.addAll((res as List).map((e) => e['id'] as int));
    }
    if (phones.isNotEmpty) {
      final res = await _supabase.from('bookings').select('id').inFilter('customer_phone', phones);
      bookingIds.addAll((res as List).map((e) => e['id'] as int));
    }
    if (emails.isNotEmpty) {
      final res = await _supabase.from('bookings').select('id').inFilter('customer_email', emails);
      bookingIds.addAll((res as List).map((e) => e['id'] as int));
    }
    
    bookingIds = bookingIds.toSet().toList();

    if (bookingIds.isNotEmpty) {
      await _supabase.from('booking_details').delete().inFilter('booking_id', bookingIds);
    }

    if (userIds.isNotEmpty) {
      await _supabase.from('booking_details').update({'stylist_id': null}).inFilter('stylist_id', userIds);
      await _supabase.from('bookings').update({'stylist_id': null}).inFilter('stylist_id', userIds);
      await _supabase.from('bookings').update({'cashier_id': null, 'stylist_id': null}).inFilter('cashier_id', userIds);
    }

    if (bookingIds.isNotEmpty) {
      await _supabase.from('bookings').delete().inFilter('id', bookingIds);
    }

    if (userIds.isNotEmpty) {
      await _supabase.from('users').delete().inFilter('id', userIds);
    }
  }
}
