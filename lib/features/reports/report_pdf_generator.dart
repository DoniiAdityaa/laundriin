import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReportPdfGenerator {
  static final _blue = PdfColor.fromHex('#2563EB');
  static final _blueLight = PdfColor.fromHex('#EFF6FF');
  static final _green = PdfColor.fromHex('#16A34A');
  static final _red = PdfColor.fromHex('#DC2626');
  static final _gray = PdfColor.fromHex('#6B7280');
  static final _grayLight = PdfColor.fromHex('#F9FAFB');
  static final _border = PdfColor.fromHex('#E5E7EB');

  /// Generate PDF report and save to Download folder
  /// Returns the saved File path, or null if failed
  static Future<File?> generateAndSave({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String selectedPeriod, // day, week, month
    required DateTime selectedDate,
    required int totalIncome,
    required int totalExpense,
    required int totalOrders,
    required int averageOrderPrice,
    required int previousPeriodIncome,
    required List<Map<String, dynamic>> expenseItems,
    required List<Map<String, dynamic>> topCustomers,
  }) async {
    // Load font that supports Unicode/Indonesian
    final fontData = await rootBundle.load('assets/fonts/DIN14_Regular.otf');
    final fontBoldData = await rootBundle.load('assets/fonts/DIN14_Bold.otf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    // Period label
    final periodLabel = _getPeriodLabel(selectedPeriod, selectedDate);
    final netProfit = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          periodLabel: periodLabel,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ===== RINGKASAN KEUANGAN =====
          _buildSectionTitle('Ringkasan Keuangan'),
          pw.SizedBox(height: 8),
          _buildFinancialSummary(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netProfit: netProfit,
            totalOrders: totalOrders,
            averageOrderPrice: averageOrderPrice,
            previousPeriodIncome: previousPeriodIncome,
            selectedPeriod: selectedPeriod,
          ),
          pw.SizedBox(height: 24),

          // ===== DETAIL PENGELUARAN =====
          if (expenseItems.isNotEmpty) ...[
            _buildSectionTitle('Detail Pengeluaran'),
            pw.SizedBox(height: 8),
            _buildExpenseTable(expenseItems),
            pw.SizedBox(height: 24),
          ],

          // ===== TOP PELANGGAN (hanya minggu/bulan) =====
          if (selectedPeriod != 'day' && topCustomers.isNotEmpty) ...[
            _buildSectionTitle('Top Pelanggan'),
            pw.SizedBox(height: 8),
            _buildTopCustomersTable(topCustomers),
          ],
        ],
      ),
    );

    // Save to app documents directory (no permission needed)
    try {
      final fileName = _getFileName(shopName, selectedPeriod, selectedDate);
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final file = File('${reportsDir.path}/$fileName');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      print('[PDF] Error saving: $e');
      rethrow; // Let caller handle the error with details
    }
  }

  // ===== HEADER =====
  static pw.Widget _buildHeader({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String periodLabel,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Shop info
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  shopAddress,
                  style: pw.TextStyle(fontSize: 10, color: _gray),
                ),
                pw.Text(
                  'Tel: $shopPhone',
                  style: pw.TextStyle(fontSize: 10, color: _gray),
                ),
              ],
            ),
            // Right: Period
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _blueLight,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                periodLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _blue,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 2,
          color: _blue,
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'LAPORAN KEUANGAN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _blue,
              letterSpacing: 2,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  // ===== SECTION TITLE =====
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 24,
          color: _blue,
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: _blueLight,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== FINANCIAL SUMMARY =====
  static pw.Widget _buildFinancialSummary({
    required int totalIncome,
    required int totalExpense,
    required int netProfit,
    required int totalOrders,
    required int averageOrderPrice,
    required int previousPeriodIncome,
    required String selectedPeriod,
  }) {
    final isProfit = netProfit >= 0;

    // Calculate percentage change
    String changeText = '';
    if (previousPeriodIncome > 0) {
      final change =
          ((totalIncome - previousPeriodIncome) / previousPeriodIncome * 100)
              .toStringAsFixed(1);
      final isUp = totalIncome >= previousPeriodIncome;
      final periodName = selectedPeriod == 'day'
          ? 'kemarin'
          : selectedPeriod == 'week'
              ? 'minggu lalu'
              : 'bulan lalu';
      changeText = '${isUp ? "+" : ""}$change% dari $periodName';
    }

    return pw.Column(
      children: [
        // Three boxes
        pw.Row(
          children: [
            _buildSummaryBox(
              'Total Pemasukan',
              _formatCurrency(totalIncome),
              _green,
            ),
            pw.SizedBox(width: 8),
            _buildSummaryBox(
              'Total Pengeluaran',
              _formatCurrency(totalExpense),
              _red,
            ),
            pw.SizedBox(width: 8),
            _buildSummaryBox(
              'Laba Bersih',
              _formatCurrency(netProfit),
              isProfit ? _blue : _red,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // Detail row
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _grayLight,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Jumlah Order: $totalOrders  |  Rata-rata: ${_formatCurrency(averageOrderPrice)}',
                style: pw.TextStyle(fontSize: 9, color: _gray),
              ),
              if (changeText.isNotEmpty)
                pw.Text(
                  changeText,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: totalIncome >= previousPeriodIncome ? _green : _red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Expanded _buildSummaryBox(
      String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, color: _gray),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EXPENSE TABLE =====
  static pw.Widget _buildExpenseTable(List<Map<String, dynamic>> expenseItems) {
    final totalExpense =
        expenseItems.fold<int>(0, (sum, e) => sum + (e['amount'] as int));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(70),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FixedColumnWidth(90),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _blue),
          children: [
            _tableHeaderCell('No'),
            _tableHeaderCell('Tanggal'),
            _tableHeaderCell('Nama'),
            _tableHeaderCell('Kategori'),
            _tableHeaderCell('Jumlah', align: pw.TextAlign.right),
          ],
        ),
        // Data rows
        ...expenseItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final date = item['createdAt'] as DateTime;
          final isEven = i % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : _grayLight,
            ),
            children: [
              _tableDataCell('${i + 1}'),
              _tableDataCell(DateFormat('dd MMM').format(date)),
              _tableDataCell(item['name'] ?? ''),
              _tableDataCell(item['category'] ?? ''),
              _tableDataCell(
                _formatCurrency(item['amount'] as int),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _blueLight),
          children: [
            _tableDataCell('', bold: true),
            _tableDataCell('', bold: true),
            _tableDataCell('', bold: true),
            _tableDataCell('TOTAL', bold: true),
            _tableDataCell(
              _formatCurrency(totalExpense),
              align: pw.TextAlign.right,
              bold: true,
              color: _red,
            ),
          ],
        ),
      ],
    );
  }

  // ===== TOP CUSTOMERS TABLE =====
  static pw.Widget _buildTopCustomersTable(
      List<Map<String, dynamic>> topCustomers) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(100),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _blue),
          children: [
            _tableHeaderCell('No'),
            _tableHeaderCell('Nama Pelanggan'),
            _tableHeaderCell('Jumlah Order'),
            _tableHeaderCell('Total Belanja', align: pw.TextAlign.right),
          ],
        ),
        // Data
        ...topCustomers.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isEven = i % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : _grayLight,
            ),
            children: [
              _tableDataCell('${i + 1}'),
              _tableDataCell(c['name'] ?? ''),
              _tableDataCell('${c['orders']} order'),
              _tableDataCell(
                _formatCurrency(c['amount'] as int),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ===== FOOTER =====
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: _gray),
            ),
            pw.Text(
              'Halaman ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _gray),
            ),
          ],
        ),
      ],
    );
  }

  // ===== TABLE HELPERS =====
  static pw.Widget _tableHeaderCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey800,
        ),
      ),
    );
  }

  // ===== HELPERS =====
  static String _formatCurrency(int value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  static String _getPeriodLabel(String period, DateTime date) {
    switch (period) {
      case 'day':
        return 'Hari: ${DateFormat('dd MMMM yyyy', 'id_ID').format(date)}';
      case 'week':
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Minggu: ${DateFormat('dd MMM', 'id_ID').format(weekStart)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(weekEnd)}';
      case 'month':
      default:
        return 'Bulan: ${DateFormat('MMMM yyyy', 'id_ID').format(date)}';
    }
  }

  static String _getFileName(String shopName, String period, DateTime date) {
    final cleanName = shopName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    switch (period) {
      case 'day':
        return 'Laporan_${cleanName}_${DateFormat('dd-MMM-yyyy').format(date)}.pdf';
      case 'week':
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Laporan_${cleanName}_${DateFormat('dd').format(weekStart)}-${DateFormat('dd-MMM-yyyy').format(weekEnd)}.pdf';
      case 'month':
      default:
        return 'Laporan_${cleanName}_${DateFormat('MMM-yyyy').format(date)}.pdf';
    }
  }
}
