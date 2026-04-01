import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

Future<void> showOfflineDialog(BuildContext context,
    {required String featureName}) {
  return showDialog(
    context: context,
    barrierDismissible: true, // klik luar untuk menutup
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: borderLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.wifi_off_rounded,
                    color: textMuted, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Koneksi Terputus',
              style: xsBold.copyWith(
                fontSize: 22,
                color: textPrimary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Saat ini Anda sedang offline.\nFitur $featureName tidak dapat digunakan tanpa koneksi internet.',
              style: sRegular.copyWith(
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Mengerti',
                  style: xsBold.copyWith(
                    color: white,
                    fontSize: 16,
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
