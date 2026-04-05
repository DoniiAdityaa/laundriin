import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/features/orders/cubit/wablas_cubit.dart';
import 'package:laundriin/features/orders/cubit/wablas_state.dart';
import 'package:laundriin/utility/snackbar_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/ui/shared_widget/main_navigation.dart';
import 'package:laundriin/printer_service/printer_manager.dart';
import 'package:laundriin/printer_service/receipt_genarator.dart';
import 'package:laundriin/utility/app_loading_overlay.dart';

class ReceiptScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String kasirName;
  final DateTime orderDate;
  final DateTime? estimasiSelesai;
  final String category; // kiloan, satuan, campuran
  final String serviceType; // washComplete, ironing, dryWash, steamIroning
  final String speed; // regular, express
  final int weight; // for kiloan
  final List<ReceiptItem> items; // for satuan/campuran
  final int totalPrice;
  final int? discount;
  final String? notes;
  final int? pricePerKilo;
  final int? expressCharge;
  final String source; // 'home' or 'orders' (default: 'orders')

  const ReceiptScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.kasirName,
    required this.orderDate,
    this.estimasiSelesai,
    required this.category,
    required this.serviceType,
    required this.speed,
    this.weight = 0,
    this.items = const [],
    required this.totalPrice,
    this.discount,
    this.notes,
    this.pricePerKilo,
    this.expressCharge,
    this.source = 'orders',
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class ReceiptItem {
  final String name;
  final int quantity;
  final String unit;
  final int unitPrice;
  final int totalPrice;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isPrinting = false;
  bool _isSharing = false;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _floatingButton(
              icon: 'assets/svg/print_.svg',
              onTap: _isPrinting ? () {} : () => _handlePrint(),
            ),
            const SizedBox(height: 12),
            _floatingButton(
              icon: 'assets/svg/send_.svg',
              onTap: _isSharing ? () {} : () => _handleShare(),
            ),
            const SizedBox(height: 12),
            _floatingButton(
              icon: 'assets/svg/whatsapp_.svg',
              onTap: _isSharing ? () {} : () => _handleWhatsAppDirect(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Receipt Container
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _buildReceiptContainer(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // // Bottom Action Buttons
            // _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            // Jika dari Add Order (home), langsung ke home
            if (widget.source == 'home') {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(),
                ),
                (route) => false,
              );
            } else {
              // Jika dari Orders Detail, pop biasa (balik ke detail)
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Struk Pemesanan', style: mBold),
              const SizedBox(height: 4),
              Text(
                'Order ID: ${widget.orderId}',
                style: xsRegular.copyWith(color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Receipt Container (Printable Area) =====
  Widget _buildReceiptContainer() {
    return BlocListener<WablasCubit, WablasState>(
      listener: (context, state) {
        if (state is WablasLoading) {
          AppLoading.show(context);
        } else if (state is WablasSuccess) {
          AppLoading.hide(context);
          SnackbarHelper.showSuccess(state.message);
        } else if (state is WablasFailure) {
          AppLoading.hide(context);
          SnackbarHelper.showError(state.error);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===== STORE HEADER =====
            _buildStoreHeader(),
            const SizedBox(height: 4),
            _buildDottedDivider(),
            const SizedBox(height: 16),

            // ===== ORDER INFO =====
            _buildOrderInfo(),
            const SizedBox(height: 4),
            _buildDottedDivider(),
            const SizedBox(height: 16),

            // ===== ITEMS DETAIL =====
            _buildItemsDetail(),
            const SizedBox(height: 4),
            _buildDottedDivider(),
            const SizedBox(height: 16),

            // ===== PRICING SUMMARY =====
            _buildPricingSummary(),
            const SizedBox(height: 16),
            _buildDottedDivider(),
            const SizedBox(height: 16),

            // ===== THANK YOU =====
            _buildThankYouSection(),
          ],
        ),
      ),
    );
  }

  // ===== Store Header =====
  Widget _buildStoreHeader() {
    return Column(
      children: [
        Text(
          ShopSettings.shopName,
          style: mBold.copyWith(fontSize: 18, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          ShopSettings.shopAddress,
          style: sRegular.copyWith(color: textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Tel: ${ShopSettings.shopPhone}',
          style: xsRegular.copyWith(color: textMuted),
        ),
      ],
    );
  }

  // ===== Order Info (2 Columns) =====
  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoRow('Order ID', widget.orderId),
        const SizedBox(height: 10),
        _buildInfoRow('Pelanggan', widget.customerName),
        const SizedBox(height: 10),
        _buildInfoRow('Kasir', widget.kasirName),
        const SizedBox(height: 10),
        _buildInfoRow(
          'Tgl Pesanan',
          DateFormat('yyyy-MM-dd HH:mm').format(widget.orderDate),
        ),
        if (widget.estimasiSelesai != null) ...[
          const SizedBox(height: 10),
          _buildInfoRow(
            'Est. Selesai',
            DateFormat('yyyy-MM-dd HH:mm').format(widget.estimasiSelesai!),
          ),
        ],
      ],
    );
  }

  // ===== Info Row Helper =====
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: sRegular.copyWith(color: textMuted),
        ),
        Text(
          value,
          style: sBold.copyWith(color: textPrimary),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  // ===== Items Detail =====
  Widget _buildItemsDetail() {
    final serviceDisplay = _getServiceDisplay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Service summary (tanpa estimasi di struk)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceDisplay,
                    style: sRegular.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSpeedDisplay(),
                    style: xsRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatNumber(widget.totalPrice),
              style: sBold.copyWith(color: blue500),
            ),
          ],
        ),

        // Weight or Items breakdown
        if (widget.category == 'kiloan' && widget.weight > 0) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.weight} Kg X ${_formatNumber(widget.pricePerKilo ?? 0)}',
                style: xsRegular.copyWith(color: textMuted),
              ),
              Text(
                _formatNumber(widget.weight * (widget.pricePerKilo ?? 0)),
                style: xsRegular.copyWith(color: textPrimary),
              ),
            ],
          ),
        ] else if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...widget.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: sRegular.copyWith(color: textPrimary),
                        ),
                        Text(
                          '${item.quantity} ${item.unit} X ${_formatNumber(item.unitPrice)}',
                          style: xsRegular.copyWith(color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatNumber(item.totalPrice),
                    style: xsRegular.copyWith(color: textPrimary),
                  ),
                ],
              ),
            );
          }),
        ],

        // Express Charge
        if (widget.speed.toLowerCase() == 'express' &&
            (widget.expressCharge ?? 0) > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Express',
                style: sRegular.copyWith(color: textMuted),
              ),
              Text(
                _formatNumber(widget.expressCharge ?? 0),
                style: xsRegular.copyWith(color: textPrimary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ===== Pricing Summary =====
  Widget _buildPricingSummary() {
    final subtotal = widget.totalPrice + (widget.discount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sub Total',
              style: sRegular.copyWith(color: textMuted),
            ),
            Text(
              _formatNumber(subtotal),
              style: sRegular.copyWith(color: textPrimary),
            ),
          ],
        ),
        if (widget.discount != null && widget.discount! > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diskon',
                style: sRegular.copyWith(color: textMuted),
              ),
              Text(
                '-${_formatNumber(widget.discount!)}',
                style: sRegular.copyWith(color: Colors.red),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Total Harga',
                  style: mBold.copyWith(color: blue500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _formatNumber(widget.totalPrice),
                  style: mBold.copyWith(
                    color: blue500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Thank You Section =====
  Widget _buildThankYouSection() {
    return Column(
      children: [
        Text(
          'Terima Kasih.',
          style: mBold.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (widget.notes != null && widget.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Catatan: ${widget.notes}',
            style: xsRegular.copyWith(
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ===== Dotted Divider =====
  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: Colors.grey[300],
            child: index % 3 == 0 ? null : const SizedBox(),
          ),
        ),
      ),
    );
  }

  // ===== Bottom Action Buttons =====
  Widget _buildActionButtons() {
    return Positioned(
      right: 11,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _floatingButton(
            icon: 'assets/svg/print_.svg',
            onTap: _isPrinting ? () {} : () => _handlePrint(),
          ),
          const SizedBox(height: 12),
          _floatingButton(
            icon: 'assets/svg/send_.svg',
            onTap: _isSharing ? () {} : () => _handleShare(),
          ),
          const SizedBox(height: 12),
          _floatingButton(
            icon: 'assets/svg/whatsapp_.svg',
            onTap: _isSharing ? () {} : () => _handleWhatsAppDirect(),
          ),
        ],
      ),
    );
  }

  // ===== CAPTURE RECEIPT AS IMAGE =====
  Future<File?> _captureReceipt() async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/struk_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat gambar struk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // ===== SHARE RECEIPT =====
  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final file = await _captureReceipt();
      if (file == null) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Struk Pemesanan - ${widget.orderId}',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ===== SHARE TO WHATSAPP (TEXT ONLY, DIRECT TO CONTACT) =====
  Future<void> _handleWhatsAppDirect() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final file = await _captureReceipt();
      if (file == null) {
        if (mounted) setState(() => _isSharing = false);
        return;
      }
      // 2. Compose message text
      final message =
          'Halo ${widget.customerName}, berikut struk pesanan Anda:\n\n'
          '🧾 *STRUK PEMESANAN*\n'
          '━━━━━━━━━━━━━━━\n'
          '📋 Order ID: ${widget.orderId}\n'
          '👤 Pelanggan: ${widget.customerName}\n'
          '📅 Tanggal: ${_formatDate(widget.orderDate)}\n'
          '🧺 Layanan: ${_getServiceDisplay()}\n'
          '⚡ Kecepatan: ${_getSpeedDisplay()}\n'
          '━━━━━━━━━━━━━━━\n'
          '💰 *Total: Rp ${_formatNumber(widget.totalPrice)}*\n'
          '━━━━━━━━━━━━━━━\n\n'
          'Terima kasih! 🙏';

      await Share.shareXFiles([XFile(file.path)], text: message);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // ===== HANDLE PRINT =====
  Future<void> _handlePrint() async {
    final printer = PrinterManager.instance;

    // Tampilkan loading saat proses pencarian & koneksi ke Bluetooth
    AppLoading.show(context, message: 'mencari printer...');

    try {
      // Cek Bluetooth aktif
      final btEnabled = await printer.isBluetoothEnabled();
      if (!btEnabled) {
        if (mounted) {
          AppLoading.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bluetooth tidak aktif. Nyalakan Bluetooth terlebih dahulu.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Cek koneksi printer
      final connected = await printer.checkConnection();

      if (!connected) {
        // Coba reconnect ke printer terakhir
        final reconnected = await printer.reconnectLastPrinter();
        if (!reconnected) {
          // Belum ada printer — tampilkan bottom sheet pilih printer
          if (mounted) {
            AppLoading.hide(context);
            _showPrinterSelectionSheet();
          }
          return;
        }
      }

      // Printer sudah connected — tampilkan dialog konfirmasi
      if (mounted) {
        AppLoading.hide(context);
        _showPrintConfirmDialog();
      }
    } catch (e) {
      if (mounted) {
        AppLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== PRINT RECEIPT =====
  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      // Generate ESC/POS bytes
      final bytes = await ReceiptGenerator.generate(
        shopName: ShopSettings.shopName,
        shopAddress: ShopSettings.shopAddress,
        shopPhone: ShopSettings.shopPhone,
        orderId: widget.orderId,
        customerName: widget.customerName,
        kasirName: widget.kasirName,
        orderDate: widget.orderDate,
        estimasi: widget.estimasiSelesai,
        category: widget.category,
        serviceType: widget.serviceType,
        speed: widget.speed,
        weight: widget.weight,
        items: widget.items,
        totalPrice: widget.totalPrice,
        discount: widget.discount,
        notes: widget.notes,
        pricePerKilo: widget.pricePerKilo,
        expressCharge: widget.expressCharge,
      );

      // Kirim ke printer
      final success = await PrinterManager.instance.printReceipt(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Nota berhasil dicetak!' : 'Gagal mencetak nota'),
            backgroundColor: success ? const Color(0xFF1F8F5F) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // ===== Dialog Konfirmasi Print =====
  void _showPrintConfirmDialog() {
    final printerName =
        PrinterManager.instance.currentPrinter?.name ?? 'Printer';
    final printerMac = PrinterManager.instance.currentPrinter?.macAddress ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: blue50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/svg/print_.svg',
                    color: blue500,
                    width: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Printer Terhubung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              // Printer info
              Text(
                printerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              if (printerMac.isNotEmpty)
                Text(
                  printerMac,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              const SizedBox(height: 24),

              // Tombol Cetak Nota
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _printReceipt();
                  },
                  icon: const Icon(Icons.print, size: 20),
                  label: const Text('Cetak Nota',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Ganti Printer
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Disconnect dulu, lalu buka pilih printer baru
                    PrinterManager.instance.disconnect();
                    _showPrinterSelectionSheet();
                  },
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  label: const Text('Ganti Printer',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blue500,
                    side: const BorderSide(color: blue400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== PRINTER SELECTION BOTTOM SHEET =====
  void _showPrinterSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PrinterSelectionSheet(
        onPrinterConnected: () {
          Navigator.pop(ctx);
          // Langsung print setelah connect
          _printReceipt();
        },
      ),
    );
  }

  Widget _floatingButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: blue400, // hijau seperti gambar
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: SvgPicture.asset(
              icon,
              color: Colors.white,
              width: 28,
            ),
          ),
        ),
      ),
    );
  }

  // ===== Helper Methods =====
  String _getServiceDisplay() {
    final service = widget.serviceType == 'washComplete'
        ? 'Cuci Komplit'
        : widget.serviceType == 'ironing'
            ? 'Setrika'
            : widget.serviceType == 'dryWash'
                ? 'Cuci Kering'
                : 'Setrika Uap';

    final categoryDisplay = widget.category == 'kiloan'
        ? 'Kiloan'
        : widget.category == 'satuan'
            ? 'Satuan'
            : 'Campuran';

    return '$service - $categoryDisplay';
  }

  String _getSpeedDisplay() {
    return widget.speed.toLowerCase() == 'express' ? 'Express' : 'Regular';
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}

// ===== PRINTER SELECTION BOTTOM SHEET =====
class _PrinterSelectionSheet extends StatefulWidget {
  final VoidCallback onPrinterConnected;

  const _PrinterSelectionSheet({required this.onPrinterConnected});

  @override
  State<_PrinterSelectionSheet> createState() => _PrinterSelectionSheetState();
}

class _PrinterSelectionSheetState extends State<_PrinterSelectionSheet> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingMac;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final devices = await PrinterManager.instance.scanDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error scanning: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _connectDevice(BluetoothInfo device) async {
    setState(() {
      _isConnecting = true;
      _connectingMac = device.macAdress;
    });

    try {
      final success = await PrinterManager.instance.connect(device);
      if (mounted) {
        if (success) {
          widget.onPrinterConnected();
        } else {
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal connect ke printer. Coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.print, color: blue500, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pilih Printer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: _isScanning ? null : _startScan,
                  icon: Icon(
                    Icons.refresh,
                    color: _isScanning ? Colors.grey : blue500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: _isScanning
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: blue500),
                        SizedBox(height: 16),
                        Text(
                          'Mencari perangkat Bluetooth...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _devices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_disabled,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ditemukan printer.\nPastikan printer menyala & Bluetooth aktif.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Scan Ulang'),
                              style: TextButton.styleFrom(
                                  foregroundColor: blue500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _devices.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (ctx, i) {
                          final device = _devices[i];
                          final isThis = _connectingMac == device.macAdress;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: blue50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.print,
                                  color: blue500, size: 20),
                            ),
                            title: Text(
                              device.name.isNotEmpty
                                  ? device.name
                                  : 'Unknown Device',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              device.macAdress,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                            trailing: _isConnecting && isThis
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: blue500,
                                    ),
                                  )
                                : const Icon(
                                    Icons.bluetooth,
                                    color: blue400,
                                    size: 20,
                                  ),
                            onTap: _isConnecting
                                ? null
                                : () => _connectDevice(device),
                          );
                        },
                      ),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
