import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  const SkeletonListLoader({super.key, this.itemCount = 6});

  Widget _row() => Row(
    children: [
      Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 14, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(width: 100, height: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading…')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => _row(),
        ),
      ),
    );
  }
}
