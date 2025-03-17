import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/models/music_player.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/constants/default/app_icons.dart';

class PlayerControlPage extends StatefulWidget {
  final String? selectedPlaylistId;
  final MusicApp selectedApp; // New parameter to indicate which app (Spotify/YouTube)
  
  const PlayerControlPage({
    Key? key,
    this.selectedPlaylistId,
    required this.selectedApp,
  }) : super(key: key);
  
  @override
  _PlayerControlPageState createState() => _PlayerControlPageState();
}

class _PlayerControlPageState extends State<PlayerControlPage> {
  String? userID = "";
  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // Local state for repeat and shuffle modes.
  String _currentRepeatMode = "off"; // possible values: "off", "track", "context"
  bool _currentShuffleMode = false;

  // Helper function to extract the first available device ID.
  String extractFirstDeviceId(Map<String, dynamic> response) {
    if (response.containsKey('devices') && response['devices'] is List) {
      List<dynamic> devices = response['devices'];
      if (devices.isNotEmpty) {
        Map<String, dynamic> firstDevice = devices[0];
        if (firstDevice.containsKey('id') && firstDevice['id'] is String) {
          return firstDevice['id'];
        } else {
          return 'Device ID not found or is not a string.';
        }
      } else {
        return 'No devices available.';
      }
    } else {
      return 'Invalid response format: "devices" key missing or not a list.';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedApp == MusicApp.Spotify) {
    _initializeData().then((_) {
        _startStateCheckTimer();
    });
    }
  }

  Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      setState(() {
        userID = userId;
      });
      // If a selectedPlaylistId is provided, trigger playback.
      if (widget.selectedPlaylistId != null && widget.selectedPlaylistId!.isNotEmpty) {
        final responseDevices = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(responseDevices);
        // Start playback for the selected playlist.
        await spotifyAPI.playPlaylist(widget.selectedPlaylistId!, userID, deviceId);
        // Optionally, you can set repeat/shuffle mode here if needed.
      }
      // Then load the current player state.
      setState(() {
        _playerFuture = spotifyAPI.getPlayer(userID);
      });
    } catch (e) {
      print("Error during initialization: $e");
    }
  }

  /// Starts a periodic timer to check the player state every 4 seconds.
  void _startStateCheckTimer() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (userID != null && userID!.isNotEmpty) {
        try {
          final newData = await spotifyAPI.getPlayer(userID);
          // ignore: unnecessary_null_comparison
          if (newData != null && newData['item'] != null) {
            final String newRepeat = newData["repeat_state"] ?? "off";
            final bool newShuffle = newData["shuffle_state"] ?? false;
            if (_currentRepeatMode != newRepeat || _currentShuffleMode != newShuffle) {
              setState(() {
                _currentRepeatMode = newRepeat;
                _currentShuffleMode = newShuffle;
              });
            }
            setState(() {
              _playerFuture = Future.value(newData);
              _lastPlayerData = newData;
            });
          }
        } catch (e) {
          print("Error in state check: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    super.dispose();
  }

  /// Builds the appropriate player widget based on the MusicApp type.
  Widget _buildPlayerWidget(Map<String, dynamic> data, MusicApp app) {
    if (widget.selectedApp == MusicApp.YouTube) {
      // For YouTube tracks, assume the API returns a video ID in data['item']['videoId'].
      final String videoId = widget.selectedPlaylistId!;
      if (videoId.isNotEmpty) {
        print(videoId);
        return const Center(child: Text('No YouTube video available.'));
      } else {
        return const Center(child: Text('No YouTube video available.'));
      }
    } else {
      // Build Spotify player widget.
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
        layoutType: PlayerLayoutType.compact,
        albumArtUrl: albumArtUrl,
        songTitle: songTitle,
        artistName: artistName,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isPlaying: isPlaying,
        repeatMode: _currentRepeatMode,
        shuffleMode: _currentShuffleMode,
        isDynamic: true,
        onPlayPausePressed: () async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          if (isPlaying) {
            await spotifyAPI.pausePlayer(userID, deviceId);
          } else {
            await spotifyAPI.resumePlayer(userID, deviceId);
          }
          setState(() {
            _playerFuture = spotifyAPI.getPlayer(userID);
          });
        },
        onNextPressed: () async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          await spotifyAPI.skipToNext(userID, deviceId);
          setState(() {
            _playerFuture = spotifyAPI.getPlayer(userID);
          });
        },
        onPreviousPressed: () async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          await spotifyAPI.skipToPrevious(userID, deviceId);
          setState(() {
            _playerFuture = spotifyAPI.getPlayer(userID);
          });
        },
        onSeek: (newPosition) async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          await spotifyAPI.seekToPosition(
              userID, deviceId, newPosition.inMilliseconds.toString());
        },
        onRepeatPressed: () async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          String newMode;
          if (_currentRepeatMode == "off") {
            newMode = "track";
          } else if (_currentRepeatMode == "track") {
            newMode = "context";
          } else {
            newMode = "off";
          }
          await spotifyAPI.setRepeatMode(userID, deviceId, newMode);
        },
        onShufflePressed: () async {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          bool newShuffle = !_currentShuffleMode;
          await spotifyAPI.setShuffleMode(userID, deviceId, newShuffle);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userID == null || userID!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('No track is currently playing.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        actions: [
          // Show current app icon on top-right if player data is available.
          if (_lastPlayerData != null)
            Builder(builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppIcons.getAppIcon(widget.selectedApp),
              );
            }),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _playerFuture,
        builder: (context, snapshot) {
          Map<String, dynamic>? data;
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_lastPlayerData != null) {
              data = _lastPlayerData;
            } else {
              return const Center(child: Text('Loading...'));
            }
          } else if (snapshot.hasError) {
            if (_lastPlayerData != null) {
              data = _lastPlayerData;
            } else {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
          } else if (!snapshot.hasData || snapshot.data!['item'] == null) {
            if (_lastPlayerData != null) {
              data = _lastPlayerData;
            } else {
              return const Center(child: Text('No track is currently playing.'));
            }
          } else {
            data = snapshot.data;
            _lastPlayerData = snapshot.data;
          }
          
          return _buildPlayerWidget(data!, widget.selectedApp);
        },
      ),
    );
  }
}
