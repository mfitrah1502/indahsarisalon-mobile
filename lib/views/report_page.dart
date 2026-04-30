import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../controllers/report_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'settings_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final int _selectedIndex = 3;
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  DateTimeRange? _dateRange;

  // Data State
  int totalIncome = 0;
  int totalExpense = 0;
  int totalProfit = 0;
  List<ReportDailyStat> dailyStats = [];
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
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String formatDateRange(DateTimeRange? range) {
    if (range == null) return "";
    final start = DateFormat('MMM d').format(range.start).toUpperCase();
    final end = DateFormat('MMM d').format(range.end).toUpperCase();
    return "$start - $end";
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _fetchData();
    }
  }

  Future<void> _showAddExpenseDialog() async {
    final amountCtrl = TextEditingController();
    String category = 'gaji karyawan';
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Tambah Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "gaji karyawan", child: Text("Gaji Karyawan")),
                      DropdownMenuItem(value: "maintenance", child: Text("Maintenance")),
                      DropdownMenuItem(value: "others", child: Text("Others")),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah (Rp)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal", style: TextStyle(color: mutedText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final amount = int.tryParse(amountCtrl.text) ?? 0;
                    if (amount > 0) {
                      try {
                        await _reportController.addExpense(amount: amount, category: category);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _fetchData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengeluaran berhasil ditambahkan")));
                      } catch (e) {
                        debugPrint("Error adding expense: $e");
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                      }
                    }
                  },
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Report'];
      excel.setDefaultSheet('Report');

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Pemasukan'),
        TextCellValue('Pengeluaran'),
        TextCellValue('Profit'),
      ]);

      // Add Data
      for (var s in dailyStats) {
        final date = DateFormat('yyyy-MM-dd').format(s.date);
        sheetObject.appendRow([
          TextCellValue(date),
          IntCellValue(s.income),
          IntCellValue(s.expense),
          IntCellValue(s.profit),
        ]);
      }
      
      // Add Totals
      sheetObject.appendRow([
        TextCellValue('TOTAL'),
        IntCellValue(totalIncome),
        IntCellValue(totalExpense),
        IntCellValue(totalProfit),
      ]);

      var fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/Salon_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        await Share.shareXFiles([XFile(path)], text: 'Report Salon');
      }
    } catch (e) {
      debugPrint("Error exporting excel: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengunduh report: $e")));
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
                    if (dailyStats.length > 7 && idx % (dailyStats.length ~/ 5) != 0) return const SizedBox();
                    final date = dailyStats[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd MMM').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
                    child: Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.right),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
                BarChartRodData(
                  toY: s.income > 0 ? s.income.toDouble() : 0,
                  color: Colors.blueAccent,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
                BarChartRodData(
                  toY: s.profit > 0 ? s.profit.toDouble() : 0,
                  color: Colors.amber.shade300,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    "Report",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => _pickDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.chevron_left, color: primaryColor, size: 20),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              formatDateRange(_dateRange),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text("TAMBAH PENGELUARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // The new stat cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 85,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Total Income", style: TextStyle(color: mutedText, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(formatCurrency(totalIncome), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
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
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Due Payments", style: TextStyle(color: mutedText, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(formatCurrency(totalExpense), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sales Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                      const Text("More >", style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(formatDateRange(_dateRange), style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  _buildIncomeExpenseChart(),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text("Pemasukan", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text("Pengeluaran", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.amber.shade300, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text("Profit", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "DOWNLOAD REPORT EXCEL",
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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          Icon(
            icon,
            color: isSelected ? primaryColor : mutedText,
            size: 26,
          ),
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
        ],
      ),
    );
  }
}
