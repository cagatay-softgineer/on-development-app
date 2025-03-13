import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/services/api_service.dart';
import '../models/music_player.dart';
import '../utils/timer_funcs.dart';

/// A widget that builds a MusicPlayerWidget based on the provided player data.
/// It manages the repeat and shuffle mode state internally.
class CustomPlayerWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userID;
  final GlobalKey<MusicPlayerWidgetState> musicPlayerKey;

  const CustomPlayerWidget({
    Key? key,
    required this.data,
    required this.userID,
    required this.musicPlayerKey,
  }) : super(key: key);

  @override
  _CustomPlayerWidgetState createState() => _CustomPlayerWidgetState();
}

class _CustomPlayerWidgetState extends State<CustomPlayerWidget> {
  String _currentRepeatMode = "off";
  bool _currentShuffleMode = false;

  @override
  void didUpdateWidget(CustomPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if the incoming data has changed.
    final String newRepeat = widget.data["repeat_state"] ?? "off";
    final bool newShuffle = widget.data["shuffle_state"] ?? false;
    if (_currentRepeatMode != newRepeat || _currentShuffleMode != newShuffle) {
      setState(() {
        _currentRepeatMode = newRepeat;
        _currentShuffleMode = newShuffle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final track = data['item'];
    final album = track['album'];
    final String albumArtUrl = (album['images'] as List).isNotEmpty
        ? album['images'][0]['url']
        : 'https://via.placeholder.com/300';
    final String songTitle = track['name'] ?? 'Song Title';
    final String artistName = (track['artists'] as List).isNotEmpty
        ? track['artists'][0]['name']
        : 'Artist Name';
    final Duration currentPosition =
        Duration(milliseconds: data['progress_ms'] ?? 0);
    final Duration totalDuration =
        Duration(milliseconds: track['duration_ms'] ?? 0);
    final bool isPlaying = data['is_playing'] ?? false;

    return MusicPlayerWidget(
      key: widget.musicPlayerKey,
      layoutType: PlayerLayoutType.compact,
      albumArtUrl: albumArtUrl,
      songTitle: songTitle,
      artistName: artistName,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      isPlaying: isPlaying,
      repeatMode: _currentRepeatMode,
      shuffleMode: _currentShuffleMode,
      isDynamic: false,
      onPlayPausePressed: () async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        if (isPlaying) {
          await spotifyAPI.pausePlayer(widget.userID, deviceId);
        } else {
          await spotifyAPI.resumePlayer(widget.userID, deviceId);
        }
        // Optionally, you can trigger an external refresh.
      },
      onNextPressed: () async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.skipToNext(widget.userID, deviceId);
      },
      onPreviousPressed: () async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.skipToPrevious(widget.userID, deviceId);
      },
      onSeek: (newPosition) async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.seekToPosition(
            widget.userID, deviceId, newPosition.inMilliseconds.toString());
      },
      onRepeatPressed: () async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        String newMode;
        if (_currentRepeatMode == "off") {
          newMode = "track";
        } else if (_currentRepeatMode == "track") {
          newMode = "context";
        } else {
          newMode = "off";
        }
        await spotifyAPI.setRepeatMode(widget.userID, deviceId, newMode);
      },
      onShufflePressed: () async {
        final response = await spotifyAPI.getDevices(widget.userID);
        final String deviceId = extractFirstDeviceId(response);
        bool newShuffle = !_currentShuffleMode;
        await spotifyAPI.setShuffleMode(widget.userID, deviceId, newShuffle);
      },
    );
  }
}