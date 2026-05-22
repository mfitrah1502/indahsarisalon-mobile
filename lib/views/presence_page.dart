import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../app_session.dart';

class PresencePage extends StatefulWidget {
  const PresencePage({super.key});

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFFAFAFC);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFFBE7A9F); // Elegant muted pink/rose font
  Color get darkText => isDark ? const Color(0xFFCBD5E1) : const Color(0xFFB53D7C);  // Deep premium pink font

  List<Map<String, dynamic>> _staffs = [];
  Map<int, String> _absensiMap = {}; // Maps user_id to status ('hadir' or 'off') for the selected date
  bool _isLoading = true;
  String _searchQuery = "";

  late final List<DateTime> _dates;
  int _selectedDateIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildDates();
    _fetchData();
  }

  void _buildDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (i) => now.add(Duration(days: i)));
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final selectedDate = _dates[_selectedDateIndex];
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      // Fetch all staffs
      final usersData = await Supabase.instance.client
          .from('users')
          .select('id, name, role, avatar, status')
          .eq('type', 'karyawan')
          .neq('role', 'pelanggan')
          .neq('role', 'owner')
          .neq('role', 'admin')
          .eq('status', 'aktif') // Only active employees
          .order('name');

      // Fetch absensi for the selected date
      final absensiData = await Supabase.instance.client
          .from('absensi')
          .select('user_id, status')
          .eq('tanggal', dateStr);

      final newAbsensiMap = <int, String>{};
      for (var row in absensiData) {
        newAbsensiMap[row['user_id'] as int] = row['status'] as String;
      }

      if (mounted) {
        setState(() {
          _staffs = List<Map<String, dynamic>>.from(usersData);
          _absensiMap = newAbsensiMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(int userId, String newStatus) async {
    try {
      final selectedDate = _dates[_selectedDateIndex];
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      // Standardize status for database compatibility
      final dbStatus = (newStatus.toLowerCase() == 'present' || newStatus == 'hadir') ? 'hadir' : 'off';

      // Update local optimistically
      if (mounted) {
        setState(() {
          _absensiMap[userId] = dbStatus;
        });
      }

      // Upsert to absensi table
      final existing = await Supabase.instance.client
          .from('absensi')
          .select('id')
          .eq('user_id', userId)
          .eq('tanggal', dateStr)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('absensi')
            .update({
              'status': dbStatus,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('absensi').insert({
          'user_id': userId,
          'tanggal': dateStr,
          'status': dbStatus,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Error updating absensi: $e");
    }
  }

  Color _getRoleBgColor(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r.contains('stylist') || r.contains('hair')) {
      return isDark ? const Color(0xFF075985) : const Color(0xFFE0F2FE); // blue
    } else if (r.contains('beautician')) {
      return isDark ? const Color(0xFF831843) : const Color(0xFFFCE7F3); // pink/rose
    } else if (r.contains('therapist')) {
      return isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5); // green
    }
    return isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  }

  Color _getRoleTextColor(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r.contains('stylist') || r.contains('hair')) {
      return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1); // blue
    } else if (r.contains('beautician')) {
      return isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D); // pink
    } else if (r.contains('therapist')) {
      return isDark ? const Color(0xFF34D399) : const Color(0xFF047857); // green
    }
    return isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaffs = _staffs.where((staff) {
      final query = _searchQuery.toLowerCase();
      final nameStr = (staff['name'] ?? '').toString().toLowerCase();
      return nameStr.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header (Unified back button and title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Staff Attendance",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Manage staff attendance & schedule today",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Premium Sleek Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                    hintText: "Search staff name...",
                    hintStyle: TextStyle(color: mutedText.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Premium Date Timeline
            SizedBox(
              height: 82,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDateIndex;
                  final d = _dates[index];
                  final isToday = DateFormat('yyyyMMdd').format(d) == DateFormat('yyyyMMdd').format(DateTime.now());
                  
                  const dayNames = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];

                  return GestureDetector(
                    onTap: () {
                      if (_selectedDateIndex != index) {
                        setState(() => _selectedDateIndex = index);
                        _fetchData();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [primaryColor, buttonColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isToday ? primaryColor.withOpacity(0.3) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: isToday ? 1.5 : 1.0,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: isDark ? Colors.transparent : Colors.black.withOpacity(0.01),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[d.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : mutedText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.day.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Karyawan List Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStaffs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded, color: mutedText.withOpacity(0.4), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Staff not found",
                                style: TextStyle(color: mutedText, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredStaffs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final staff = filteredStaffs[index];
                            final status = _absensiMap[staff['id']] ?? 'hadir';
                            final isAktif = status != 'off';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.transparent : Colors.black.withOpacity(0.015),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Rounded Avatar with Status Badge
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          image: staff['avatar'] != null && staff['avatar'].toString().isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(staff['avatar']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: staff['avatar'] == null || staff['avatar'].toString().isEmpty
                                            ? Icon(
                                                Icons.person_rounded,
                                                color: mutedText.withOpacity(0.6),
                                                size: 26,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: -3,
                                        bottom: -3,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: isAktif ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: cardBg, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Name and Category Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff['name'] ?? '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: darkText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            // Dynamic Styled Role Tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: _getRoleBgColor(staff['role']),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (staff['role'] ?? 'Stylist').toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: _getRoleTextColor(staff['role']),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Custom Status Indicator
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: isAktif 
                                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)) 
                                                    : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isAktif ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                    color: isAktif 
                                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) 
                                                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                                    size: 10,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    isAktif ? "Present" : "Off",
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: isAktif 
                                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) 
                                                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
 
                                  // Sleek IN/OUT Switcher Button
                                  Container(
                                    height: 36,
                                    width: 108,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedAlign(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          alignment: isAktif ? Alignment.centerLeft : Alignment.centerRight,
                                          child: Container(
                                            width: 50,
                                            height: 30,
                                            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isAktif
                                                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isAktif ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                                      .withOpacity(0.25),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => _updateStatus(staff['id'], 'Present'),
                                                child: Center(
                                                  child: Text(
                                                    "IN",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      color: isAktif ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => _updateStatus(staff['id'], 'Off'),
                                                child: Center(
                                                  child: Text(
                                                    "OUT",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      color: !isAktif ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
