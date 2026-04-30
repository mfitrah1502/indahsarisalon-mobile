class DashboardStatsModel {
  final int todayBookings;
  final int todayRevenue;
  final int todayCustomers;
  final num bookingsIncrease;
  final num revenueIncrease;
  final num customersIncrease;

  DashboardStatsModel({
    required this.todayBookings,
    required this.todayRevenue,
    required this.todayCustomers,
    required this.bookingsIncrease,
    required this.revenueIncrease,
    required this.customersIncrease,
  });
}
