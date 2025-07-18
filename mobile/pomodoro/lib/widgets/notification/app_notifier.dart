import 'package:flutter/material.dart';
import 'app_notification.dart';

class AppNotifier {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    AppNoticeType type = AppNoticeType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // If a banner is already visible, remove it first
    removeCurrentOverlay();

    // Schedule the insertion for the *next* frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      // ignore: unnecessary_null_comparison
      if (overlay == null) return;

      _current = OverlayEntry(
        builder: (_) => AppNotification(
          title: title,
          message: message,
          type: type,
          duration: duration,
          onTap: onTap,
        ),
      );

      overlay.insert(_current!);
    });
  }

  static void removeCurrentOverlay() {
    _current?.remove();
    _current = null;
  }
}
