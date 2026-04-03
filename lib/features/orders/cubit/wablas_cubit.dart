import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laundriin/data/api/api_service.dart';
import 'package:laundriin/models/weblas_model.dart';
import 'wablas_state.dart';

class WablasCubit extends Cubit<WablasState> {
  final ApiService apiService;

  // Constructor menerima apiService
  WablasCubit({required this.apiService}) : super(WablasInitial());

  Future<void> sendWhatsAppMessage(
      {required String phone, required String message}) async {
    emit(
        WablasLoading()); // Menandakan bahwa sedang loading (bisa buat nampilin muter-muter/AppLoading)

    try {
      final payload = WablasMessage(phone: phone, message: message);
      await apiService.sendWhatsApp(payload);

      emit(const WablasSuccess("Notifikasi WhatsApp berhasil dikirim!"));
    } catch (e) {
      emit(WablasFailure(e.toString()));
    }
  }
}
