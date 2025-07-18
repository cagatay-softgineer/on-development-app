import 'package:flutter/material.dart';

/// Displays a list of grey bars to simulate loading list items.
class SkeletonListLoading extends StatelessWidget {
  const SkeletonListLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}