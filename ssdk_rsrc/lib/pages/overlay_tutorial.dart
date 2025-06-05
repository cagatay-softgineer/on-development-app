import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Create GlobalKeys for each widget you want to showcase
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _registerBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Start the tutorial after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ShowCaseWidget.of(context).startShowCase([
        _emailKey,
        _passwordKey,
        _registerBtnKey,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Page')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Showcase(
              key: _emailKey,
              description: 'Enter your email address here.',
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Showcase(
              key: _passwordKey,
              description: 'Choose a secure password.',
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Showcase(
              key: _registerBtnKey,
              description: 'Tap here to create your account!',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
