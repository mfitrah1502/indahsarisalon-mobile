import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_model.dart';
import '../models/dashboard_stats_model.dart';

class HomeController {
  final _supabase = Supabase.instance.client;

  Future<List<PromoModel>> fetchPromos() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('promos')
          .select('id, title, description, price, image_url, start_at, end_at, is_active')
          .eq('is_active', true)
          .lte('start_at', now)
          .gte('end_at', now)
          .order('created_at', ascending: false);
      
      return (data as List).map((e) => PromoModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Error fetching promos: $e");
    }
  }

  Future<DashboardStatsModel> fetchDashboardData() async {
    try {
      final now = DateTime.now();
      // Today bounds (Local)
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      
      // Yesterday bounds (Local)
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day).toIso8601String();
      final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59).toIso8601String();

      // Fetch Today's bookings based on reservation date
      final todayData = await _supabase
          .from('bookings')
          .select('id, user_id, total_price, reservation_datetime, payment_status, status, customer_name')
          .gte('reservation_datetime', todayStart)
          .lte('reservation_datetime', todayEnd)
          .neq('status', 'dibatalkan');

      // Fetch Yesterday's bookings based on reservation date
      final yesterdayData = await _supabase
          .from('bookings')
          .select('id, user_id, total_price, reservation_datetime, payment_status, status, customer_name')
          .gte('reservation_datetime', yesterdayStart)
          .lte('reservation_datetime', yesterdayEnd)
          .neq('status', 'dibatalkan');

      // Calculate Today Stats
      int tBookings = todayData.length;
      int tRev = 0;
      Set<String> tCustomers = {};
      for (var b in todayData) {
        // Count all non-cancelled bookings for revenue (to match ReportController)
        tRev += (b['total_price'] as num?)?.toInt() ?? 0;
        
        final uId = b['user_id']?.toString();
        final cName = b['customer_name']?.toString();
        
        if (uId != null && uId != 'null') {
          tCustomers.add("u_$uId");
        } else if (cName != null) {
          tCustomers.add("g_$cName");
        }
      }

      // Calculate Yesterday Stats
      int yBookings = yesterdayData.length;
      int yRev = 0;
      Set<String> yCustomers = {};
      for (var b in yesterdayData) {
        yRev += (b['total_price'] as num?)?.toInt() ?? 0;
        
        final uId = b['user_id']?.toString();
        final cName = b['customer_name']?.toString();
        
        if (uId != null && uId != 'null') {
          yCustomers.add("u_$uId");
        } else if (cName != null) {
          yCustomers.add("g_$cName");
        }
      }

      // Calculate percentage increase
      double bInc = yBookings == 0 ? (tBookings > 0 ? 100 : 0) : ((tBookings - yBookings) / yBookings) * 100;
      double rInc = yRev == 0 ? (tRev > 0 ? 100 : 0) : ((tRev - yRev) / yRev) * 100;
      double cInc = yCustomers.isEmpty ? (tCustomers.isNotEmpty ? 100 : 0) : ((tCustomers.length - yCustomers.length) / yCustomers.length) * 100;

      return DashboardStatsModel(
        todayBookings: tBookings,
        todayRevenue: tRev,
        todayCustomers: tCustomers.length,
        bookingsIncrease: bInc,
        revenueIncrease: rInc,
        customersIncrease: cInc,
      );
    } catch (e) {
      throw Exception("Error fetching dashboard data: $e");
    }
  }
}
