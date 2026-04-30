class ReportDailyStat {
  final DateTime date;
  final int income;
  final int expense;
  final int profit;

  ReportDailyStat({
    required this.date,
    required this.income,
    required this.expense,
    required this.profit,
  });
}

class ReportSummary {
  final int totalIncome;
  final int totalExpense;
  final int totalProfit;
  final List<ReportDailyStat> dailyStats;

  ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
    required this.dailyStats,
  });
}
