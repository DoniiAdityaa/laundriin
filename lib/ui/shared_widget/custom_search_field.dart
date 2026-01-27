import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:laundriin/ui/shared_widget/custom_text_form_field.dart';

class CustomSearchField extends StatelessWidget {
  const CustomSearchField({
    super.key,
    required this.searchController,
    this.focusNode,
    this.onSubmit,
    this.textInputAction,
    this.readOnly,
    this.onChanged,
    this.placeHolder = 'Cari brand atau produk',
  });
  final TextEditingController searchController;
  final FocusNode? focusNode;
  final Function(String)? onSubmit;
  final TextInputAction? textInputAction;
  final bool? readOnly;
  final Function(String)? onChanged;
  final String? placeHolder;
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      onSubmit: onSubmit,
      readOnly: readOnly,
      controller: searchController,
      placeholder: 'Cari brand atau produk',
      textInputAction: textInputAction,
      focusNode: focusNode,
      onChanged: onChanged,
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) {
          return IconButton(
            onPressed: () {
              searchController.clear();
            },
            icon: value.text.isEmpty
                ? SvgPicture.asset(
                    'assets/images/ic_search.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.scaleDown,
                  )
                : const Icon(Icons.close),
          );
        },
      ),
    );
  }
}
