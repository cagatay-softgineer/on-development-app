import 'package:flutter/material.dart';

/// A full-width linear progress indicator.
class LinearProgressBar extends StatelessWidget {
  const LinearProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LinearProgressIndicator(),
    );
  }
}