import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro/models/button_params.dart';

/// Reads/writes ButtonParams JSON from local storage.
class ButtonParamsLocalDataSource {
  static const _storageKey = 'button_params';

  Future<ButtonParams> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return ButtonParams.fromMap(map);
    }
    return ButtonParams();
  }

  Future<void> save(ButtonParams params) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(params.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}