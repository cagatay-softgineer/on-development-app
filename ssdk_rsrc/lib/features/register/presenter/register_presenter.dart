import 'package:flutter/material.dart';
import '../interactor/register_interactor.dart';

class RegisterPresenter {
  final RegisterInteractor _interactor = RegisterInteractor();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<bool> register(BuildContext context) async {
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

    isLoading = true;
    try {
      final response = await _interactor.register(email, password);
      if (response['error'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Register failed')),
          );
        }
        return false;
      } else {
        return true;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during register')),
        );
      }
      return false;
    } finally {
      isLoading = false;
    }
  }
}
