import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'api_service.dart';
import 'widgets/custom_button.dart'; // Import the CustomButton widget
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final ApiService apiService = ApiService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _rememberMe = false;
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // Kullanıcı daha önce "Beni Hatırla" seçtiyse bilgileri doldur ve giriş yap
    String? savedUsername = await _secureStorage.read(key: 'username');
    String? savedPassword = await _secureStorage.read(key: 'password');
    if (savedUsername != null && savedPassword != null) {
      emailController.text = savedUsername;
      passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
      // Otomatik giriş yap
      final isLoggedIn = await login(context);
      if (isLoggedIn && mounted) {
                        Navigator.pushNamed(
                          context,
                         '/main',
                        );
                      }
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

    setState(() => _isLoading = true);

    try {
      final response = await mainAPI.login(email, password);

      if (response['error'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Login failed')),
          );
        }
        return false;
      } else {
        final token = response['access_token'];
        final user_id = response['user_id'];
        //print("Saved USER_ID : $user_id");
        if (token != null) {
          await _secureStorage.write(key: 'jwt_token', value: token);
          await _secureStorage.write(key: 'user_id', value: user_id);
          if (_rememberMe) {
          await _secureStorage.write(
              key: 'username', value: emailController.text);
          await _secureStorage.write(
              key: 'password', value: passwordController.text);
        } else {
          await _secureStorage.delete(key: 'username');
          await _secureStorage.delete(key: 'password');
        }
        }
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

                  // Remember Me Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Sola hizalama
                    children: [
                      const Text(
                        'Remember Me',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 14),
                      ),
                      const SizedBox(
                          width: 10), // Yazı ve buton arasında boşluk
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? Colors.green
                                : Colors.grey.shade800, // Renk değişimi
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                left: _rememberMe ? 30 : 0,
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

                  // Log In Button
                  CustomButton(
                text: "Login", // Corrected typo
                onPressed: () async {
                  mainButtonParams.isLoading = true;
                  final isLoggedIn = await login(context);
                  mainButtonParams.isLoading = false;
                      if (isLoggedIn && mounted) {
                  Navigator.pushNamed(context, '/main');
                      }
                },
                buttonParams: mainButtonParams,
              ),
                  const SizedBox(height: 10),
                  // Forgot Password (Login butonunun altında)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Forgot Password Logic
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register_page');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            color: Color.fromARGB(255, 0, 0, 0)),
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