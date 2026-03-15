import 'package:flutter/material.dart';

class SnackbarHelper {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    key.currentState?.hideCurrentSnackBar();
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError(String message) {
    key.currentState?.hideCurrentSnackBar();
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showWarning(String message) {
    key.currentState?.hideCurrentSnackBar();
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
