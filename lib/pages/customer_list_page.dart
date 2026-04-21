import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CustomerListPage extends StatefulWidget {
  final bool isSelectionMode;
  
  const CustomerListPage({super.key, this.isSelectionMode = false});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _loading = true;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch all users with role 'pelanggan'
      final usersData = await supabase
          .from('users')
          .select('id, name, email, phone')
          .eq('role', 'pelanggan');

      // 2. Fetch all bookings for spend calculation
      final bookingsData = await supabase
          .from('bookings')
          .select('customer_name, customer_phone, customer_email, total_price, status, user_id');
          
      // Grouping logic
      final Map<String, Map<String, dynamic>> map = {};
      
      // Initialize with registered users
      for (final user in usersData) {
        final name = (user['name'] ?? 'Customer').toString().trim();
        final phone = (user['phone'] ?? '').toString().trim();
        final email = (user['email'] ?? '').toString().trim();
        
        // Use phone as main key, fallback to email if phone missing
        final key = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : "id_${user['id']}");
        
        map[key] = {
          'id': user['id'],
          'name': name,
          'phone': phone,
          'email': email,
          'spend': 0,
        };
      }

      // Merge with booking data
      for (final row in bookingsData) {
        final name = (row['customer_name'] ?? 'Customer').toString().trim();
        final phone = (row['customer_phone'] ?? '').toString().trim();
        final email = (row['customer_email'] ?? '').toString().trim();
        final userId = row['user_id'];
        
        String? key;
        if (phone.isNotEmpty) {
          key = phone;
        } else if (email.isNotEmpty) {
          key = email;
        }

        // If no key found by phone/email, check if we can match by user_id
        if (key == null && userId != null) {
          // Find key in map where 'id' matches userId
          try {
            key = map.entries.firstWhere((e) => e.value['id'] == userId).key;
          } catch (_) {
            key = "id_$userId";
          }
        }

        if (key == null) continue;

        if (!map.containsKey(key)) {
          // Guest customer found in bookings but not in users table
          map[key] = {
            'name': name,
            'phone': phone,
            'email': email,
            'spend': 0,
          };
        }
        
        if (row['status'] != 'dibatalkan') {
          map[key]!['spend'] += (row['total_price'] as num?)?.toInt() ?? 0;
        }
      }


      final list = map.values.toList();
      // Sort by spend descending
      list.sort((a, b) => (b['spend'] as int).compareTo(a['spend'] as int));

      if (mounted) {
        setState(() {
          _customers = list;
          _loading = false;
        });
        _filter();
      }
    } catch (e) {
      debugPrint("Error fetching customers: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  String _selectedTier = 'Semua';

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final matchSearch = c['name'].toString().toLowerCase().contains(q) ||
               c['phone'].toString().toLowerCase().contains(q);
               
        final spend = c['spend'] as int;
        bool matchTier = true;
        
        if (_selectedTier == 'Platinum') {
          matchTier = spend >= 3000000;
        } else if (_selectedTier == 'Gold') {
          matchTier = spend >= 2000000 && spend < 3000000;
        } else if (_selectedTier == 'Silver') {
          matchTier = spend >= 1000000 && spend < 2000000;
        }
        
        return matchSearch && matchTier;
      }).toList();
    });
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          Navigator.pop(context, customer);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar with green dot
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFF1F5F9),
                    image: DecorationImage(
                      image: NetworkImage("https://ui-avatars.com/api/?name=${Uri.encodeComponent(customer['name'])}&background=E4F0FA&color=D660A1&bold=true"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Emerald green
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Name and phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final spend = customer['spend'] as int;
                          String tier = 'Reguler';
                          Color tc = mutedText;
                          if (spend >= 3000000) { tier = 'Platinum'; tc = const Color(0xFF334155); } // dark slate
                          else if (spend >= 2000000) { tier = 'Gold'; tc = const Color(0xFFEAB308); } // gold
                          else if (spend >= 1000000) { tier = 'Silver'; tc = const Color(0xFF94A3B8); } // silver
                          
                          if (tier == 'Reguler') return const SizedBox.shrink();

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tc.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: tc.withOpacity(0.5)),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: tc,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer['phone'].toString().isEmpty ? '-' : customer['phone'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Lifetime spend
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "LIFETIME SPEND",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currency.format(customer['spend']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
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
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text(
                          widget.isSelectionMode ? "Pilih Pelanggan" : "Daftar Pelanggan",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => _filter(),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.search, color: Color(0xFF64748B)),
                          hintText: 'Cari nama atau nomor HP...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown Menu Button
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                           const Icon(Icons.tune, color: Color(0xFF64748B), size: 24),
                           if (_selectedTier != 'Semua')
                             Positioned(
                               right: -2,
                               top: -2,
                               child: Container(
                                 width: 10, height: 10,
                                 decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                               )
                             )
                        ],
                      ),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (String tier) {
                        setState(() {
                          _selectedTier = tier;
                          _filter();
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return ['Semua', 'Platinum', 'Gold', 'Silver'].map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(choice, style: TextStyle(
                                  fontWeight: _selectedTier == choice ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedTier == choice ? primaryColor : Colors.black87,
                                )),
                                if (_selectedTier == choice)
                                  Icon(Icons.check, color: primaryColor, size: 18),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            "Belum ada data pelanggan",
                            style: TextStyle(color: mutedText, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            return _buildCustomerCard(_filteredCustomers[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
