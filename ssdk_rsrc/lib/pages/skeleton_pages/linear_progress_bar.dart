import 'package:flutter/material.dart';

class FullScreenLinearLoader extends StatelessWidget {
  const FullScreenLinearLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: LinearProgressIndicator(),
        ),
      ),
    );
  }
}
