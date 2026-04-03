import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../config/constant.dart';
import '../../models/weblas_model.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseApi)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Endpoint Wablas (API WhatsApp)
  @POST('/api/send-whatsapp')
  Future<void> sendWhatsApp(@Body() WablasMessage data);
}
