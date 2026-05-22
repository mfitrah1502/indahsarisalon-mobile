import 'dart:io';
import 'package:flutter/material.dart';
import '../app_session.dart';
import '../models/report_model.dart';
import '../controllers/report_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'settings_page.dart';
import '../utils/pdf_report_helper.dart';
import '../utils/popup_helper.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF6F8FA);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get cardBgAlt => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withOpacity(0.5);
  Color get inputBorderColor => isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

  final int _selectedIndex = 3;

  DateTimeRange? _dateRange;

  // Data State
  int totalIncome = 0;
  int totalExpense = 0;
  int totalProfit = 0;
  List<ReportDailyStat> dailyStats = [];
  List<IncomeDetail> incomeDetails = [];
  List<ExpenseDetail> expenseDetails = [];
  bool isLoading = true;

  final ReportController _reportController = ReportController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final summary = await _reportController.fetchReportData(_dateRange!);
      if (mounted) {
        setState(() {
          totalIncome = summary.totalIncome;
          totalExpense = summary.totalExpense;
          totalProfit = summary.totalProfit;
          dailyStats = summary.dailyStats;
          incomeDetails = summary.incomeDetails;
          expenseDetails = summary.expenseDetails;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Report data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDateRange(DateTimeRange? range) {
    if (range == null) return "";
    final start = DateFormat('MMM d').format(range.start).toUpperCase();
    final end = DateFormat('MMM d').format(range.end).toUpperCase();
    return "$start - $end";
  }

  String _selectedFilter = 'Monthly';

  void _setFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      if (filter == 'Weekly') {
        int currentDay = now.weekday;
        DateTime start = now.subtract(Duration(days: currentDay - 1));
        DateTime end = start.add(const Duration(days: 6));
        _dateRange = DateTimeRange(start: start, end: end);
      } else if (filter == 'Monthly') {
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      } else if (filter == 'Yearly') {
        _dateRange = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      }
    });
    _fetchData();
  }

  Widget _buildFilterSlider() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Weekly', 'Monthly', 'Yearly'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? cardBgAlt : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? primaryColor : mutedText,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAddExpenseDialog() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'employee_salary';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Add Expense",
                style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: mainTextColor),
                    decoration: InputDecoration(
                      labelText: "Expense Name",
                      labelStyle: TextStyle(color: mutedText),
                      hintText: "Example: Electricity, Budi's Salary",
                      hintStyle: TextStyle(color: mutedText.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: cardBg,
                    value: category,
                    style: TextStyle(color: mainTextColor),
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: mutedText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "employee_salary",
                        child: Text("Employee Salary", style: TextStyle(color: mainTextColor)),
                      ),
                      DropdownMenuItem(
                        value: "maintenance",
                        child: Text("Maintenance", style: TextStyle(color: mainTextColor)),
                      ),
                      DropdownMenuItem(
                        value: "others",
                        child: Text("Others", style: TextStyle(color: mainTextColor)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: mainTextColor),
                    decoration: InputDecoration(
                      labelText: "Amount (Rp)",
                      labelStyle: TextStyle(color: mutedText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: mutedText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD660A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final amount = int.tryParse(amountCtrl.text) ?? 0;
                    final name = nameCtrl.text.trim();
                    if (amount > 0 && name.isNotEmpty) {
                      try {
                        await _reportController.addExpense(
                          name: name,
                          amount: amount,
                          category: category,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _fetchData();
                        PopupHelper.showSuccess(
                          context,
                          "Expense added successfully",
                        );
                      } catch (e) {
                        debugPrint("Error adding expense: $e");
                        if (!context.mounted) return;
                        PopupHelper.showError(context, "Failed: $e");
                      }
                    } else {
                      PopupHelper.showError(context, "Please fill in all fields");
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportToPdf() async {
    try {
      final summary = ReportSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalProfit,
        dailyStats: dailyStats,
        incomeDetails: incomeDetails,
        expenseDetails: expenseDetails,
      );
      final bytes = await PdfReportHelper.generatePdf(
        summary: summary,
        dateRange: _dateRange,
      );

      if (!context.mounted) return;

      final now = DateTime.now();
      final fileName = "Report_Salon_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf";

      await Printing.sharePdf(bytes: bytes, filename: fileName);

      PopupHelper.showInfo(context, "PDF Report ready to share/save");
    } catch (e) {
      debugPrint("Error exporting pdf: $e");
      if (!context.mounted) return;
      PopupHelper.showError(context, "Failed to download PDF report: $e");
    }
  }

  Widget _buildIncomeExpenseChart() {
    if (dailyStats.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var s in dailyStats) {
      if (s.income > maxY) maxY = s.income.toDouble();
      if (s.expense > maxY) maxY = s.expense.toDouble();
      if (s.profit > maxY) maxY = s.profit.toDouble();
    }
    if (maxY == 0) maxY = 100000;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < dailyStats.length) {
                    if (dailyStats.length > 7 &&
                        idx % (dailyStats.length ~/ 5) != 0)
                      return const SizedBox();
                    final date = dailyStats[idx].date;
                    final isYearly = _selectedFilter == 'Tahunan';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        isYearly
                            ? DateFormat('MMM').format(date)
                            : DateFormat('dd MMM').format(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedText,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Format large numbers
                  String text;
                  if (value >= 1000000) {
                    text = "${(value / 1000000).toStringAsFixed(1)}M";
                  } else if (value >= 1000) {
                    text = "${(value / 1000).toStringAsFixed(0)}K";
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                  if (value == 0) text = "0";
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 10,
                        color: mutedText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300, width: 1),
              left: BorderSide.none,
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          barGroups: dailyStats.asMap().entries.map((e) {
            int i = e.key;
            var s = e.value;
            return BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                BarChartRodData(
                  toY: s.expense > 0 ? s.expense.toDouble() : 0,
                  color: Colors.redAccent,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
                BarChartRodData(
                  toY: s.income > 0 ? s.income.toDouble() : 0,
                  color: Colors.blueAccent,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
                BarChartRodData(
                  toY: s.profit > 0 ? s.profit.toDouble() : 0,
                  color: Colors.amber.shade300,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox.shrink(),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Report",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28), // balance for the back button
                  ],
                ),
                const SizedBox(height: 24),

                _buildFilterSlider(),
                const SizedBox(height: 16),

                if (AppSession.userRole == 'owner') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddExpenseDialog,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        "ADD EXPENSE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD660A1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // The new stat cards
                  if (AppSession.userRole == 'owner') ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 85,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 12.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Total Income",
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            formatCurrency(totalIncome),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: mainTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 85,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 12.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Expenses",
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            formatCurrency(totalExpense),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: mainTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sales Report",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: mainTextColor,
                        ),
                      ),
                        const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateRange(_dateRange),
                    style: TextStyle(color: mutedText, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _buildIncomeExpenseChart(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Income",
                        style: TextStyle(
                          fontSize: 12,
                          color: mainTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),

                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Expenses",
                        style: TextStyle(
                          fontSize: 12,
                          color: mainTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),

                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Profit",
                        style: TextStyle(
                          fontSize: 12,
                          color: mainTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (AppSession.userRole == 'owner')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _exportToPdf,
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          "DOWNLOAD REPORT PDF",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, "HOME", Icons.home_filled),
              _buildNavItem(1, "BOOKING", Icons.calendar_today_outlined),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded),
              _buildNavItem(4, "SETTINGS", Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  // Replaced unused stat card widget

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BookingListPage()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ManageServicesPage()),
            (route) => false,
          );
        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
            (route) => false,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : mutedText, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSelected ? primaryColor : mutedText,
              letterSpacing: 0.5,
            ),
          ),
        const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
