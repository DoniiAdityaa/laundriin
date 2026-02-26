import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/ui/shared_widget/main_navigation.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
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
                  _buildReceiptContainer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Bottom Action Buttons
            _buildActionButtons(),
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
    return Container(
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
          }).toList(),
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
        Text(
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          style: sRegular.copyWith(color: textMuted),
        ),
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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print coming soon')),
              );
            },
          ),
          const SizedBox(height: 12),
          _floatingButton(
            icon: 'assets/svg/send_.svg',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon')),
              );
            },
          ),
          const SizedBox(height: 12),
          _floatingButton(
            icon: 'assets/svg/whatsapp_.svg',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WhatsApp coming soon')),
              );
            },
          ),
        ],
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
