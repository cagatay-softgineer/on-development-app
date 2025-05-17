import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoLoading extends StatelessWidget {
  const CupertinoLoading({Key? key}) : super(key: key);

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
