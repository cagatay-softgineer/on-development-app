import 'package:flutter/material.dart';

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
          ModalBarrier(
            color: Colors.black38,
            dismissible: false,
          ),
        if (isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
