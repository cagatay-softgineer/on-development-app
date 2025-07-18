import 'package:flutter/services.dart';

class NativeNotify {
  static const _ch = MethodChannel('com.pomodoro/notify');

  /// Shows an immediate banner
  static Future<void> show(
    {required int id,
     required String title,
     required String body}) =>
      _ch.invokeMethod('show', {
        'id': id,
        'title': title,
        'body': body,
      });

  /// Schedules (exact) yyyy-mm-dd hh:mm
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when}) =>
      _ch.invokeMethod('schedule', {
        'id': id,
        'title': title,
        'body': body,
        'epoch': when.millisecondsSinceEpoch,
      });
}