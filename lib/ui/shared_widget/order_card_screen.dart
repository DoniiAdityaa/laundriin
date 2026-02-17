import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../color.dart';
import '../typography.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = order['customerName'] ?? 'Tidak Diketahui';
    final totalPrice = order['totalPrice'] ?? 0;
    final status = order['status'] ?? 'pending';
    final createdAt = order['createdAt'] as Timestamp?;
    final category = order['category'] ?? '';
    final speed = order['speed'] ?? '';

    // Format tanggal
    String dateStr = 'N/A';
    if (createdAt != null) {
      dateStr = DateFormat('d MMM, HH:mm').format(createdAt.toDate());
    }

    // Status
    String statusLabel = 'Menunggu';
    Color statusColor = const Color(0xFF9A6A00);
    Color statusBgColor = const Color(0xFFFFF4C2);

    if (status == 'process') {
      statusLabel = 'Memproses';
      statusColor = const Color(0xFF2F5FE3);
      statusBgColor = const Color(0xFFE8F1FF);
    } else if (status == 'completed') {
      statusLabel = 'Selesai';
      statusColor = const Color(0xFF1F8F5F);
      statusBgColor = const Color(0xFFE8F8F0);
    } else if (status == 'cancelled') {
      statusLabel = 'Dibatalkan';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    }

    // Label
    String categoryLabel = category.isNotEmpty
        ? category[0].toUpperCase() + category.substring(1)
        : '-';
    String speedLabel =
        speed.isNotEmpty ? speed[0].toUpperCase() + speed.substring(1) : '-';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: smBold.copyWith(color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: xsRegular.copyWith(color: textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: xsRegular.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryLabel,
                    style: xsRegular.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: speed.toLowerCase() == 'express'
                        ? Colors.red[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    speedLabel,
                    style: xsRegular.copyWith(
                      color: speed.toLowerCase() == 'express'
                          ? Colors.red[700]
                          : Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Harga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: sRegular.copyWith(color: textMuted)),
                Text(
                  'Rp ${_formatNumber(totalPrice)}',
                  style: smBold.copyWith(color: Colors.blue[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }
}
