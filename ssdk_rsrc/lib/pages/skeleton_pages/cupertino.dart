import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoLoading extends StatelessWidget {
  const CupertinoLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );
  }
}
