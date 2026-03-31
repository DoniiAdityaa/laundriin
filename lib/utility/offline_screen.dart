import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final String? errorMessage;

  const OfflineScreen({
    super.key,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.fromLTRB(26, 40, 26, 32),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon / Illustration
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: borderLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 42,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Koneksi Terputus",
                      style: xsBold.copyWith(
                        fontSize: 24,
                        color: textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Aduh, sepertinya kamu sedang offline atau ada masalah jaringan. Pastikan koneksi internetmu stabil dan coba lagi ya.",
                      style: sRegular.copyWith(
                        color: textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // if (errorMessage != null) ...[
                    //   const SizedBox(height: 16),
                    //   Container(
                    //     padding: const EdgeInsets.all(12),
                    //     decoration: BoxDecoration(
                    //       color: errorColor.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(12),
                    //       border: Border.all(
                    //         color: errorColor.withOpacity(0.2),
                    //       ),
                    //     ),
                    //     // child: Text(
                    //     //   "Detail:\n$errorMessage",
                    //     //   style: xsRegular.copyWith(
                    //     //     color: errorColor,
                    //     //     fontSize: 12,
                    //     //   ),
                    //     //   textAlign: TextAlign.center,
                    //     //   maxLines: 2,
                    //     //   overflow: TextOverflow.ellipsis,
                    //     // ),
                    //   ),
                    // ],

                    const SizedBox(height: 25),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: borderFocus.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue500,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onRetry,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, color: white),
                              const SizedBox(width: 10),
                              Text(
                                "Coba Lagi",
                                style: xsBold.copyWith(
                                  color: white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
