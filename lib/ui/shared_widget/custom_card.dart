import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = BorderRadius.zero,
    this.borderSide = BorderSide.none,
    this.shadow,
    this.onTap,
    this.color = black50,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final BorderSide borderSide;
  final List<BoxShadow>? shadow;
  final Function()? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                offset: const Offset(1, 1),
                blurRadius: 10,
              ),
            ],
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          side: borderSide,
          borderRadius: borderRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
