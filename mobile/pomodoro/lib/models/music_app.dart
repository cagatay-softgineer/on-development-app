import 'package:flutter/material.dart';

enum MusicApp {
  spotify,
  youtube,
  apple,
}

extension MusicAppProperties on MusicApp {
  /// The default icon for this app.
  IconData get icon {
    switch (this) {
      case MusicApp.spotify:  return Icons.headset;
      case MusicApp.youtube:  return Icons.smart_display;
      case MusicApp.apple:    return Icons.apple;
    }
  }

  /// The brand color for this app.
  Color get color {
    switch (this) {
      case MusicApp.spotify:  return Color(0xFF1ED760);
      case MusicApp.youtube:  return Colors.red;
      case MusicApp.apple:    return Colors.black;
    }
  }

  /// A default size for icons (if you need a standard).
  double get size => 24.0;

  static const String defaultAppsImageUrl = 'https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Tablet/WebP/Asset%202.webp';
}
