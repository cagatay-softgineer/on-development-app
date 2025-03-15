import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/enums/enums.dart';

/// Contains default icon properties for playlist sources and a helper
/// method to get the default icon by app type.
class AppIcons {
  // Spotify icon properties
  static const IconData spotifyIcon = Icons.headset;
  static const Color spotifyIconColor = Color(0xFF1ED760);
  static const double spotifyIconSize = 24.0;

  // YouTube icon properties
  static const IconData youtubeIcon = Icons.video_library;
  static const Color youtubeIconColor = Colors.red;
  static const double youtubeIconSize = 24.0;

  /// Returns a default Icon widget based on the provided [app] type.
  static Icon getAppIcon(MusicApp app) {
    switch (app) {
      case MusicApp.Spotify:
        return const Icon(spotifyIcon, color: spotifyIconColor, size: spotifyIconSize);
      case MusicApp.YouTube:
        return const Icon(youtubeIcon, color: youtubeIconColor, size: youtubeIconSize);
    }
  }
}
