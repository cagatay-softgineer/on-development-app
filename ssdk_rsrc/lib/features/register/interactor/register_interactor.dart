import '../../services/main_api.dart';

class RegisterInteractor {
  final MainAPI _api = mainAPI;

  Future<Map<String, dynamic>> register(String email, String password) {
    return _api.register(email, password);
  }
}
