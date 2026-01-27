import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/shared_widget/custom_form_field.dart';
import 'package:laundriin/ui/style.dart';

// ignore: must_be_immutable
class CustomTextFormField extends StatelessWidget {
  CustomTextFormField(
      {super.key,
      this.titleSection,
      required this.controller,
      this.keyboardType = TextInputType.text,
      this.placeholder,
      this.errorText,
      this.prefixText,
      this.focusNode,
      this.obsecureText,
      this.validator,
      this.helper,
      this.helperText,
      this.onChanged,
      this.onSubmit,
      this.suffixIcon,
      this.maxLines,
      this.minLines,
      this.defaultValue,
      this.enabled,
      this.hintColor,
      this.onTap,
      this.inputFormatters,
      this.prefix,
      this.textValidator,
      this.prefixIcon,
      this.textInputAction,
      this.readOnly,
      this.suffixIconConstraints,
      this.subtitleSection,
      this.scrollPadding});

  final String? titleSection;
  final String? subtitleSection;

  final BoxConstraints? suffixIconConstraints;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? defaultValue;
  final String? placeholder;
  final String? errorText;
  final String? prefixText;
  final Widget? helper;
  final String? helperText;
  final FocusNode? focusNode;
  final bool? obsecureText;
  final Function(String)? onChanged;
  final Function(String)? onSubmit;
  final String? Function(String)? validator;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool? enabled;
  final void Function()? onTap;
  Color? hintColor = Colors.grey.shade600;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final String? textValidator;
  final TextInputAction? textInputAction;
  final bool? readOnly;
  final EdgeInsets? scrollPadding;

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(
      color: black900,
      fontSize: 14,
    );
    if (defaultValue != null) {
      controller.text = defaultValue ?? "";
    }
    return CustomFormField(
      subtitleSection: subtitleSection ?? '',
      titleSection: titleSection ?? '',
      helper: helper,
      helperText: helperText,
      child: TextFormField(
        scrollPadding: scrollPadding ?? const EdgeInsets.all(20),
        readOnly: readOnly ?? false,
        onTap: onTap,
        textInputAction: textInputAction ?? TextInputAction.next,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obsecureText ?? false,
        style: inputStyle,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        onFieldSubmitted: onSubmit,
        inputFormatters: inputFormatters,
        decoration: inputDecoration().copyWith(
          hintStyle: const TextStyle(
              color: bgFillNeutral, fontWeight: FontWeight.w400),
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: bgFillNeutral),
          prefix: prefix,
          prefixIcon: prefixIcon,
          prefixIconConstraints:
              const BoxConstraints(minHeight: 20, minWidth: 20),
          hintText: placeholder,
          suffixIconConstraints: suffixIconConstraints,
          errorText: validator == null ? null : errorText,
          enabled: true,
        ),
        validator: (input) {
          if (validator != null) {
            return validator!(input!);
          }
          return null;
        },
        onChanged: onChanged,
        onTapOutside: (event) {
          // if (focusNode?.hasFocus ?? false) {
          //   onSubmit?.call(controller.text);
          // }
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }
}
