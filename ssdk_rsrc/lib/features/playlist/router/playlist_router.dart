import 'package:flutter/material.dart';
import '../../../pages/player_control_page.dart';
import '../../../models/playlist.dart';

class PlaylistRouter {
  void openPlayer(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerControlPage(
          selectedPlaylistId: playlist.playlistId,
          selectedApp: playlist.app,
        ),
      ),
    );
  }
}
