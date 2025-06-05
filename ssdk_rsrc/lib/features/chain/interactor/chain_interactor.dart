import '../../../services/main_api.dart';

class ChainInteractor {
  Future<Map<String, dynamic>> fetchStatus() async {
    return await mainAPI.getChainStatus();
  }

  Future<void> updateStatus(String status) async {
    await mainAPI.updateChainStatus(status);
  }
}
