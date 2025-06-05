import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/features/player_control/view/player_control_view.dart';
import '../../../models/playlist.dart';

class PlaylistRouter {
  void openPlayer(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerControlView()),
    );
  }
}
