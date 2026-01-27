import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/dimension.dart';
import 'package:laundriin/ui/typography.dart';

class CustomFormField extends StatelessWidget {
  const CustomFormField({
    super.key,
    this.titleSection,
    required this.child,
    this.helperText,
    this.helper,
    this.subtitleSection,
  });

  final String? titleSection;
  final String? subtitleSection;

  final Widget? helper;
  final String? helperText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (titleSection != '')
              Text(
                titleSection ?? '',
                style: const TextStyle(
                  color: black900,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (subtitleSection != '')
              Padding(
                padding: const EdgeInsets.only(left: space250),
                child: Text(
                  subtitleSection ?? '',
                  style: xsRegular.copyWith(color: textNeutralSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: space150),
        child,
        helper != null || helperText != null
            ? const SizedBox(height: 6)
            : const SizedBox(),
        _generateHelper(),
      ],
    );
  }

  Widget _generateHelper() {
    const textStyle = TextStyle(
      color: Colors.grey,
      fontSize: 12,
      height: 1.6,
    );

    if (helper != null) {
      return DefaultTextStyle.merge(
        style: textStyle,
        child: helper!,
      );
    } else {
      return Text(helperText ?? "", style: textStyle);
    }
  }
}
