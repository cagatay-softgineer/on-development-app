import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../interactor/login_interactor.dart';

class LoginPresenter {
  final LoginInteractor _interactor = LoginInteractor();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;

  void toggleRememberMe() => rememberMe = !rememberMe;

  Future<void> checkAutoLogin(BuildContext context, VoidCallback onSuccess) async {
    String? savedUsername = await _secureStorage.read(key: 'username');
    String? savedPassword = await _secureStorage.read(key: 'password');
    if (savedUsername != null && savedPassword != null) {
      emailController.text = savedUsername;
      passwordController.text = savedPassword;
      rememberMe = true;
      final ok = await login(context);
      if (ok) onSuccess();
    }
  }

  Future<bool> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return false;
    }

    final response = await _interactor.login(email, password);
    if (response['error'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed')),
        );
      }
      return false;
    } else {
      final token = response['access_token'];
      final userId = response['user_id'];
      if (token != null) {
        await _secureStorage.write(key: 'jwt_token', value: token);
        await _secureStorage.write(key: 'user_id', value: userId);
        if (rememberMe) {
          await _secureStorage.write(key: 'username', value: emailController.text);
          await _secureStorage.write(key: 'password', value: passwordController.text);
        } else {
          await _secureStorage.delete(key: 'username');
          await _secureStorage.delete(key: 'password');
        }
      }
      return true;
    }
  }
}
