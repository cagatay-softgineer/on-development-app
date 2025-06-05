import 'package:flutter/material.dart';
import '../view/navigation_view.dart';

class NavigationRouter {
  void showChain(BuildContext context) {
    NavigationView.of(context).showChain();
  }

  void hideChain(BuildContext context) {
    NavigationView.of(context).hideChain();
  }
}
