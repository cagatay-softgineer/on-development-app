import 'package:flutter/material.dart';
import '../view/widgets_showroom_view.dart';

class WidgetsShowroomRouter {
  void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WidgetsShowroomView()),
    );
  }
}
