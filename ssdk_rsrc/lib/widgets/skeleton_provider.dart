import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 1. Provider that holds whether we're loading + shimmer config.
class SkeletonProvider extends InheritedWidget {
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const SkeletonProvider({
    super.key,
    required this.isLoading,
    required super.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.period = const Duration(milliseconds: 1500),
  });

  static SkeletonProvider of(BuildContext context) {
    final prov = context.dependOnInheritedWidgetOfExactType<SkeletonProvider>();
    assert(prov != null, 'No SkeletonProvider found in context');
    return prov!;
  }

  @override
  bool updateShouldNotify(covariant SkeletonProvider old) {
    return old.isLoading != isLoading ||
        old.baseColor != baseColor ||
        old.highlightColor != highlightColor ||
        old.period != period;
  }
}

/// 2. A simple box you can reuse everywhere.
class SkeletonBox extends StatelessWidget {
  final double width, height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);
    return Shimmer.fromColors(
      baseColor: prov.baseColor,
      highlightColor: prov.highlightColor,
      period: prov.period,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: prov.baseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// 3. Skeleton‐aware TextField
class SkeletonTextField extends StatelessWidget {
  final InputDecoration decoration;
  final TextEditingController? controller;

  const SkeletonTextField({
    super.key,
    this.decoration = const InputDecoration(),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);
    if (prov.isLoading) {
      // match typical TextField height ~48
      return const SkeletonBox(width: double.infinity, height: 48);
    }
    return TextField(controller: controller, decoration: decoration);
  }
}

/// 4. Skeleton‐aware Button
class SkeletonButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final double width;
  final double height;

  const SkeletonButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 48,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);
    if (prov.isLoading) {
      // match typical button size ~48
      return SkeletonBox(width: width, height: height, borderRadius: const BorderRadius.all(Radius.circular(8)));
    }
    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

/// 5. Skeleton‐aware Image
class SkeletonImage extends StatelessWidget {
  final double width, height;
  final ImageProvider image;
  final BoxFit fit;

  const SkeletonImage({
    super.key,
    required this.width,
    required this.height,
    required this.image,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);
    if (prov.isLoading) {
      return SkeletonBox(width: width, height: height, borderRadius: BorderRadius.circular(8));
    }
    return Image(image: image, width: width, height: height, fit: fit);
  }
}

class SkeletonText extends StatelessWidget {
  /// The actual text to display when not loading.
  final String text;

  /// Styling for the text (also used to size the placeholder).
  final TextStyle? style;

  /// Maximum width for the placeholder. If null, falls back to full width.
  final double? width;

  /// Radius for rounding the placeholder’s corners.
  final BorderRadius borderRadius;

  const SkeletonText({
    super.key,
    required this.text,
    this.style,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    final prov = SkeletonProvider.of(context);
    if (prov.isLoading) {
      // Approximate text height from style, defaulting to 16 if unspecified
      final placeholderHeight = style?.fontSize ?? 16.0;
      return Shimmer.fromColors(
        baseColor: prov.baseColor,
        highlightColor: prov.highlightColor,
        period: prov.period,
        child: Container(
          width: width ?? double.infinity,
          height: placeholderHeight * 1.2, // add a bit of vertical padding
          decoration: BoxDecoration(
            color: prov.baseColor,
            borderRadius: borderRadius,
          ),
        ),
      );
    } else {
      return Text(
        text,
        style: style,
      );
    }
  }
}

// SkeletonProvider(
//  isLoading: _isLoading,
//  baseColor: ColorPalette.lightGray,
//  highlightColor: ColorPalette.gold,
//  child: Scaffold(
//    appBar: AppBar(title: Text('Home Page', style: TextStyle(color: Youtube.white)), backgroundColor: ColorPalette.backgroundColor),
//    backgroundColor: ColorPalette.backgroundColor,
//    body: Padding(
//      padding: const EdgeInsets.all(16),
//      child: Column(
//        children: [
//          // image placeholder
//          const SkeletonImage(width: 100, height: 100, image: AssetImage('dummy')),
//          const SizedBox(height
//          // form field placeholder
//          const SkeletonTextField(decoration: InputDecoration(hintText: 'Na
//          const SizedBox(height
//          // another form field
//          const SkeletonTextField(decoration: InputDecoration(hintText: 'Ema
//          const SizedBox(height
//          // submit button placeholder
//          SkeletonButton(
//            child: const Text('Submit'),
//            onPressed: () {}, // will be ignored during loading
//          ),
//        ],
//      ),
//    ),
//  ),
//)
