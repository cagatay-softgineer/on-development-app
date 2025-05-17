import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonFormLoader extends StatelessWidget {
  const SkeletonFormLoader({Key? key}) : super(key: key);

  // ignore: unused_element
  Widget _field(double width) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 20,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Loading…')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _SkeletonField(width: double.infinity),
            _SkeletonField(width: 200),
            _SkeletonField(width: double.infinity),
            _SkeletonField(width: 150),
          ],
        ),
      ),
    );
  }
}

class _SkeletonField extends StatelessWidget {
  final double width;
  const _SkeletonField({required this.width});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 20,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}
