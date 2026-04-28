import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
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
  List<Map<String, dynamic>> dailyStats = [];
  bool isLoading = true;

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

    final supabase = Supabase.instance.client;

    try {
      final startStr = _dateRange!.start.toIso8601String();
      final endStr = _dateRange!.end.add(const Duration(days: 1)).toIso8601String();

      // Fetch Bookings
      final bookingsData = await supabase
          .from('bookings')
          .select('total_price, reservation_datetime, status')
          .gte('reservation_datetime', startStr)
          .lt('reservation_datetime', endStr);

      // Fetch Expenses
      final expensesData = await supabase
          .from('expenses')
          .select('amount, expense_date')
          .gte('expense_date', startStr)
          .lt('expense_date', endStr);

      int income = 0;
      int expense = 0;
      Map<String, Map<String, dynamic>> statsMap = {};

      DateTime curr = _dateRange!.start;
      while (curr.isBefore(_dateRange!.end.add(const Duration(days: 1)))) {
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
      
      for (var s in list) {
        s['profit'] = (s['income'] as int) - (s['expense'] as int);
      }

      if (mounted) {
        setState(() {
          totalIncome = income;
          totalExpense = expense;
          totalProfit = income - expense;
          dailyStats = list;
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
                        await Supabase.instance.client.from('expenses').insert({
                          'amount': amount,
                          'category': category,
                          'expense_date': DateTime.now().toIso8601String(),
                        });
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
        final date = DateFormat('yyyy-MM-dd').format(s['date'] as DateTime);
        sheetObject.appendRow([
          TextCellValue(date),
          IntCellValue(s['income'] as int),
          IntCellValue(s['expense'] as int),
          IntCellValue(s['profit'] as int),
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
      if (s['income'] > maxY) maxY = (s['income'] as int).toDouble();
      if (s['expense'] > maxY) maxY = (s['expense'] as int).toDouble();
    }
    if (maxY == 0) maxY = 100000;
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
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
                    final date = dailyStats[idx]['date'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 9)),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailyStats.asMap().entries.map((e) {
            int i = e.key;
            var s = e.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (s['income'] as int).toDouble(),
                  color: Colors.green.shade400,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: (s['expense'] as int).toDouble(),
                  color: Colors.red.shade400,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfitChart() {
    if (dailyStats.isEmpty) return const SizedBox();
    
    double maxY = 0;
    double minY = 0;
    for (var s in dailyStats) {
      if (s['profit'] > maxY) maxY = (s['profit'] as int).toDouble();
      if (s['profit'] < minY) minY = (s['profit'] as int).toDouble();
    }
    if (maxY == 0 && minY == 0) maxY = 100000;
    
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY < 0 ? minY * 1.2 : 0,
          maxY: maxY * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < dailyStats.length) {
                    if (dailyStats.length > 7 && idx % (dailyStats.length ~/ 5) != 0) return const SizedBox();
                    final date = dailyStats[idx]['date'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 9)),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dailyStats.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value['profit'] as int).toDouble());
              }).toList(),
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withOpacity(0.2),
              ),
            ),
          ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Performance",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "IN SELECTED RANGE",
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stat cards
                  _buildHorizontalStatCard(Icons.arrow_downward, "PEMASUKAN", formatCurrency(totalIncome), Colors.green),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(Icons.arrow_upward, "PENGELUARAN", formatCurrency(totalExpense), Colors.red),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(Icons.attach_money, "PROFIT", formatCurrency(totalProfit), primaryColor),
                  const SizedBox(height: 32),

                  Text("Pemasukan & Pengeluaran", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.green.shade400), const SizedBox(width: 4),
                      const Text("Pemasukan", style: TextStyle(fontSize: 10)), const SizedBox(width: 12),
                      Container(width: 10, height: 10, color: Colors.red.shade400), const SizedBox(width: 4),
                      const Text("Pengeluaran", style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildIncomeExpenseChart(),
                  const SizedBox(height: 32),

                  Text("Grafik Profit", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildProfitChart(),
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

  Widget _buildHorizontalStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: mutedText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
