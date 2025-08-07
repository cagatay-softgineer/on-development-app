import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps any page in a full‐screen skeleton by:
///  1. Desaturating it to pure luminance (grayscale).
///  2. Masking it to your `baseColor` × shape (`BlendMode.srcIn`).
///  3. Animating a shimmer.Highlight over that mask.
class SkeletonFromWidgetPage extends StatelessWidget {
  /// Your real page.
  final Widget child;

  /// Controls whether to show skeleton (true) or real child (false).
  final bool isLoading;

  /// If true, wraps in a Scaffold + optional AppBar.
  final bool useScaffold;
  final PreferredSizeWidget? appBar;

  /// Skeleton colors & speed.
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const SkeletonFromWidgetPage({
    super.key,
    required this.child,
    required this.isLoading,
    this.useScaffold = true,
    this.appBar,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    // 1. Desaturate everything (luminance only).
    final greyed = ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, // R
        0.2126, 0.7152, 0.0722, 0, 0, // G
        0.2126, 0.7152, 0.0722, 0, 0, // B
        0, 0, 0, 1, 0, // A
      ]),
      child: child,
    );

    // 2. Mask that greyed tree to your baseColor (shape only).
    final masked = ColorFiltered(
      colorFilter: ColorFilter.mode(baseColor, BlendMode.srcIn),
      child: greyed,
    );

    // 3. Wrap it in a shimmer
    final shimmer = Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: period,
      child: masked,
    );

    if (useScaffold) {
      return Scaffold(appBar: appBar, body: shimmer);
    }
    return shimmer;
  }
}
