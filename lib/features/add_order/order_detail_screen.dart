import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/utility/app_loading_overlay.dart';
import 'package:laundriin/utility/receipt_screen.dart';
import 'package:laundriin/config/shop_config.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _orderData;
  late String _currentStatus;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _orderData = widget.orderData;
    _currentStatus = _orderData['status'] ?? 'pending';
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);
    AppLoading.show(context, message: 'Updating status...');

    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .doc(_orderData['id'])
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
        _orderData['status'] = newStatus;
      });

      if (mounted) {
        AppLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cancel Order', style: mBold),
              const SizedBox(height: 12),
              Text('Are you sure you want to cancel this order?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'No',
                            style: smMedium.copyWith(color: Colors.black),
                          ))),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Yes',
                            style: smMedium.copyWith(color: white),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _updateOrderStatus('cancelled');
      if (mounted) Navigator.pop(context);
    }
  }

// delete order
  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Delete Order', style: mBold),
              const SizedBox(height: 12),
              Text(
                  'Are you sure you want to delete this order? This action cannot be undone.'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'No',
                            style: smMedium.copyWith(color: Colors.black),
                          ))),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Yes',
                            style: smMedium.copyWith(color: white),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      if (_isUpdating) return;

      setState(() => _isUpdating = true);
      AppLoading.show(context, message: 'Deleting order...');

      try {
        await _firestore
            .collection('shops')
            .doc(_userId)
            .collection('orders')
            .doc(_orderData['id'])
            .delete();

        if (mounted) {
          AppLoading.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppLoading.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _openReceipt() {
    final orderId = _orderData['orderId'] ?? 'N/A';
    final customerName = _orderData['customerName'] ?? 'Unknown';
    final customerPhone = _orderData['customerPhone'] ?? '';
    final totalPrice = _orderData['totalPrice'] ?? 0;
    final category = _orderData['category'] ?? '';
    final serviceType = _orderData['serviceType'] ?? '';
    final speed = _orderData['speed'] ?? '';
    final weight = _orderData['weight'] ?? 0;
    final createdAt = _orderData['createdAt'] as Timestamp?;

    List<ReceiptItem> items = [];
    if (_orderData['items'] != null && _orderData['items'] is Map) {
      (_orderData['items'] as Map).forEach((key, value) {
        items.add(
          ReceiptItem(
            name: value['name'] ?? 'Unknown',
            quantity: value['qty'] ?? 1,
            unit: 'item',
            unitPrice: value['price'] ?? 0,
            totalPrice: (value['price'] ?? 0) * (value['qty'] ?? 1),
          ),
        );
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(
          orderId: orderId,
          customerName: customerName,
          customerPhone: customerPhone,
          kasirName: ShopSettings.currentUserName,
          orderDate: createdAt?.toDate() ?? DateTime.now(),
          estimasiSelesai: DeliveryConfig.calculateEstimatedCompletion(
            createdAt?.toDate() ?? DateTime.now(),
            speed.toLowerCase() == 'express',
          ),
          category: category,
          serviceType: serviceType,
          speed: speed,
          weight: weight,
          items: items,
          totalPrice: totalPrice,
          notes: _orderData['notes'],
          pricePerKilo: 0, // Not available in old data
          expressCharge: 0, // Not available in old data
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _orderData['orderId'] ?? 'N/A';
    final customerName = _orderData['customerName'] ?? 'Unknown';
    final customerPhone = _orderData['customerPhone'] ?? '';
    final category = _orderData['category'] ?? '';
    final speed = _orderData['speed'] ?? '';
    final weight = _orderData['weight'] ?? 0;
    final items = _orderData['items'] as Map? ?? {};
    final totalPrice = _orderData['totalPrice'] ?? 0;
    final createdAt = _orderData['createdAt'] as Timestamp?;
    final notes = _orderData['notes'] ?? '';

    // Format tanggal
    String dateStr = 'N/A';
    if (createdAt != null) {
      dateStr = DateFormat('d MMM yyyy • HH:mm').format(createdAt.toDate());
    }

    // Format category & speed
    String categoryLabel = category.isNotEmpty
        ? category[0].toUpperCase() + category.substring(1)
        : '';
    String speedLabel =
        speed.isNotEmpty ? speed[0].toUpperCase() + speed.substring(1) : '';

    // Status badge
    String statusLabel = 'Waiting';
    Color statusColor = const Color(0xFF9A6A00);
    Color statusBgColor = const Color(0xFFFFF4C2);

    if (_currentStatus == 'process') {
      statusLabel = 'Processing';
      statusColor = const Color(0xFF2F5FE3);
      statusBgColor = const Color(0xFFE8F1FF);
    } else if (_currentStatus == 'completed') {
      statusLabel = 'Done';
      statusColor = const Color(0xFF1F8F5F);
      statusBgColor = const Color(0xFFE8F8F0);
    } else if (_currentStatus == 'cancelled') {
      statusLabel = 'Cancelled';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    }

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _openReceipt,
            icon: SvgPicture.asset(
              'assets/svg/receipt-2.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        ],
        title: Text(
          'Order Detail',
          style: mBold,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== CUSTOMER CARD =====
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: blue500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/bust_in_silhouette.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerName, style: mBold),
                          const SizedBox(height: 5),
                          Text(
                            customerPhone,
                            style: sRegular.copyWith(color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order ID: $orderId',
                    style: xsRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== STATUS =====
            _sectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: sRegular.copyWith(color: textMuted)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: smSemiBold.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== ORDER INFO =====
            _sectionCard(
              child: Column(
                children: [
                  _infoRow(
                    icon: 'assets/images/basket.png',
                    title: 'Category',
                    value: categoryLabel,
                  ),
                  _infoRow(
                    icon: 'assets/images/zap-2.png',
                    title: 'Speed',
                    value: speedLabel,
                  ),
                  if (weight > 0)
                    _infoRow(
                      icon: 'assets/images/package.png',
                      title: 'Weight',
                      value: '$weight kg',
                    ),
                  if (items.isNotEmpty)
                    _infoRow(
                      icon: 'assets/images/package.png',
                      title: 'Items',
                      value: '${items.length} pcs',
                    ),
                  if (notes.isNotEmpty)
                    _infoRow(
                      icon: 'assets/images/zap-2.png',
                      title: 'Notes',
                      value: notes,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== PRICE =====
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Price',
                      style: sRegular.copyWith(color: textMuted)),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatNumber(totalPrice)}',
                    style: lBold.copyWith(color: Colors.blue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== CREATED TIME =====
            _sectionCard(
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Created: $dateStr',
                    style: sRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== ACTION BUTTONS =====
            Column(
              children: [
                if (_currentStatus == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating
                          ? null
                          : () => _updateOrderStatus('process'),
                      child: Text(
                        'Start Process',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating ? null : _cancelOrder,
                      child: Text(
                        'Cancel Order',
                        style: smSemiBold.copyWith(color: Colors.red),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'process') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating
                          ? null
                          : () => _updateOrderStatus('completed'),
                      child: Text(
                        'Mark as Done',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'completed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Open WhatsApp or similar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('WhatsApp integration coming soon'),
                          ),
                        );
                      },
                      child: Text(
                        'Message on WhatsApp',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'cancelled') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating ? null : _deleteOrder,
                      child: Text(
                        'Delete Order',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== REUSABLE SECTION CARD =====
  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow({
    required String icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            child: Image.asset(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: sRegular.copyWith(color: textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: smSemiBold,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
