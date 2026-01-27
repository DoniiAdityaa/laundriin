import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24.0,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), // 4px border radius
          border: Border.all(
            color: widget.value
                ? iconPrimary // Border color when checked
                : borderFillNeutral, // Border color when unchecked
            width: 1,
          ),
          color: widget.value
              ? iconPrimary // #B18D41 background when checked
              : Colors.white, // #0F0F0F background when unchecked
        ),
        child: widget.value
            ? Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
