import 'package:flutter/material.dart';

class PlayerControlRouter {
  void openPlaylist(BuildContext context) {
    Navigator.pushNamed(context, '/playlists');
  }
}
