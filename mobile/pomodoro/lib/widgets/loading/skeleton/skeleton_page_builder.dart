import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer configuration.
mixin _ShimmerConfig {
  Color get baseColor;
  Color get highlightColor;
  Duration get period;

  Widget applyShimmer(Widget child) => Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: period,
        child: child,
      );
}

/// Base class: handles padding, scrolling, scaffold/appbar.
abstract class SkeletonPageBuilderBase extends StatelessWidget
    with _ShimmerConfig {
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool useScaffold;
  final PreferredSizeWidget? appBar;

  @override
  final Color baseColor;
  @override
  final Color highlightColor;
  @override
  final Duration period;

  const SkeletonPageBuilderBase({
    Key? key,
    this.padding = const EdgeInsets.all(16),
    this.physics,
    this.shrinkWrap = false,
    this.useScaffold = true,
    this.appBar,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.period = const Duration(milliseconds: 1500),
  }) : super(key: key);

  /// Subclasses must implement this to build their layout.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final content = buildContent(context);
    return useScaffold
        ? Scaffold(appBar: appBar, body: content)
        : content;
  }
}

/// 1. List Skeleton
class SkeletonListPage extends SkeletonPageBuilderBase {
  final int itemCount;
  final double separatorHeight;
  final IndexedWidgetBuilder? separatorBuilder;
  final IndexedWidgetBuilder itemBuilder;

  SkeletonListPage({
    Key? key,
    this.itemCount = 6,
    this.separatorHeight = 16.0,
    this.separatorBuilder,
    IndexedWidgetBuilder? itemBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    bool useScaffold = true,
    PreferredSizeWidget? appBar,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  })  : itemBuilder = itemBuilder ?? _defaultRowBuilder,
        super(
          key: key,
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          useScaffold: useScaffold,
          appBar: appBar,
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: period,
        );

  static Widget _defaultRowBuilder(BuildContext context, int index) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 14, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
              SizedBox(height: 8),
              SizedBox(height: 14, width: 100, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      separatorBuilder:
          separatorBuilder ?? (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: (ctx, idx) =>
          applyShimmer(itemBuilder(ctx, idx)),
    );
  }
}

/// 2. Grid Skeleton
class SkeletonGridPage extends SkeletonPageBuilderBase {
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final IndexedWidgetBuilder itemBuilder;

  SkeletonGridPage({
    Key? key,
    this.itemCount = 8,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 12.0,
    this.crossAxisSpacing = 12.0,
    this.childAspectRatio = 1.0,
    IndexedWidgetBuilder? itemBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    bool useScaffold = true,
    PreferredSizeWidget? appBar,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  })  : itemBuilder = itemBuilder ?? ((_, __) => const SizedBox.shrink()),
        super(
          key: key,
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          useScaffold: useScaffold,
          appBar: appBar,
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: period,
        );

  @override
  Widget buildContent(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (ctx, idx) =>
          applyShimmer(itemBuilder(ctx, idx)),
    );
  }
}

/// 3. Custom (any builder)
class SkeletonCustomPage extends SkeletonPageBuilderBase {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  SkeletonCustomPage({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    bool useScaffold = true,
    PreferredSizeWidget? appBar,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  }) : super(
          key: key,
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          useScaffold: useScaffold,
          appBar: appBar,
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: period,
        );

  @override
  Widget buildContent(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (ctx, idx) =>
          applyShimmer(itemBuilder(ctx, idx)),
    );
  }
}

/// 4. Form Skeleton (fields + buttons)
class SkeletonFormPage extends SkeletonPageBuilderBase {
  final int formFieldCount;
  final List<double>? formFieldWidths;
  final double formFieldHeight;
  final double formFieldSpacing;
  final int formButtonCount;
  final List<double>? formButtonWidths;
  final double formButtonHeight;
  final double formButtonSpacing;

  SkeletonFormPage({
    Key? key,
    this.formFieldCount = 4,
    this.formFieldWidths,
    this.formFieldHeight = 20.0,
    this.formFieldSpacing = 16.0,
    this.formButtonCount = 2,
    this.formButtonWidths,
    this.formButtonHeight = 48.0,
    this.formButtonSpacing = 16.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    bool useScaffold = true,
    PreferredSizeWidget? appBar,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  }) : super(
          key: key,
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          useScaffold: useScaffold,
          appBar: appBar,
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: period,
        );

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      physics: physics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fields
          for (var i = 0; i < formFieldCount; i++) ...[
            applyShimmer(
              FractionallySizedBox(
                widthFactor: (formFieldWidths != null && i < formFieldWidths!.length)
                    ? formFieldWidths![i]
                    : 1.0,
                child: Container(
                  height: formFieldHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            if (i < formFieldCount - 1)
              SizedBox(height: formFieldSpacing),
          ],

          SizedBox(height: formFieldSpacing),

          // Buttons
          for (var j = 0; j < formButtonCount; j++) ...[
            applyShimmer(
              FractionallySizedBox(
                widthFactor: (formButtonWidths != null && j < formButtonWidths!.length)
                    ? formButtonWidths![j]
                    : 1.0,
                child: Container(
                  height: formButtonHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (j < formButtonCount - 1)
              SizedBox(height: formButtonSpacing),
          ],
        ],
      ),
    );
  }
}
