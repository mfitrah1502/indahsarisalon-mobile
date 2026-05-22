import 'dart:typed_data';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_model.dart';

class PdfReportHelper {
  static Future<Uint8List> generatePdf({
    required ReportSummary summary,
    required DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#D660A1');
    final redColor = PdfColor.fromHex('#F44336');
    final greenColor = PdfColor.fromHex('#4CAF50');
    final blueColor = PdfColor.fromHex('#2196F3');
    final mutedColor = PdfColor.fromHex('#64748B');

    String formatCurrency(num amount) {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
    }

    final now = DateTime.now();
    final printedDate = DateFormat('dd MMM yyyy HH:mm').format(now);
    final reportId = "#REP-${DateFormat('yyyyMMdd').format(now)}-${now.millisecondsSinceEpoch.toString().substring(8)}";
    
    String coverage = "Seluruh Transaksi (Hingga Saat Ini)";
    if (dateRange != null) {
      coverage = "${DateFormat('dd MMM yyyy').format(dateRange.start)} - ${DateFormat('dd MMM yyyy').format(dateRange.end)}";
    }

    // Combine and sort transactions for the detail table
    List<_Transaction> transactions = [];
    for (var inc in summary.incomeDetails) {
      transactions.add(_Transaction(
        date: inc.date,
        description: inc.services.isNotEmpty ? inc.services : inc.category,
        type: 'Pemasukan',
        amount: inc.price,
      ));
    }
    for (var exp in summary.expenseDetails) {
      transactions.add(_Transaction(
        date: exp.date,
        description: exp.name.isNotEmpty ? exp.name : exp.category,
        type: 'Pengeluaran',
        amount: exp.amount,
      ));
    }
    transactions.sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              height: 70,
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    "Indah Sarisalon",
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "RINGKASAN PROFIT & KEUANGAN KESELURUHAN",
                    style: pw.TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 32),

            // Metadata Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF0F5'), // light pink
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildMetaRow("ID Laporan:", reportId),
                  pw.SizedBox(height: 4),
                  _buildMetaRow("Tanggal Cetak:", printedDate),
                  pw.SizedBox(height: 4),
                  _buildMetaRow("Cakupan Data:", coverage),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Transaction Details Title
            pw.Text(
              "Rincian Transaksi Harian",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // Transaction Table Custom
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
                  children: [
                    _buildTableCell("TANGGAL", isHeader: true),
                    _buildTableCell("KATEGORI / DESKRIPSI", isHeader: true),
                    _buildTableCell("TIPE", isHeader: true),
                    _buildTableCell("JUMLAH (IDR)", isHeader: true, isRight: true),
                  ],
                ),
                // Data rows
                ...transactions.map((t) {
                  final isIncome = t.type == 'Pemasukan';
                  final amountStr = isIncome ? formatCurrency(t.amount) : "-${formatCurrency(t.amount)}";
                  final amountColor = isIncome ? greenColor : redColor;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
                    ),
                    children: [
                      _buildTableCell(DateFormat('dd/MM/yyyy').format(t.date)),
                      _buildTableCell(t.description),
                      _buildTableCell(t.type),
                      _buildTableCell(amountStr, isRight: true, color: amountColor, isBold: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 32),

            // Summary Title
            pw.Text(
              "Ringkasan Keseluruhan",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // Summary Table
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(6.5),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
                  children: [
                    _buildTableCell("DESKRIPSI LAPORAN", isHeader: true),
                    _buildTableCell("NILAI NOMINAL (IDR)", isHeader: true, isRight: true),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
                  ),
                  children: [
                    _buildTableCell("Total Seluruh Pemasukan"),
                    _buildTableCell(formatCurrency(summary.totalIncome), isRight: true, color: greenColor, isBold: true),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
                  ),
                  children: [
                    _buildTableCell("Total Seluruh Pengeluaran"),
                    _buildTableCell(formatCurrency(summary.totalExpense), isRight: true, color: redColor, isBold: true),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
                  ),
                  children: [
                    _buildTableCell("Profit Bersih (Net Income)", isBold: true),
                    _buildTableCell(formatCurrency(summary.totalProfit), isRight: true, color: blueColor, isBold: true),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "© ${DateTime.now().year} Indah Sarisalon Management System. Hak Cipta Dilindungi Undang-Undang",
                  style: pw.TextStyle(color: mutedColor, fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  "Cetak oleh Admin pada $printedDate",
                  style: pw.TextStyle(color: mutedColor, fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isRight = false, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Text(
        text,
        textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColor.fromHex('#334155') : PdfColor.fromHex('#000000')),
        ),
      ),
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}

class _Transaction {
  final DateTime date;
  final String description;
  final String type;
  final int amount;

  _Transaction({
    required this.date,
    required this.description,
    required this.type,
    required this.amount,
  });
}
