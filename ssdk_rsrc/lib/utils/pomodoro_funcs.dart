// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

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
        pomodoroRemaining = Duration(seconds: pomodoroRemaining.inSeconds - 1);
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
      if (sessionCount % sessionsBeforeLongBreak == 0) {
        // Only for main widget
        if (mounted) {
          // Haptic feedback here:
          if (await Vibration.hasVibrator()) {
            // Melody pattern: vibrate-pause-vibrate-pause-long-vibrate
            Vibration.vibrate(preset: VibrationPreset.longAlarmBuzz);
          }
          stopPomodoro();
          Future.delayed(const Duration(milliseconds: 300), () {
            showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Pomodoro Cycle Complete!'),
                    content: const Text('Take a longer break!'),
                    actions: [
                      TextButton(
                        onPressed:
                            () => {
                              Navigator.of(ctx).pop(),
                              Vibration.vibrate(
                                preset: VibrationPreset.progressiveBuzz,
                              ),
                            },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          });
        }
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

Future<bool> showMLPredictionDialog(
  BuildContext context,
  Map<String, dynamic> mlResult,
  Map<String, dynamic> durationData,
) async {
  final pattern = mlResult['pattern'];
  final shortBreak = mlResult['short_break'];
  final longBreak = mlResult['long_break'];
  final workSessions = mlResult['work_sessions'];

  final formattedDuration = durationData['formatted_duration'];
  final totalDurationMs = durationData['total_duration_ms'];
  final totalTrackCount = durationData['total_track_count'];

  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('AI Pomodoro Prediction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Playlist Duration Info:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Duration: $formattedDuration"),
                Text("Duration (ms): $totalDurationMs"),
                Text("Tracks: $totalTrackCount"),
                const SizedBox(height: 16),
                const Text(
                  "AI Prediction:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Pattern: $pattern"),
                Text("Short Break: $shortBreak min"),
                Text("Long Break: $longBreak min"),
                Text("Work Sessions:"),
                ...workSessions.map<Widget>((ws) => Text("- $ws min")).toList(),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text("Start"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ??
      false;
}
