import 'package:dio/dio.dart';

import 'package:retrofit/retrofit.dart';
import '../../config/constant.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseApi)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
}
