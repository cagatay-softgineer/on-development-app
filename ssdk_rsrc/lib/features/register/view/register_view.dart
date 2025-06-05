import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import '../presenter/register_presenter.dart';
import '../router/register_router.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final RegisterPresenter presenter;
  late final RegisterRouter router;

  @override
  void initState() {
    super.initState();
    presenter = RegisterPresenter();
    router = RegisterRouter();
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
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 100),
                  const SizedBox(height: 5),
                  TextField(
                    controller: presenter.emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Color(0x89FFFFFF)),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color(0x89FFFFFF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF292929),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Color(0xFFF6F6F6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 5),
                  TextField(
                    controller: presenter.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF292929),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Register',
                    onPressed: () async {
                      mainButtonParams.isLoading = true;
                      final ok = await presenter.register(context);
                      mainButtonParams.isLoading = false;
                      if (ok && mounted) {
                        router.openLogin(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration Successful!')),
                        );
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
