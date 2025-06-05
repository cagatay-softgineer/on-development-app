import 'package:flutter/material.dart';
import '../../../models/button_params.dart';
import '../../../utils/custom_button_funcs.dart';

class ButtonCustomizerInteractor {
  void showParams(BuildContext context, ButtonParams params) {
    showParamsDialog(context: context, params: params);
  }

  Future<void> importParams(BuildContext context, Function(ButtonParams) onChanged) {
    return importJsonFromTextBox(context: context, onParamsChanged: onChanged);
  }
}
