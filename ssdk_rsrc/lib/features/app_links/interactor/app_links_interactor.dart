import '../../services/main_api.dart';

class AppLinksInteractor {
  final MainAPI _api = mainAPI;

  Future<Map<String, dynamic>> fetchBindings(String userEmail) {
    return _api.getAllAppsBinding(userEmail);
  }
}
