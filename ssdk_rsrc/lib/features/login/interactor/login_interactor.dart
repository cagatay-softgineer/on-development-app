import '../../services/main_api.dart';

class LoginInteractor {
  final MainAPI _api = mainAPI;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.login(email, password);
  }
}
