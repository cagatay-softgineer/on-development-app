import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonGridLoader extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  const SkeletonGridLoader({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Loading…')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: itemCount,
          itemBuilder:
              (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
