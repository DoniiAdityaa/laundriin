import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

/// Widget Loading Overlay dengan Blur Background
/// Gunakan di seluruh app untuk menampilkan loading state
class AppLoadingOverlay extends StatefulWidget {
  final String? message;
  final bool dismissible;

  const AppLoadingOverlay({
    super.key,
    this.message = 'Memproses...',
    this.dismissible = false,
  });

  @override
  State<AppLoadingOverlay> createState() => _AppLoadingOverlayState();
}

class _AppLoadingOverlayState extends State<AppLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.dismissible,
      child: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: GestureDetector(
              onTap:
                  widget.dismissible ? () => Navigator.of(context).pop() : null,
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
          // Loading spinner + text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotating spinner
                RotationTransition(
                  turns: _animationController,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: blue500.withOpacity(0.3),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: LinearProgressIndicator(
                          value: null,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            blue500.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Loading message
                if (widget.message != null && widget.message!.isNotEmpty)
                  Text(
                    widget.message!,
                    style: sRegular.copyWith(
                      color: white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class untuk manage loading dialog
class AppLoading {
  /// Tampilkan loading overlay
  ///
  /// Usage:
  /// ```dart
  /// AppLoading.show(context);
  /// // Lakukan proses
  /// AppLoading.hide(context);
  /// ```
  static void show(
    BuildContext context, {
    String message = 'Memproses...',
    bool dismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => AppLoadingOverlay(
        message: message,
        dismissible: dismissible,
      ),
    );
  }

  /// Sembunyikan loading overlay
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
}
