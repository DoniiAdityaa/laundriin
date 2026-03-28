import 'package:dio/dio.dart';
import '../config/shop_config.dart';
import '../models/wablas_message.dart';

class WablasService {
  final Dio _dio;

  WablasService(this._dio);

  /// Mengirim pesan teks via backend Laravel
  Future<Response> sendText(String phone, String message) async {
    try {
      final data = WablasMessage(phone: phone, message: message).toJson();
      
      final response = await _dio.post(
        '${WablasConfig.baseUrl}${WablasConfig.sendTextEndpoint}',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      print('[WABLAS SERVICE] Success: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('[WABLAS SERVICE] Error: ${e.message}');
      rethrow;
    }
  }

  /// Cek nomor WhatsApp via backend Laravel
  Future<Response> checkNumber(String phone) async {
    try {
      final response = await _dio.get(
        '${WablasConfig.baseUrl}${WablasConfig.checkNumberEndpoint}',
        queryParameters: {'phone': phone},
      );
      return response;
    } catch (e) {
      print('[WABLAS SERVICE] Error checkNumber: $e');
      rethrow;
    }
  }
}
