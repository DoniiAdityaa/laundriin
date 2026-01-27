import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RupiahFormatter extends TextInputFormatter {
  final bool showRp;
  final bool allowNegative;

  RupiahFormatter({this.allowNegative = false,this.showRp = true});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove non-numeric characters and leading zeros
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.startsWith('0')) {
      newText = newText.substring(1);
    }

    // Format the number with rupiah symbol and thousand separators
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      name: 'Rp',
      symbol: showRp ? 'Rp' : "",
      decimalDigits: 0,
    );
    String formattedText;
    if(newText.isNotEmpty){
      formattedText = formatter.format(int.parse(newText));
    } else{
      formattedText = "";
    }

    // Ensure the formatted text doesn't exceed the maximum length
    final maxLength = 15; // Adjust as needed
    if (formattedText.length > maxLength) {
      return oldValue;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formattedText.length),
      ),
    );
  }
}
