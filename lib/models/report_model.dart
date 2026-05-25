class IncomeDetail {
  final DateTime date;
  final String invoiceId;
  final String customerName;
  final String services;
  final String category;
  final int price;

  IncomeDetail({
    required this.date,
    required this.invoiceId,
    required this.customerName,
    required this.services,
    required this.category,
    required this.price,
  });
}

class ExpenseDetail {
  final DateTime date;
  final String name;
  final String category;
  final int amount;

  ExpenseDetail({
    required this.date,
    required this.name,
    required this.category,
    required this.amount,
  });
}

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
  final List<IncomeDetail> incomeDetails;
  final List<ExpenseDetail> expenseDetails;

  ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
    required this.dailyStats,
    required this.incomeDetails,
    required this.expenseDetails,
  });
}
