import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

typedef SkeletonItemBuilder = Widget Function(BuildContext context, int index);

class LoadingPage extends StatelessWidget {
  /// How many placeholder items to show.
  final int itemCount;

  /// Vertical spacing between each placeholder.
  final double separatorHeight;

  /// A builder that returns the placeholder widget for each index.
  /// If null, we default to a row with circle + two lines.
  final SkeletonItemBuilder itemBuilder;

  const LoadingPage({
    super.key,
    this.itemCount = 6,
    this.separatorHeight = 16.0,
    SkeletonItemBuilder? itemBuilder,
  }) : itemBuilder = itemBuilder ?? _defaultRowBuilder;

  // The old “circle avatar + two lines” skeleton:
  static Widget _defaultRowBuilder(BuildContext context, int index) {
    return Row(
      children: [
        // circle avatar
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
        // two text lines
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 14,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(height: 14, width: 100, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading…')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
