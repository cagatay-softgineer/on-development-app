import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import '../presenter/login_presenter.dart';

import '../router/login_router.dart';
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginPresenter presenter;
late final LoginRouter router;

  @override
  void initState() {
    super.initState();
    presenter = LoginPresenter();
    router = LoginRouter();
    presenter.checkAutoLogin(context, () {
      if (mounted) router.openMain(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
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
                    'Welcome Back ',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => presenter.toggleRememberMe()),
                        child: Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            color: presenter.rememberMe
                                ? Colors.green
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                left: presenter.rememberMe ? 30 : 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Login',
                    onPressed: () async {
                      mainButtonParams.isLoading = true;
                      final ok = await presenter.login(context);
                      mainButtonParams.isLoading = false;
                      if (ok && mounted) {
                        router.openMain(context);
                      }
                    },
                    buttonParams: mainButtonParams,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        router.openRegister(context);
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
