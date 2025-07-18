import 'package:flutter/material.dart';
import 'package:pomodoro/data/repositories/button_params_repository.dart';
import 'package:pomodoro/models/button_params.dart';

/// ViewModel exposing ButtonParams and operations.
class ButtonParamsViewModel extends ChangeNotifier {
  final ButtonParamsRepository _repo;
  ButtonParams _params = ButtonParams();

  ButtonParams get params => _params;
  bool get isLoading => _params.isLoading;

  ButtonParamsViewModel(this._repo) {
    loadParams();
  }

  Future<void> loadParams() async {
    _params = await _repo.getParams();
    notifyListeners();
  }

  void updateBackgroundColor(Color color) {
    _params = (_params.backgroundColor = color) as ButtonParams;
    notifyListeners();
  }

  // Add similar setters for other fields as needed...

  Future<void> saveParams() async {
    await _repo.saveParams(_params);
  }
}