import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import 'package:intl/intl.dart';
import '../utils/translations.dart';
import 'customer_booking_history_page.dart';
import '../utils/popup_helper.dart';

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
  bool _isSelectionActive = false;
  final Set<String> _selectedKeys = {};
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _loading = true);
    try {
      final list = await _userController.fetchCustomersWithSpend();

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
    String key = customer['key'];
    bool isSelected = _selectedKeys.contains(key);

    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          Navigator.pop(context, customer);
        } else if (_isSelectionActive) {
          setState(() {
            if (isSelected) {
              _selectedKeys.remove(key);
            } else {
              _selectedKeys.add(key);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerBookingHistoryPage(customer: customer),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: _isSelectionActive && isSelected 
              ? Border.all(color: primaryColor, width: 2) 
              : Border.all(color: Colors.transparent, width: 2),
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
            if (_isSelectionActive) ...[
              Checkbox(
                value: isSelected,
                activeColor: primaryColor,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedKeys.add(key);
                    } else {
                      _selectedKeys.remove(key);
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
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
                          
                          bool isCc = customer['is_colour_circle'] == true || spend >= 1500000;
                          if (isCc) {
                            DateTime? exp = customer['colour_circle_expired_at'] != null ? DateTime.tryParse(customer['colour_circle_expired_at']) : null;
                            if (exp != null && exp.isBefore(DateTime.now())) {
                              if (spend < 1500000) {
                                isCc = false;
                              }
                            }
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tier != 'Reguler') ...[
                                Container(
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
                                ),
                              ],
                              if (isCc) ...[
                                if (tier != 'Reguler') const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD660A1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFD660A1).withOpacity(0.5)),
                                  ),
                                  child: const Text(
                                    'Colour Circle',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Color(0xFFD660A1),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
            if (!_isSelectionActive) const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelectedCustomers() async {
    if (_selectedKeys.isEmpty) return;

    final confirm = await PopupHelper.showConfirm(
      context,
      title: "Delete Customer?".tr,
      message: "${"Are you sure you want to delete ".tr}${_selectedKeys.length}${" selected customers? All related booking data will also be deleted.".tr}",
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> customersToDelete = [];
      for (var key in _selectedKeys) {
        customersToDelete.add(_customers.firstWhere((c) => c['key'] == key));
      }
      
      await _userController.deleteCustomers(customersToDelete);
      
      if (mounted) {
        PopupHelper.showSuccess(context, "Customer data cleared successfully".tr);
        setState(() {
          _isSelectionActive = false;
          _selectedKeys.clear();
        });
        _fetchCustomers();
      }
    } catch (e) {
      debugPrint("Error deleting customers: $e");
      if (mounted) {
        PopupHelper.showError(context, "Failed to delete some customer data.".tr);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                   GestureDetector(
                    onTap: () {
                      if (_isSelectionActive) {
                        setState(() {
                          _isSelectionActive = false;
                          _selectedKeys.clear();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(_isSelectionActive ? Icons.close : Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isSelectionActive 
                        ? "${_selectedKeys.length}${" Selected".tr}" 
                        : (widget.isSelectionMode ? "Select Customer".tr : "Customer List".tr),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!widget.isSelectionMode && _customers.isNotEmpty) 
                    _isSelectionActive 
                      ? IconButton(
                          onPressed: _selectedKeys.isEmpty ? null : _deleteSelectedCustomers,
                          icon: Icon(Icons.delete_outline, color: _selectedKeys.isEmpty ? Colors.grey : Colors.red, size: 28),
                        )
                      : TextButton(
                          onPressed: () => setState(() => _isSelectionActive = true),
                          child: Text("Select".tr, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Color(0xFF64748B)),
                          hintText: 'Search name or phone number...'.tr,
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
                            "No customer data yet".tr,
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
