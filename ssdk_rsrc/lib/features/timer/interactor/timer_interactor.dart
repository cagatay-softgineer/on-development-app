import 'dart:async';

class TimerInteractor {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  Duration get remaining => _remaining;

  void start(Duration duration, void Function(Duration) onTick, void Function() onComplete) {
    _timer?.cancel();
    _remaining = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining > Duration.zero) {
        _remaining -= const Duration(seconds: 1);
        onTick(_remaining);
      } else {
        t.cancel();
        onComplete();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
