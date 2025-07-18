import 'package:flutter/material.dart';

/// Displays card-shaped placeholders.
class SkeletonCardLoading extends StatelessWidget {
  const SkeletonCardLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}