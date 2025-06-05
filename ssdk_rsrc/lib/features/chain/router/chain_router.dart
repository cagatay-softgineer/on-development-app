import 'package:flutter/material.dart';
import '../../navigation/view/navigation_view.dart';

class ChainRouter {
  void goBack(BuildContext context) {
    NavigationView.of(context).hideChain();
  }
}
