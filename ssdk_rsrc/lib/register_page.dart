import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'api_service.dart';
import 'widgets/custom_button.dart'; // Import the CustomButton widget

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final ApiService apiService = ApiService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

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

    setState(() => _isLoading = true);

    try {
      final response = await apiService.register(email, password);

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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during login')),
        );
      }
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Page')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  const Text(
                        'Welcome',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                  const SizedBox(height: 100),
                  // Email Input

                  const SizedBox(height: 5),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.person, color: Color(0x89FFFFFF)),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(
                          fontFamily: 'Montserrat', color: Color(0x89FFFFFF)),
                      filled: true,
                      fillColor: const Color(0xFF292929),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(
                        fontFamily: 'Montserrat', color: Color(0xFFF6F6F6)),
                  ),
                  const SizedBox(height: 30),
                  // Password Input

                  const SizedBox(height: 5),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                          fontFamily: 'Montserrat', color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF292929),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(
                        fontFamily: 'Montserrat', color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Log In Button
                  CustomButton(
                text: "Register", // Corrected typo
                onPressed: () async {
                  mainButtonParams.isLoading = true;
                  final isLoggedIn = await register(context);
                  mainButtonParams.isLoading = false;
                      if (isLoggedIn && mounted) {
                  Navigator.pushNamed(context, '/main');
                      }
                },
                buttonParams: mainButtonParams,
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}