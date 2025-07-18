import 'package:flutter/material.dart';

/// A simple circular loading indicator.
class CircularSpinner extends StatelessWidget {
  const CircularSpinner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}