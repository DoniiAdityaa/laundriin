import 'package:dio/dio.dart';

sealed class DataState<T> {
  final T? data;
  final DioException? exception;

  const DataState({this.data, this.exception});
}

class DataStateSuccess<T> extends DataState<T> {
  const DataStateSuccess(T data) : super(data: data);
}

class DataStateError<T> extends DataState<T> {
  const DataStateError(DioException message) : super(exception: message);
}

