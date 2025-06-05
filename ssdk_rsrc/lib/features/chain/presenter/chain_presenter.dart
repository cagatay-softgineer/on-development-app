import 'package:ssdk_rsrc/providers/userSession.dart';
import '../interactor/chain_interactor.dart';

class ChainPresenter {
  final ChainInteractor _interactor = ChainInteractor();

  int chainStreak = 0;
  int maxChainStreak = 0;
  List history = [];
  String lastUpdateDate = '';
  bool isLoading = true;
  bool isMarking = false;
  bool broken = false;

  Future<void> fetchChainStatus() async {
    isLoading = true;
    try {
      final result = await _interactor.fetchStatus();
      chainStreak = result['chain_streak'] ?? 0;
      maxChainStreak = result['max_chain_streak'] ?? 0;
      history = result['history'] ?? [];
      lastUpdateDate = result['last_update_date'] ?? '';
      broken = result['broken'] ?? false;
      UserSession.currentChainStreak = chainStreak;
    } catch (_) {
      chainStreak = 0;
      maxChainStreak = 0;
      history = [];
      lastUpdateDate = '';
      broken = false;
    }
    isLoading = false;
  }

  List<DateTime?> generateMonthCalendar(DateTime today) {
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final totalDays = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;
    List<DateTime?> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      days.add(DateTime(today.year, today.month, d));
    }
    while (days.length % 7 != 0) days.add(null);
    return days;
  }

  Set<String> getCompletedDaysSet(List history) {
    return history
        .where((h) => h['action'] == 'completed')
        .map<String>((h) => h['date'].substring(0, 10))
        .toSet();
  }

  Future<void> markTodayCompleted() async {
    isMarking = true;
    await _interactor.updateStatus("completed");
    await fetchChainStatus();
    isMarking = false;
  }

  bool isTodayCompleted() {
    final now = DateTime.now();
    try {
      final lastDate = DateTime.parse(lastUpdateDate);
      return lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
    } catch (_) {
      return false;
    }
  }
}
