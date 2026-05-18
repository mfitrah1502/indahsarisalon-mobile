import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresencePage extends StatefulWidget {
  const PresencePage({super.key});

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  List<Map<String, dynamic>> _staffs = [];
  Map<int, String> _absensiMap =
      {}; // Maps user_id to status ('hadir' or 'off') for the selected date
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

      // Update local optimistically
      if (mounted) {
        setState(() {
          _absensiMap[userId] = newStatus;
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
              'status': newStatus,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('absensi').insert({
          'user_id': userId,
          'tanggal': dateStr,
          'status': newStatus,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Error updating absensi: $e");
    }
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
            // Premium Elegant Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Presensi Karyawan",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          "Kelola kehadiran & jadwal masuk hari ini",
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

            // Premium Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                    hintText: "Cari nama stylist...",
                    hintStyle: TextStyle(color: mutedText.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Date Selector (Horizontal Glow Cards)
            SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDateIndex;
                  final d = _dates[index];
                  const dayNames = [
                    'Sen',
                    'Sel',
                    'Rab',
                    'Kam',
                    'Jum',
                    'Sab',
                    'Min',
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
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [primaryColor, buttonColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 5,
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.day.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Staff Presence List (Premium Cards)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStaffs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded, color: mutedText.withOpacity(0.5), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Karyawan tidak ditemukan",
                                style: TextStyle(color: mutedText, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredStaffs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final staff = filteredStaffs[index];
                            final status = _absensiMap[staff['id']] ?? 'hadir';
                            final isAktif = status != 'off';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(color: const Color(0xFFF8FAFC)),
                              ),
                              child: Row(
                                children: [
                                  // Sleek Avatar with Active Dot
                                  Stack(
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: const Color(0xFFF1F5F9),
                                          image: staff['avatar'] != null && staff['avatar'].toString().isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(staff['avatar']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: staff['avatar'] == null || staff['avatar'].toString().isEmpty
                                            ? const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFF94A3B8),
                                                size: 32,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: isAktif ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),

                                  // Employee Info Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff['name'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // Role tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (staff['role'] ?? 'Stylist').toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF64748B),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Status tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isAktif ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isAktif ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isAktif ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                    color: isAktif ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                                    size: 11,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isAktif ? "Hadir" : "Libur",
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      color: isAktif ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

                                  // Custom Premium Segmented Slide Switcher
                                  Container(
                                    height: 38,
                                    width: 112,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Sliding selection indicator
                                        AnimatedAlign(
                                          duration: const Duration(milliseconds: 240),
                                          curve: Curves.easeOutBack,
                                          alignment: isAktif ? Alignment.centerLeft : Alignment.centerRight,
                                          child: Container(
                                            width: 52,
                                            height: 32,
                                            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isAktif
                                                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(17),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isAktif ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Interactive switch segments
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => _updateStatus(staff['id'], 'hadir'),
                                                child: Center(
                                                  child: Text(
                                                    "IN",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                      color: isAktif ? Colors.white : const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => _updateStatus(staff['id'], 'off'),
                                                child: Center(
                                                  child: Text(
                                                    "OUT",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                      color: !isAktif ? Colors.white : const Color(0xFF94A3B8),
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
