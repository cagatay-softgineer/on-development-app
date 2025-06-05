import '../../../models/button_params.dart';
import '../interactor/button_customizer_interactor.dart';
import 'package:flutter/material.dart';

class ButtonCustomizerPresenter {
  final ButtonCustomizerInteractor _interactor = ButtonCustomizerInteractor();

  ButtonParams params = ButtonParams();

  void update(ButtonParams newParams) {
    params = newParams;
  }

  void showParams(BuildContext context) {
    _interactor.showParams(context, params);
  }

  Future<void> importParams(BuildContext context, Function(void) refresh) async {
    await _interactor.importParams(context, (imported) {
      params = imported;
      refresh();
    });
  }
}
