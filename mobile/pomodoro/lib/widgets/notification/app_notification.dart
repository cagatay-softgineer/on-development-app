import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pomodoro/widgets/notification/app_notifier.dart';

enum AppNoticeType { success, warning, error, info }

class AppNotification extends StatefulWidget {
  final String title;
  final String message;
  final AppNoticeType type;
  final VoidCallback? onTap;
  final Duration duration;

  const AppNotification({
    super.key,
    required this.title,
    required this.message,
    this.type = AppNoticeType.info,
    this.onTap,
    this.duration = const Duration(seconds: 5),   // ← 5-second default
  });

  @override
  State<AppNotification> createState() => _AppNotificationState();
}

class _AppNotificationState extends State<AppNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween(begin: const Offset(0, -1), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_controller);

    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_controller.isDismissed) return;
    _controller.reverse().whenComplete(() => AppNotifier.removeCurrentOverlay());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bg {
    switch (widget.type) {
      case AppNoticeType.success:
        return Colors.green.shade600;
      case AppNoticeType.warning:
        return Colors.amber.shade800;
      case AppNoticeType.error:
        return Colors.red.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppNoticeType.success:
        return Icons.check_circle_rounded;
      case AppNoticeType.warning:
        return Icons.warning_amber_rounded;
      case AppNoticeType.error:
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double bannerWidth = math.min(mq.size.width * 0.9, 600);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: widget.onTap ?? _dismiss,
              child: Container(
                width: bannerWidth,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text(widget.message,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
