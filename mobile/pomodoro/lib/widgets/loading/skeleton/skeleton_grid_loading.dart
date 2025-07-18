import 'package:flutter/material.dart';

/// Displays grid-shaped placeholders.
class SkeletonGridLoading extends StatelessWidget {
  const SkeletonGridLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}