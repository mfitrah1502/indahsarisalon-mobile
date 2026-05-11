import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportController {
  final _supabase = Supabase.instance.client;

  Future<ReportSummary> fetchReportData(DateTimeRange dateRange) async {
    final startStr = dateRange.start.toIso8601String();
    final endStr = dateRange.end.add(const Duration(days: 1)).toIso8601String();

    List<dynamic> bookingsData = [];
    List<dynamic> expensesData = [];
    Map<int, List<Map<String, dynamic>>> detailsMap = {};

    try {
      // Fetch Bookings
      bookingsData = await _supabase
          .from('bookings')
          .select('id, total_price, reservation_datetime, status, customer_name')
          .gte('reservation_datetime', startStr)
          .lt('reservation_datetime', endStr);
      
      final bookingIds = bookingsData.map((b) => b['id']).toList();
      if (bookingIds.isNotEmpty) {
        try {
          final detailsData = await _supabase
              .from('booking_details')
              .select('booking_id, treatment_details(name, treatments(name, categories(name)))')
              .inFilter('booking_id', bookingIds);
          
          for (var d in detailsData) {
            final bId = d['booking_id'] as int;
            if (!detailsMap.containsKey(bId)) detailsMap[bId] = [];
            detailsMap[bId]!.add(d);
          }
        } catch (e) {
          debugPrint("Error fetching booking details: $e");
        }
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    }

    try {
      // Fetch Expenses (Removing 'name' as it might not exist in DB yet)
      expensesData = await _supabase
          .from('expenses')
          .select('amount, expense_date, category')
          .gte('expense_date', startStr)
          .lt('expense_date', endStr);
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
    }

    int income = 0;
    int expense = 0;
    Map<String, Map<String, dynamic>> statsMap = {};
    List<IncomeDetail> incomeDetails = [];
    List<ExpenseDetail> expenseDetails = [];

    DateTime curr = dateRange.start;
    final isYearly = dateRange.end.difference(dateRange.start).inDays > 60;

    while (curr.isBefore(dateRange.end.add(const Duration(days: 1)))) {
      final dateKey = isYearly 
          ? "${curr.year}-${curr.month.toString().padLeft(2,'0')}"
          : "${curr.year}-${curr.month.toString().padLeft(2,'0')}-${curr.day.toString().padLeft(2,'0')}";
      if (!statsMap.containsKey(dateKey)) {
        statsMap[dateKey] = {'date': isYearly ? DateTime(curr.year, curr.month, 1) : curr, 'income': 0, 'expense': 0, 'profit': 0};
      }
      curr = isYearly ? DateTime(curr.year, curr.month + 1, 1) : curr.add(const Duration(days: 1));
    }

    for (var b in bookingsData) {
      if (b['status'] == 'dibatalkan') continue;
      final price = (b['total_price'] as num?)?.toInt() ?? 0;
      final bDate = DateTime.parse(b['reservation_datetime']).toLocal();
      final dateKey = isYearly
          ? "${bDate.year}-${bDate.month.toString().padLeft(2,'0')}"
          : "${bDate.year}-${bDate.month.toString().padLeft(2,'0')}-${bDate.day.toString().padLeft(2,'0')}";
      
      income += price;
      if (statsMap.containsKey(dateKey)) {
        statsMap[dateKey]!['income'] = (statsMap[dateKey]!['income'] as int) + price;
      }

      // Prepare IncomeDetail
      final bId = b['id'] as int;
      final bDetails = detailsMap[bId] ?? [];
      String services = bDetails.map((d) {
        final td = d['treatment_details'] as Map?;
        final t = td?['treatments'] as Map?;
        String tName = t?['name'] ?? '';
        String tdName = td?['name'] ?? '';
        return tName == tdName || tdName.isEmpty ? tName : "$tName - $tdName";
      }).where((s) => s.isNotEmpty).join(", ");
      
      String category = 'Service';
      if (bDetails.isNotEmpty) {
        final td = bDetails[0]['treatment_details'] as Map?;
        final t = td?['treatments'] as Map?;
        final c = t?['categories'] as Map?;
        category = (c?['name'] as String?) ?? 'Service';
      }

      incomeDetails.add(IncomeDetail(
        date: bDate,
        invoiceId: "INV-$bId",
        customerName: b['customer_name'] ?? '-',
        services: services.isEmpty ? "Booking #$bId" : services,
        category: category,
        price: price,
      ));
    }

    for (var e in expensesData) {
      final amount = (e['amount'] as num?)?.toInt() ?? 0;
      final eDate = DateTime.parse(e['expense_date']).toLocal();
      final dateKey = isYearly
          ? "${eDate.year}-${eDate.month.toString().padLeft(2,'0')}"
          : "${eDate.year}-${eDate.month.toString().padLeft(2,'0')}-${eDate.day.toString().padLeft(2,'0')}";
      
      expense += amount;
      if (statsMap.containsKey(dateKey)) {
        statsMap[dateKey]!['expense'] = (statsMap[dateKey]!['expense'] as int) + amount;
      }

      expenseDetails.add(ExpenseDetail(
        date: eDate,
        name: e['category'] ?? 'Pengeluaran', // Use category as name since name column is missing
        category: e['category'] ?? 'others',
        amount: amount,
      ));
    }

    final list = statsMap.values.toList();
    list.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    List<ReportDailyStat> dailyStats = [];
    for (var s in list) {
      final statProfit = (s['income'] as int) - (s['expense'] as int);
      dailyStats.add(ReportDailyStat(
        date: s['date'] as DateTime,
        income: s['income'] as int,
        expense: s['expense'] as int,
        profit: statProfit,
      ));
    }

    return ReportSummary(
      totalIncome: income,
      totalExpense: expense,
      totalProfit: income - expense,
      dailyStats: dailyStats,
      incomeDetails: incomeDetails,
      expenseDetails: expenseDetails,
    );
  }

  Future<void> addExpense({required String name, required int amount, required String category}) async {
    // Note: We might not be able to save 'name' if the column doesn't exist.
    // For now, let's keep it safe. If 'name' column is added later, this will work.
    // To be safe, we can try to insert and if it fails, insert without name.
    try {
      await _supabase.from('expenses').insert({
        'name': name,
        'amount': amount,
        'category': category,
        'expense_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Failed to insert with name, trying without: $e");
      await _supabase.from('expenses').insert({
        'amount': amount,
        'category': category,
        'expense_date': DateTime.now().toIso8601String(),
      });
    }
  }
}
