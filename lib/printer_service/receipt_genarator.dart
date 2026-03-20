import 'package:intl/intl.dart';
import 'package:laundriin/utility/receipt_screen.dart';

/// Generate format nota thermal dari data order (ESC/POS commands)
class ReceiptGenerator {
  /// Generate ESC/POS bytes dari data receipt
  /// Support 58mm (32 char) dan 80mm (48 char)
  static Future<List<int>> generate({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String orderId,
    required String customerName,
    required String kasirName,
    required DateTime orderDate,
    DateTime? estimasi,
    required String category,
    required String serviceType,
    required String speed,
    int weight = 0,
    required List<ReceiptItem> items,
    required int totalPrice,
    int? discount,
    String? notes,
    int? pricePerKilo,
    int? expressCharge,
    int paperSize = 58,
  }) async {
    // Lebar karakter based on paper size
    final int charWidth = paperSize == 80 ? 48 : 32;
    final String divider = '=' * charWidth;
    final String dividerDash = '-' * charWidth;

    List<int> bytes = [];

    // ===== INITIALIZE PRINTER =====
    bytes += _initPrinter();

    // ===== HEADER TOKO =====
    bytes += _textCenter(shopName, bold: true, size: 1);
    bytes += _textCenter(shopAddress);
    bytes += _textCenter('HP: $shopPhone');
    bytes += _text(divider);

    // ===== INFO ORDER =====
    bytes += _textLeftRight('No:', orderId, charWidth);
    bytes += _textLeftRight('Pelanggan:', customerName, charWidth);
    bytes += _textLeftRight('Kasir:', kasirName, charWidth);
    bytes += _textLeftRight(
      'Tgl Pesan:',
      DateFormat('dd MMM yyyy  HH:mm', 'id_ID').format(orderDate),
      charWidth,
    );
    if (estimasi != null) {
      bytes += _textLeftRight(
        'Est Selesai:',
        DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(estimasi),
        charWidth,
      );
    }
    bytes += _text(dividerDash);

    // ===== SERVICE INFO =====
    final serviceDisplay = _getServiceDisplay(serviceType);
    final categoryDisplay = _getCategoryDisplay(category);
    bytes += _text('$serviceDisplay ($categoryDisplay)');
    bytes += _text('Kecepatan: ${speed == 'express' ? 'Express' : 'Regular'}');
    bytes += _text(dividerDash);

    // ===== ITEMS DETAIL =====
    if (category == 'kiloan') {
      // Kiloan: tampilkan berat x harga per kilo
      final priceKg = pricePerKilo ?? 0;
      final subtotalKiloan = weight * priceKg;
      bytes += _textLeftRight(
        '$weight kg x Rp ${_formatNumber(priceKg)}',
        'Rp ${_formatNumber(subtotalKiloan)}',
        charWidth,
      );

      // Express charge kalau ada
      if (speed == 'express' && expressCharge != null && expressCharge > 0) {
        bytes += _textLeftRight(
          'Express charge',
          'Rp ${_formatNumber(expressCharge)}',
          charWidth,
        );
      }
    } else {
      // Satuan / Campuran: list items
      for (final item in items) {
        bytes += _text(item.name);
        bytes += _textLeftRight(
          '  ${item.quantity} x Rp ${_formatNumber(item.unitPrice)}',
          'Rp ${_formatNumber(item.totalPrice)}',
          charWidth,
        );
      }

      // Express charge kalau ada
      if (speed == 'express' && expressCharge != null && expressCharge > 0) {
        bytes += _textLeftRight(
          'Express charge',
          'Rp ${_formatNumber(expressCharge)}',
          charWidth,
        );
      }
    }

    bytes += _text(dividerDash);

    // ===== PRICING SUMMARY =====
    // Subtotal (sebelum diskon)
    final subtotal = totalPrice + (discount ?? 0);
    if (discount != null && discount > 0) {
      bytes += _textLeftRight(
        'Subtotal',
        'Rp ${_formatNumber(subtotal)}',
        charWidth,
      );
      bytes += _textLeftRight(
        'Diskon',
        '-Rp ${_formatNumber(discount)}',
        charWidth,
      );
    }

    // TOTAL (bold & besar)
    bytes += _text(divider);
    bytes += _textLeftRight(
      'TOTAL',
      'Rp ${_formatNumber(totalPrice)}',
      charWidth,
      bold: true,
    );
    bytes += _text(divider);

    // ===== NOTES =====
    if (notes != null && notes.isNotEmpty) {
      bytes += _newLine();
      bytes += _text('Catatan: $notes');
    }

    // ===== THANK YOU =====
    bytes += _newLine();
    bytes += _textCenter('Terima Kasih!');
    bytes += _text(divider);

    // ===== FEED & CUT =====
    bytes += _feedAndCut();

    print('[RECEIPT] ✅ Generated ${bytes.length} bytes (${paperSize}mm)');
    return bytes;
  }

