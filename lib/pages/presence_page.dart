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
      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

      // Fetch all staffs
      final usersData = await Supabase.instance.client
          .from('users')
          .select('id, name, role, avatar, status')
          .eq('type', 'karyawan')
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
      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

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
            .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('absensi')
            .insert({
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
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text(
                          "Staff Attendance",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: mutedText, size: 22),
                    hintText: "Search stylist or staff name...",
                    hintStyle: TextStyle(color: mutedText, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Date Selector
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDateIndex;
                  final d = _dates[index];
                  const dayNames = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                  
                  return GestureDetector(
                    onTap: () {
                      if (_selectedDateIndex != index) {
                        setState(() => _selectedDateIndex = index);
                        _fetchData();
                      }
                    },
                    child: Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
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
                              fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStaffs.isEmpty
                      ? Center(child: Text("No staff found.", style: TextStyle(color: mutedText)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: filteredStaffs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final staff = filteredStaffs[index];
                            final status = _absensiMap[staff['id']] ?? 'hadir'; // Default hadir if no record
                            final isAktif = status != 'off';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF1F5F9),
                                      image: staff['avatar'] != null && staff['avatar'].toString().isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(staff['avatar']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: staff['avatar'] == null || staff['avatar'].toString().isEmpty
                                        ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 32)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff['name'] ?? '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          staff['role'] ?? 'Stylist',
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Action Buttons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _updateStatus(staff['id'], 'hadir'),
                                        child: Container(
                                          width: 100,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isAktif ? primaryColor : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isAktif ? primaryColor : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 14,
                                                color: isAktif ? Colors.white : primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Presence",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAktif ? Colors.white : primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _updateStatus(staff['id'], 'off'),
                                        child: Container(
                                          width: 100,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: !isAktif ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: !isAktif ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.cancel_outlined,
                                                size: 14,
                                                color: !isAktif ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Off Work",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: !isAktif ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
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
