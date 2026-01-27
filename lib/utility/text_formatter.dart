


import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.length >= 2 && text.length < 5) {
      return newValue.copyWith(text: '${text.substring(0, 2)}:${text.substring(2)}');
    } else if (text.length >= 5) {
      return newValue.copyWith(
          text: '${text.substring(0, 2)}:${text.substring(2, 4)}:${text.substring(4)}');
    }
    return newValue;
  }
}