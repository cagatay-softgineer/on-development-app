import 'dart:async';
import 'package:flutter/material.dart';

mixin PomodoroMixin<T extends StatefulWidget> on State<T> {
  Timer? pomodoroTimer;
  Duration pomodoroRemaining = Duration.zero;
  bool isWorkPhase = true;
  int sessionCount = 0;
  Duration workDuration = Duration.zero;
  Duration shortBreakDuration = Duration.zero;
  Duration longBreakDuration = Duration.zero;
  int sessionsBeforeLongBreak = 4;

  /// Starts a Pomodoro session with the specified durations.
  Future<void> startPomodoroSession({
    required Duration workDuration,
    required Duration shortBreak,
    required Duration longBreak,
    int sessionsBeforeLongBreak = 4,
  }) async {
    pomodoroTimer?.cancel();
    setState(() {
      this.workDuration = workDuration;
      this.shortBreakDuration = shortBreak;
      this.longBreakDuration = longBreak;
      isWorkPhase = true;
      sessionCount = 0;
      pomodoroRemaining = workDuration;
      this.sessionsBeforeLongBreak = sessionsBeforeLongBreak;
    });
    pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickPomodoro();
    });
  }

  /// Internal tick function that decreases the remaining time.
  Future<void> _tickPomodoro() async {
    if (pomodoroRemaining.inSeconds > 0) {
      setState(() {
        pomodoroRemaining =
            Duration(seconds: pomodoroRemaining.inSeconds - 1);
      });
    } else {
      if (isWorkPhase) {
        sessionCount++;
        if (sessionCount % sessionsBeforeLongBreak == 0) {
          setState(() {
            pomodoroRemaining = longBreakDuration;
          });
        } else {
          setState(() {
            pomodoroRemaining = shortBreakDuration;
          });
        }
        // (Insert any work-phase end actions here, e.g. pause music)
      } else {
        setState(() {
          pomodoroRemaining = workDuration;
        });
        // (Insert any break-phase end actions here, e.g. resume music)
      }
      setState(() {
        isWorkPhase = !isWorkPhase;
      });
    }
  }
  /// Stops the Pomodoro session.
  Future<void> stopPomodoro() async {
    pomodoroTimer?.cancel();
  }

}
