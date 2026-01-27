import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';

class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool disabled;
  final Gradient? gradient;
  final Color? textColor;
  final Size? maximumSize;
  final Color backgroundColor;
  final Color disabledColor;
  final Size? minimumSize;
  final Border? border;

  const CustomButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.disabled = false,
    this.gradient,
    this.textColor,
    this.maximumSize,
    this.minimumSize,
    this.backgroundColor = bgButtonPrimaryDefault,
    this.border,
    this.disabledColor = bgButtonPrimaryDisabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Material(
        color: onPressed != null ? backgroundColor : disabledColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          splashColor: bgButtonPrimaryPressed,
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed != null
              ? () {
                  /// Dismiss keyboard
                  FocusManager.instance.primaryFocus?.unfocus();
                  onPressed!();
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                  fontSize: 14,
                  color: textButtonPrimary,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
