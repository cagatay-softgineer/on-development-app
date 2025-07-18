import 'package:flutter/material.dart';

class FullScreenSpinner extends StatelessWidget {
  const FullScreenSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}