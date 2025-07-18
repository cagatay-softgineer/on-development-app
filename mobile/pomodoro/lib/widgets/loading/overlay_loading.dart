import 'package:flutter/material.dart';

/// A full-screen overlay with a loading indicator.
class OverlayLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const OverlayLoading({
    Key? key,
    required this.isLoading,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
