import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
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
                  Text('John Doe', style: mBold),
                  const SizedBox(height: 4),
                  Text(
                    '0812 3456 7890',
                    style: sRegular.copyWith(color: textMuted),
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
                      color: const Color(0xFFFFF4C2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'WAITING',
                      style: smSemiBold.copyWith(
                        color: const Color(0xFF9A6A00),
                      ),
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
                    value: 'Campuran',
                  ),
                  _infoRow(
                    icon: 'assets/images/zap-2.png',
                    title: 'Speed',
                    value: 'Express',
                  ),
                  _infoRow(
                    icon: 'assets/images/package.png',
                    title: 'Items',
                    value: '3 pcs',
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
                    'Rp 37.500',
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
                    'Created: 9 Feb 2026 • 18:11',
                    style: sRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== ACTION BUTTONS =====
            Column(
              children: [
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
                    onPressed: () {},
                    child: const Text(
                      'Start Process',
                      style: smSemiBold,
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
                    onPressed: () {},
                    child: Text(
                      'Cancel Order',
                      style: smSemiBold.copyWith(color: Colors.red),
                    ),
                  ),
                ),
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
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: bgApp,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: sRegular.copyWith(color: textMuted),
            ),
          ),
          Text(
            value,
            style: smSemiBold,
          ),
        ],
      ),
    );
  }
}
