import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportController {
  final _supabase = Supabase.instance.client;

  Future<ReportSummary> fetchReportData(DateTimeRange dateRange) async {
    final startStr = dateRange.start.toIso8601String();
    final endStr = dateRange.end.add(const Duration(days: 1)).toIso8601String();

    // Fetch Bookings
    final bookingsData = await _supabase
        .from('bookings')
        .select('total_price, reservation_datetime, status')
        .gte('reservation_datetime', startStr)
        .lt('reservation_datetime', endStr);

    // Fetch Expenses
    final expensesData = await _supabase
        .from('expenses')
        .select('amount, expense_date')
        .gte('expense_date', startStr)
        .lt('expense_date', endStr);

    int income = 0;
    int expense = 0;
    Map<String, Map<String, dynamic>> statsMap = {};

    DateTime curr = dateRange.start;
    while (curr.isBefore(dateRange.end.add(const Duration(days: 1)))) {
      final dateKey = "${curr.year}-${curr.month.toString().padLeft(2,'0')}-${curr.day.toString().padLeft(2,'0')}";
      statsMap[dateKey] = {'date': curr, 'income': 0, 'expense': 0, 'profit': 0};
      curr = curr.add(const Duration(days: 1));
    }

    for (var b in bookingsData) {
      if (b['status'] == 'dibatalkan') continue;
      final price = (b['total_price'] as num?)?.toInt() ?? 0;
      final bDate = DateTime.parse(b['reservation_datetime']).toLocal();
      final dateKey = "${bDate.year}-${bDate.month.toString().padLeft(2,'0')}-${bDate.day.toString().padLeft(2,'0')}";
      
      income += price;
      if (statsMap.containsKey(dateKey)) {
        statsMap[dateKey]!['income'] = (statsMap[dateKey]!['income'] as int) + price;
      }
    }

    for (var e in expensesData) {
      final amount = (e['amount'] as num?)?.toInt() ?? 0;
      final eDate = DateTime.parse(e['expense_date']).toLocal();
      final dateKey = "${eDate.year}-${eDate.month.toString().padLeft(2,'0')}-${eDate.day.toString().padLeft(2,'0')}";
      
      expense += amount;
      if (statsMap.containsKey(dateKey)) {
        statsMap[dateKey]!['expense'] = (statsMap[dateKey]!['expense'] as int) + amount;
      }
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
    );
  }

  Future<void> addExpense({required int amount, required String category}) async {
    await _supabase.from('expenses').insert({
      'amount': amount,
      'category': category,
      'expense_date': DateTime.now().toIso8601String(),
    });
  }
}
