import 'package:flutter/material.dart';
import '../view/button_customizer_view.dart';

class ButtonCustomizerRouter {
  void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ButtonCustomizerView()),
    );
  }
}
