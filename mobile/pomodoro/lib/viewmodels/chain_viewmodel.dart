import 'package:flutter/foundation.dart';
import 'package:pomodoro/services/main_api.dart';

/// ViewModel to manage chain (streak) state and logic.
class ChainViewModel extends ChangeNotifier {
  int chainStreak = 0;
  int maxChainStreak = 0;
  List<dynamic> history = [];
  String lastUpdateDate = '';
  bool broken = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isMarking = false;
  bool get isMarking => _isMarking;

  ChainViewModel() {
    fetchChainStatus();
  }

  Future<void> fetchChainStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await mainAPI.getChainStatus();
      chainStreak = result['chain_streak'] ?? 0;
      maxChainStreak = result['max_chain_streak'] ?? 0;
      history = result['history'] ?? [];
      lastUpdateDate = result['last_update_date'] ?? '';
      broken = result['broken'] ?? false;
    } catch (_) {
      chainStreak = 0;
      maxChainStreak = 0;
      history = [];
      lastUpdateDate = '';
      broken = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markTodayCompleted() async {
    _isMarking = true;
    notifyListeners();

    await mainAPI.updateChainStatus('completed');
    await fetchChainStatus();

    _isMarking = false;
    notifyListeners();
  }

  bool isTodayCompleted() {
    try {
      final lastDate = DateTime.parse(lastUpdateDate);
      final now = DateTime.now();
      return lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  List<DateTime?> generateMonthCalendar(DateTime today) {
    final firstDay = DateTime(today.year, today.month, 1);
    final lastDay = DateTime(today.year, today.month + 1, 0);
    final total = lastDay.day;
    final startOffset = firstDay.weekday % 7;

    List<DateTime?> days = [];
    for (int i = 0; i < startOffset; i++) days.add(null);
    for (int d = 1; d <= total; d++) days.add(DateTime(today.year, today.month, d));
    while (days.length % 7 != 0) days.add(null);
    return days;
  }

  Set<String> getCompletedDaysSet(List<dynamic> history) {
    return history
        .map<String>((h) => (h['date'] as String).substring(0, 10))
        .toSet();
  }
}
