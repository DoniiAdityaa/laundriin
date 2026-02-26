import 'dart:convert';

import 'package:dio/dio.dart';

class JsonStringConverter {
  const JsonStringConverter();

  Response<T> convertResponse<T>(Response response) {
    final decoded = json.decode(response.data as String);
    return response.copyWith(data: decoded as T) as Response<T>;
  }

  T fromJson<T>(dynamic json) {
    return json as T;
  }

  dynamic toJson<T>(T object) {
    return object;
  }
}

extension<T> on Response<T> {
  Response<T> copyWith({required T data}) {
    return Response<T>(
      data: data,
      headers: headers,
      requestOptions: requestOptions,
      statusCode: statusCode,
      statusMessage: statusMessage,
      extra: extra,
      redirects: redirects,
      isRedirect: isRedirect,
    );
  }
}
