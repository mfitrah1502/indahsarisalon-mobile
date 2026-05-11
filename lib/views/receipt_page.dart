import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPage extends StatelessWidget {
  final String transactionId;
  final DateTime transactionDate;
  final List<Map<String, dynamic>> services;
  final double discountPercentage;
  final double discountAmount;
  final String paymentMethod;
  final double amountPaid;
  final double? totalOverride;

  const ReceiptPage({
    super.key,
    required this.transactionId,
    required this.transactionDate,
    required this.services,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    required this.paymentMethod,
    required this.amountPaid,
    this.totalOverride,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final Color primaryColor = const Color(0xFFD660A1);

    double subtotal = 0;
    for (var service in services) {
      subtotal += (service['price'] as num?)?.toDouble() ?? 0;
    }

    // Always show prices for a POS receipt to ensure clarity.
    bool hasIndividualPrices = true;

    // If the services list doesn't have prices but we have a total,
    // distribute the total if there's only one service.
    if (services.length == 1 &&
        (services[0]['price'] == 0 || services[0]['price'] == null) &&
        (subtotal > 0 || totalOverride != null)) {
      // Create a new list to avoid unmodifiable map issues
      final firstService = Map<String, dynamic>.from(services[0]);
      firstService['price'] = totalOverride ?? subtotal;
      services[0] = firstService;
      subtotal = firstService['price'];
    }

    // If subtotal is 0 but we have a total_price in the booking,
    // we should use the total_price passed from outside if possible.
    if (subtotal == 0 && totalOverride != null) {
      subtotal = totalOverride!;
    }

    // If we have a totalOverride that is different from subtotal,
    // and no discount was explicitly passed, treat the difference as discount
    double effectiveDiscountAmount = discountAmount;
    if (totalOverride != null &&
        totalOverride! < subtotal &&
        discountAmount == 0) {
      effectiveDiscountAmount = subtotal - totalOverride!;
    }

    final total = totalOverride ?? (subtotal - effectiveDiscountAmount);
    final change = amountPaid - total;

    Future<void> _printReceipt() async {
      final doc = pw.Document();
      final titleFont = pw.Font.helveticaBold();
      final regularFont = pw.Font.helvetica();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Indah Sari 2 Salon dan SPA',
                        style: pw.TextStyle(font: titleFont, fontSize: 16),
                      ),
                      pw.Text(
                        'Jl. Jawa No.30A, Tegal Boto Lor, Sumbersari',
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                      pw.Text(
                        'Kec. Sumbersari, Kabupaten Jember',
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'No. Struk',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      transactionId,
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Tanggal',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      DateFormat('dd MMM yyyy', 'id').format(transactionDate),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Jam',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      '${DateFormat('HH:mm', 'id').format(transactionDate)} WIB',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                ...services.map((s) {
                  final sName = s['name'] ?? '';
                  final sPrice = (s['price'] as num?)?.toDouble() ?? 0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            sName,
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (hasIndividualPrices)
                          pw.Text(
                            currencyFormat.format(sPrice),
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 0.5), // Solid line
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Subtotal',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      currencyFormat.format(subtotal),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                if (effectiveDiscountAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        discountPercentage > 0
                            ? 'Diskon (${discountPercentage.toInt()}%)'
                            : 'Diskon',
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                      pw.Text(
                        '-${currencyFormat.format(effectiveDiscountAmount)}',
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(font: titleFont, fontSize: 13),
                    ),
                    pw.Text(
                      currencyFormat.format(total),
                      style: pw.TextStyle(font: titleFont, fontSize: 13),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Bayar ($paymentMethod)',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      currencyFormat.format(amountPaid),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Kembalian',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                    pw.Text(
                      currencyFormat.format(change),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.Text(
                    'Terima Kasih Telah Menggunakan\nLayanan di Indah Sari Salon',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Struk Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Indah Sari 2 Salon dan SPA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Jl. Jawa No.30A, Tegal Boto Lor, Sumbersari, Kec. Sumbersari, Kabupaten Jember, Jawa Timur 68121',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const DashedDivider(),
                      const SizedBox(height: 16),
                      _buildInfoRow('No. Struk', transactionId),
                      _buildInfoRow(
                        'Tanggal',
                        DateFormat('dd MMM yyyy', 'id').format(transactionDate),
                      ),
                      _buildInfoRow(
                        'Jam',
                        '${DateFormat('HH:mm', 'id').format(transactionDate)} WIB',
                      ),
                      const SizedBox(height: 16),
                      const DashedDivider(),
                      const SizedBox(height: 16),
                      ...services.map(
                        (s) => _buildServiceRow(
                          s['name'] ?? '',
                          s['price'] ?? 0,
                          currencyFormat,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(thickness: 1),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Subtotal', subtotal, currencyFormat),
                      if (effectiveDiscountAmount > 0)
                        _buildSummaryRow(
                          discountPercentage > 0
                              ? 'Diskon (${discountPercentage.toInt()}%)'
                              : 'Diskon',
                          -effectiveDiscountAmount,
                          currencyFormat,
                          color: Colors.orange[800],
                        ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Total',
                        total,
                        currencyFormat,
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                      const DashedDivider(),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Bayar ($paymentMethod)',
                        amountPaid,
                        currencyFormat,
                      ),
                      _buildSummaryRow('Kembalian', change, currencyFormat),
                      const SizedBox(height: 20),
                      const DashedDivider(),
                      const SizedBox(height: 24),
                      const Text(
                        'Terima Kasih Telah Menggunakan\nLayanan di Indah Sari Salon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _printReceipt,
                          icon: const Icon(Icons.print, color: Colors.white),
                          label: const Text(
                            "Cetak Struk",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String name, num price, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            format.format(price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    NumberFormat format, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? Colors.black : Colors.black87),
            ),
          ),
          Text(
            format.format(amount),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? Colors.black : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFE0E0E0),
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
