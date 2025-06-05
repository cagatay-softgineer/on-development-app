import '../interactor/timer_interactor.dart';
import 'package:flutter/material.dart';

class TimerPresenter {
  final TimerInteractor _interactor = TimerInteractor();

  Duration get remaining => _interactor.remaining;
  bool isRunning = false;

  void start(Duration duration, VoidCallback onTick, VoidCallback onComplete) {
    if (isRunning) return;
    isRunning = true;
    _interactor.start(duration, (d) => onTick(), () {
      isRunning = false;
      onComplete();
    });
  }

  void stop() {
    _interactor.stop();
    isRunning = false;
  }
}
