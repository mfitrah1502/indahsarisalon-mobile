import 'package:flutter/material.dart';
import '../models/promo_model.dart';
import '../controllers/home_controller.dart';
import 'package:intl/intl.dart';
import '../utils/translations.dart';

class PromoListPage extends StatefulWidget {
  const PromoListPage({super.key});

  @override
  State<PromoListPage> createState() => _PromoListPageState();
}

class _PromoListPageState extends State<PromoListPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  bool _loading = true;
  List<PromoModel> _promos = [];
  final HomeController _homeController = HomeController();

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    try {
      final promos = await _homeController.fetchPromos();
      if (mounted) {
        setState(() {
          _promos = promos;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showPromoDetail(PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: promo.imageUrl != null && promo.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(promo.imageUrl!), fit: BoxFit.cover)
                  : null,
                color: primaryColor,
              ),
              child: promo.imageUrl == null || promo.imageUrl!.isEmpty
                ? const Icon(Icons.local_offer, color: Colors.white, size: 80)
                : null,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          promo.title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text("Promo".tr, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Get this service only for:".tr, style: TextStyle(color: mutedText, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(formatCurrency(promo.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                  if (promo.description != null && promo.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Included Treatments:".tr, style: TextStyle(color: mutedText, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(promo.description!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: mutedText),
                      const SizedBox(width: 8),
                      Text(
                        "${"Valid until: ".tr}${DateFormat('dd MMM yyyy').format(promo.endAt)}",
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "All Promos".tr,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _promos.isEmpty
                      ? Center(child: Text("No active promos".tr, style: TextStyle(color: mutedText)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: _promos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final p = _promos[index];
                            return GestureDetector(
                              onTap: () => _showPromoDetail(p),
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(p.imageUrl!), fit: BoxFit.cover)
                                    : null,
                                  gradient: p.imageUrl == null || p.imageUrl!.isEmpty
                                    ? LinearGradient(colors: [primaryColor, buttonColor])
                                    : null,
                                ),
                                child: Stack(
                                  children: [
                                    if (p.imageUrl == null || p.imageUrl!.isEmpty)
                                      const Center(child: Icon(Icons.local_offer, color: Colors.white, size: 48)),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.title,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              formatCurrency(p.price),
                                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
