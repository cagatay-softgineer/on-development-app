import 'package:flutter/material.dart';

/// Displays form field placeholders.
class SkeletonFormLoading extends StatelessWidget {
  const SkeletonFormLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
