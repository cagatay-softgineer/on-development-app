import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/utils/timer_funcs.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/models/music_player.dart'; // Contains Track and MusicPlayerWidget
import 'package:ssdk_rsrc/services/main_api.dart';

/// A unified custom player widget that supports both Spotify and YouTube.
/// For Spotify, it uses the existing MusicPlayerWidget (with spotifyData provided).
/// For YouTube, it plays the video in the background (hidden) and shows custom controls.
class CustomPlayerWidget extends StatefulWidget {
  // For Spotify, provide the player data as a Map.
  final Map<String, dynamic>? spotifyData;
  // For YouTube, provide a Track object that includes at least trackId and trackName.
  final Track? youtubeTrack;
  final String userID;
  final MusicApp app;
  // This key is used only for Spotify (if needed).
  final GlobalKey<MusicPlayerWidgetState>? musicPlayerKey;

  const CustomPlayerWidget({
    Key? key,
    this.spotifyData,
    this.youtubeTrack,
    required this.userID,
    required this.app,
    this.musicPlayerKey,
  }) : super(key: key);

  @override
  _CustomPlayerWidgetState createState() => _CustomPlayerWidgetState();
}

class _CustomPlayerWidgetState extends State<CustomPlayerWidget> {
  // Common state for Spotify player (repeat & shuffle)
  String _currentRepeatMode = "off";
  bool _currentShuffleMode = false;

  // YouTube-specific state
  YoutubePlayerController? _youtubeController;
  Duration _youtubeCurrentPosition = Duration.zero;
  Duration _youtubeTotalDuration = Duration.zero;
  bool _youtubeIsPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.app == MusicApp.YouTube && widget.youtubeTrack != null) {
      _initializeYoutubePlayer();
    }
  }

  void _initializeYoutubePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.youtubeTrack!.trackId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true, // Hide default controls for custom UI.
        disableDragSeek: true,
      ),
    )..addListener(_youtubeListener);
  }

  void _youtubeListener() {
    if (_youtubeController != null && _youtubeController!.value.isReady) {
      setState(() {
        _youtubeCurrentPosition = _youtubeController!.value.position;
        _youtubeTotalDuration = _youtubeController!.metadata.duration;
        _youtubeIsPlaying = _youtubeController!.value.isPlaying;
      });
    }
  }

  void _toggleYoutubePlayPause() {
    if (_youtubeController != null) {
      if (_youtubeIsPlaying) {
        _youtubeController!.pause();
      } else {
        _youtubeController!.play();
      }
    }
  }

  //@override
  //void didUpdateWidget(CustomPlayerWidget oldWidget) {
  //  super.didUpdateWidget(oldWidget);
  //  // For Spotify: update repeat and shuffle if data changes.
  //  if (widget.app == MusicApp.Spotify && widget.spotifyData != null) {
  //    final String newRepeat = widget.spotifyData!["repeat_state"] ?? "off";
  //    final bool newShuffle = widget.spotifyData!["shuffle_state"] ?? false;
  //    if (_currentRepeatMode != newRepeat || _currentShuffleMode != newShuffle) {
  //      setState(() {
  //        _currentRepeatMode = newRepeat;
  //        _currentShuffleMode = newShuffle;
  //      });
  //    }
  //  }
  //}

  @override
  void dispose() {
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.app == MusicApp.YouTube) {
      // YouTube branch: use youtubeTrack and play video in background.
      if (widget.youtubeTrack == null || widget.youtubeTrack!.trackId.isEmpty) {
        return const Center(child: Text("No valid YouTube track available."));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offstage widget keeps the YoutubePlayer active but hidden.
          Offstage(
            offstage: true,
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: false,
            ),
          ),
          // Custom UI for track data and controls.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.youtubeTrack!.trackName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Display a progress bar if duration is available.
                LinearProgressIndicator(
                  value: _youtubeTotalDuration.inSeconds > 0
                      ? _youtubeCurrentPosition.inSeconds / _youtubeTotalDuration.inSeconds
                      : 0,
                ),
                const SizedBox(height: 8),
                Text("Current: ${_youtubeCurrentPosition.inSeconds} sec / Total: ${_youtubeTotalDuration.inSeconds} sec"),
                IconButton(
                  icon: Icon(_youtubeIsPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _toggleYoutubePlayPause,
                ),
              ],
            ),
          ),
        ],
      );
    } else if (widget.app == MusicApp.Spotify) {
      // Spotify branch: use spotifyData to build MusicPlayerWidget.
      if (widget.spotifyData == null || widget.spotifyData!['item'] == null) {
        return const Center(child: Text("No Spotify track is currently playing."));
      }
      final data = widget.spotifyData!;
      final track = data['item'];
      final album = track['album'];
      final String albumArtUrl = (album['images'] as List).isNotEmpty
          ? album['images'][0]['url']
          : 'https://via.placeholder.com/300';
      final String songTitle = track['name'] ?? 'Song Title';
      final String artistName = (track['artists'] as List).isNotEmpty
          ? track['artists'][0]['name']
          : 'Artist Name';
      final Duration currentPosition = Duration(milliseconds: data['progress_ms'] ?? 0);
      final Duration totalDuration = Duration(milliseconds: track['duration_ms'] ?? 0);
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
        onPomodoroPage: true,
        currentApp: widget.app,
        onPlayPausePressed: () async {
          final response = await spotifyAPI.getDevices(widget.userID);
          final String deviceId = extractFirstDeviceId(response);
          if (isPlaying) {
            await spotifyAPI.pausePlayer(widget.userID, deviceId);
          } else {
            await spotifyAPI.resumePlayer(widget.userID, deviceId);
          }
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
    } else {
      return const Center(child: Text("Unsupported music app."));
    }
  }
}
