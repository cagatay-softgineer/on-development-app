import 'package:flutter/material.dart';
import '../../custom_timer/view/custom_timer_view.dart';

class TimerRouter {
  void openCustomTimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomTimerView()),
    );
  }
}
