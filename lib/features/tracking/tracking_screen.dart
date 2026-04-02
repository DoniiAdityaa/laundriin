import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class TrackingScreen extends StatefulWidget {
  final String? initialOrderId;
  final String? initialShopId;

  const TrackingScreen({
    super.key,
    this.initialOrderId,
    this.initialShopId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _orderIdController = TextEditingController();

  // ID Toko di-hardcode karena hanya ada 1 toko untuk versi website ini
  final String _defaultShopId = 'b0sOSyHl8tM3bAomP7Z5Kz4vRkX2';

  String? _orderId;
  String? _shopId;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null && widget.initialShopId != null) {
      _orderId = widget.initialOrderId;
      _shopId = widget.initialShopId;
      _isSearching = true;
    }
  }

  void _handleSearch() {
    if (_orderIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan Nomor Order')),
      );
      return;
    }
    setState(() {
      _orderId = _orderIdController.text.trim();
      // Tetapkan shopId ke default saat melakukan pencarian manual
      _shopId = _defaultShopId;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: RefreshIndicator(
        onRefresh: () async {
          // Delay singkat agar spinner terlihat,
          // sementara Firestore akan memberikan data baru secara real-time.
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() {});
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Logo & Title
                        Image.asset(
                          'assets/images/logoApps.png',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        Text('Laundriin Track', style: xlBold),
                        Text(
                          'Lacak status cucian Anda secara real-time',
                          style: sRegular.copyWith(color: textMuted),
                        ),
                        const SizedBox(height: 40),

                        if (!_isSearching)
                          _buildSearchForm()
                        else
                          _buildTrackingDetails(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                labelText: 'Nomor Order',
                hintText: 'Contoh: ORD-2024-001',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/svg/notes.svg',
                    width: 20,
                    height: 20,
                    colorFilter:
                        const ColorFilter.mode(textMuted, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue500,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSearch,
                child: Text('Lihat Status',
                    style: mBold.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingDetails() {
    // Menggunakan fallback ID Admin/Toko utama jika tidak ada di parameter URL
    final currentShopId = _shopId ?? _defaultShopId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(currentShopId)
          .collection('orders')
          .doc(_orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState('Terjadi kesalahan saat memuat data');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorState(
              'Pesanan tidak ditemukan. Periksa kembali ID Order dan Kode Toko.');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';

        return Column(
          children: [
            _buildStatusCard(status, data),
            const SizedBox(height: 16),
            _buildOrderInfoCard(data),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _orderIdController.clear();
                  _orderId = null;
                  _shopId = null;
                });
              },
              child: const Text('Cari Pesanan Lain'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String status, Map<String, dynamic> data) {
    int activeStep = 0;
    if (status == 'process') activeStep = 1;
    if (status == 'completed') activeStep = 2;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Status Saat Ini', style: sRegular.copyWith(color: textMuted)),
            const SizedBox(height: 8),
            _getStatusBadge(status),
            const SizedBox(height: 32),
            _buildStepper(activeStep),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(int activeStep) {
    return Row(
      children: [
        _stepItem('Pending', activeStep >= 0),
        _stepLine(activeStep >= 1),
        _stepItem('Proses', activeStep >= 1),
        _stepLine(activeStep >= 2),
        _stepItem('Selesai', activeStep >= 2),
      ],
    );
  }

  Widget _stepItem(String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? blue500 : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: isActive
                  ? [BoxShadow(color: blue500.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: isActive
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: xsRegular.copyWith(color: isActive ? blue500 : textMuted)),
        ],
      ),
    );
  }

  Widget _stepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? blue500 : Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 22),
    );
  }

  Widget _getStatusBadge(String status) {
    String label = 'MENUNGGU';
    Color color = const Color(0xFF9A6A00);
    Color bgColor = const Color(0xFFFFF4C2);

    if (status == 'process') {
      label = 'MEMPROSES';
      color = const Color(0xFF2F5FE3);
      bgColor = const Color(0xFFE8F1FF);
    } else if (status == 'completed') {
      label = 'SELESAI';
      color = const Color(0xFF1F8F5F);
      bgColor = const Color(0xFFE8F8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: smSemiBold.copyWith(color: color)),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] as Timestamp?;
    String dateStr = createdAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(createdAt.toDate())
        : '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _rowInfo('Nomor Order', data['orderId'] ?? '-'),
            const Divider(),
            _rowInfo('Nama Pelanggan', data['customerName'] ?? 'Pelanggan'),
            const Divider(),
            _rowInfo('Tanggal Masuk', dateStr),
            const Divider(),
            _rowInfo('Total Harga',
                'Rp ${NumberFormat.decimalPattern().format(data['totalPrice'] ?? 0)}',
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: sRegular.copyWith(color: textMuted)),
          Text(value, style: isBold ? sBold : sMedium),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      children: [
        const Icon(Icons.search_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: sRegular.copyWith(color: textMuted)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _isSearching = false),
          child: const Text('Kembali Cari'),
        ),
      ],
    );
  }
}
