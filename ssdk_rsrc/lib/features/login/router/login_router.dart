import 'package:flutter/material.dart';

class LoginRouter {
  void openMain(BuildContext context) {
    Navigator.pushNamed(context, '/main');
  }

  void openRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register_page');
  }
}
