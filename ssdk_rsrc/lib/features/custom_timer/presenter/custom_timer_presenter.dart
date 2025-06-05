import '../interactor/custom_timer_interactor.dart';
import 'package:flutter/material.dart';

class CustomTimerPresenter {
  final CustomTimerInteractor _interactor = CustomTimerInteractor();

  final TextEditingController workController = TextEditingController(text: '25');
  final TextEditingController breakController = TextEditingController(text: '5');

  Duration get remaining => _interactor.remaining;
  bool isRunning = false;

  void start(VoidCallback onTick, VoidCallback onComplete) {
    if (isRunning) return;
    isRunning = true;
    final workMinutes = int.tryParse(workController.text) ?? 25;
    _interactor.start(Duration(minutes: workMinutes), (d) => onTick(), () {
      isRunning = false;
      onComplete();
    });
  }

  void stop() {
    _interactor.stop();
    isRunning = false;
  }
}
