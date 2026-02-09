import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

/// Success Order Dialog
class SuccessOrderDialog extends StatelessWidget {
  final String orderId;
  final VoidCallback onViewReceipt;
  final VoidCallback onBackHome;

  const SuccessOrderDialog({
    super.key,
    required this.orderId,
    required this.onViewReceipt,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blur background
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Prevent dismiss on tap
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
          // Dialog content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success icon with animation
                ScaleTransition(
                  scale: AlwaysStoppedAnimation(1.0),
                  child: Center(
                    child: Image.asset(
                      'assets/images/check-2.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Pesanan Berhasil Dibuat',
                  style: mBold.copyWith(
                    color: textPrimary,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 16),

                // Order ID section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Order ID',
                      style: sRegular.copyWith(
                        color: textMuted,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: SelectableText(
                        orderId,
                        style: mBold.copyWith(
                          color: blue500,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // View Receipt Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onViewReceipt,
                        label: Text(
                          'Lihat Struk',
                          style: smBold.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back Home Button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onBackHome,
                        label: Text(
                          'Kembali ke Home',
                          style: smBold.copyWith(color: textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderLight, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function untuk menampilkan success dialog
void showSuccessOrderDialog(
  BuildContext context, {
  required String orderId,
  required VoidCallback onViewReceipt,
  required VoidCallback onBackHome,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: SuccessOrderDialog(
        orderId: orderId,
        onViewReceipt: onViewReceipt,
        onBackHome: onBackHome,
      ),
    ),
  );
}
