import 'package:flutter/material.dart';

extension DialogExtension on BuildContext {
  void showErrorDialog({required String message}) {
    showDialog(
      context: this,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
