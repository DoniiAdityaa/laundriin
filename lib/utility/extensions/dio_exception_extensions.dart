import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

extension DioExceptionExtension on DioException {
  String? parseMessage() {
    if (type == DioExceptionType.badResponse) {
      try {
        final errorResponse = response?.data as Map<String, dynamic>;
        return errorResponse["message"] ?? errorResponse["error"];
      } catch (e2) {
        if (response?.statusCode == 401) {
          return "Session expired, please login again";
        }
        return "Error ${response?.statusCode ?? 0}";
      }
    } else if (type == DioExceptionType.connectionTimeout || type == DioExceptionType.connectionError) {
      return "An error occurred. Please check your internet connection.";
    } else {
      if (kDebugMode) {
        print(toString());
        log(toString());
      }
      return kDebugMode ? toString() : "An error occurred. Please try again later.";
    }
  }
}