  // ===== ESC/POS COMMAND HELPERS =====

  /// Initialize printer (reset)
  static List<int> _initPrinter() {
    return [0x1B, 0x40]; // ESC @
  }

  /// Center align text
  static List<int> _textCenter(String text, {bool bold = false, int size = 0}) {
    List<int> bytes = [];
    bytes += [0x1B, 0x61, 0x01]; // ESC a 1 = center

    if (bold) {
      bytes += [0x1B, 0x45, 0x01]; // ESC E 1 = bold on
    }

    if (size > 0) {
      // Double height + double width
      bytes += [0x1D, 0x21, 0x11]; // GS ! 0x11
    }

    bytes += text.codeUnits;
    bytes += [0x0A]; // Line feed

    // Reset
    if (size > 0) {
      bytes += [0x1D, 0x21, 0x00]; // Reset size
    }
    if (bold) {
      bytes += [0x1B, 0x45, 0x00]; // Bold off
    }
    bytes += [0x1B, 0x61, 0x00]; // Left align

    return bytes;
  }

  /// Left-aligned text
  static List<int> _text(String text, {bool bold = false}) {
    List<int> bytes = [];
    bytes += [0x1B, 0x61, 0x00]; // Left align

    if (bold) {
      bytes += [0x1B, 0x45, 0x01];
    }

    bytes += text.codeUnits;
    bytes += [0x0A];

    if (bold) {
      bytes += [0x1B, 0x45, 0x00];
    }

    return bytes;
  }

  /// Left-right aligned text (2 kolom)
  static List<int> _textLeftRight(
    String left,
    String right,
    int width, {
    bool bold = false,
  }) {
    // Hitung spasi di tengah
    final totalLen = left.length + right.length;
    final spaces = width - totalLen;

    String line;
    if (spaces > 0) {
      line = left + (' ' * spaces) + right;
    } else {
      // Kalau terlalu panjang, potong left
      final maxLeft = width - right.length - 1;
      if (maxLeft > 0 && left.length > maxLeft) {
        line = '${left.substring(0, maxLeft)} $right';
      } else {
        line = '$left $right';
      }
    }

    return _text(line, bold: bold);
  }

  /// New line
  static List<int> _newLine() {
    return [0x0A];
  }

  /// Feed paper and cut (kalau printer support auto-cut)
  static List<int> _feedAndCut() {
    List<int> bytes = [];
    // Feed 4 lines
    bytes += [0x1B, 0x64, 0x04]; // ESC d 4
    // Partial cut (kalau printer punya cutter)
    bytes += [0x1D, 0x56, 0x01]; // GS V 1
    return bytes;
  }

  // ===== DISPLAY HELPERS =====

  static String _getServiceDisplay(String serviceType) {
    switch (serviceType) {
      case 'washComplete':
        return 'Cuci Komplit';
      case 'ironing':
        return 'Setrika';
      case 'dryWash':
        return 'Cuci Kering';
      case 'steamIroning':
        return 'Setrika Uap';
      default:
        return serviceType;
    }
  }

  static String _getCategoryDisplay(String category) {
    switch (category) {
      case 'kiloan':
        return 'Kiloan';
      case 'satuan':
        return 'Satuan';
      case 'campuran':
        return 'Campuran';
      default:
        return category;
    }
  }

  static String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
