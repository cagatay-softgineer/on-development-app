import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/models/music_player.dart'; // Contains MusicPlayerWidget and Track model
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/constants/default/app_icons.dart';
import 'package:ssdk_rsrc/constants/default/youtube_playlist.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayerControlPage extends StatefulWidget {
  final String? selectedPlaylistId;
  final MusicApp selectedApp; // Indicates which app (Spotify/YouTube)
  final List? songs; // For YouTube, this should be List<Track>

  const PlayerControlPage({
    Key? key,
    this.selectedPlaylistId,
    required this.selectedApp,
    this.songs,
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

  // YouTube-specific controller and state.
  YoutubePlayerController? _youtubeController;
  Duration _youtubeCurrentPosition = Duration.zero;
  Duration _youtubeTotalDuration = Duration.zero;
  bool _youtubeIsPlaying = false;

  // Maintain a list of YouTube tracks and current index.
  List<Track> _youtubeTracks = [];
  int _currentTrackIndex = 0;

  // Helper function to extract the first available device ID (for Spotify).
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
    } else if (widget.selectedApp == MusicApp.YouTube) {
      // For YouTube, load all tracks from widget.songs.
      if (widget.songs != null && widget.songs!.isNotEmpty) {
        _youtubeTracks = widget.songs!.cast<Track>();
        _currentTrackIndex = 0;
        _initializeYoutubePlayer(_youtubeTracks[_currentTrackIndex].trackId);
      }
    }
  }

  void _initializeYoutubePlayer(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true, // We'll use our custom UI via MusicPlayerWidget.
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

  Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      setState(() {
        userID = userId;
      });
      // For Spotify: if a selectedPlaylistId is provided, trigger playback.
      if (widget.selectedPlaylistId != null && widget.selectedPlaylistId!.isNotEmpty) {
        final responseDevices = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(responseDevices);
        await spotifyAPI.playPlaylist(widget.selectedPlaylistId!, userID, deviceId);
      }
      // Then load the current player state.
      setState(() {
        _playerFuture = spotifyAPI.getPlayer(userID);
      });
    } catch (e) {
      print("Error during initialization: $e");
    }
  }

  /// Starts a periodic timer to check the Spotify player state every 4 seconds.
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
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.dispose();
    super.dispose();
  }

  /// Builds the player widget using MusicPlayerWidget for both Spotify and YouTube.
  Widget _buildPlayerWidget(Map<String, dynamic> data, MusicApp app) {
    if (widget.selectedApp == MusicApp.YouTube) {
      // Check that our playlist has at least one track.
      if (_youtubeTracks.isNotEmpty) {
        final Track currentTrack = _youtubeTracks[_currentTrackIndex];
        final String videoId = currentTrack.trackId;
        final String videoTitle = currentTrack.trackName;
        if (videoId.isNotEmpty && _youtubeController != null) {
          return Column(
            children: [
              // Offstage player to keep the controller active.
              Offstage(
                offstage: true,
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: false,
                ),
              ),
              // Use MusicPlayerWidget to display track info and controls.
              MusicPlayerWidget(
                layoutType: PlayerLayoutType.compact,
                albumArtUrl: currentTrack.trackImage.isNotEmpty
                    ? currentTrack.trackImage
                    : YouTubePlaylistConstants.defaultPlaylistImage,
                songTitle: videoTitle,
                artistName: currentTrack.artistName,
                currentPosition: _youtubeCurrentPosition,
                totalDuration: _youtubeTotalDuration,
                isPlaying: _youtubeIsPlaying,
                repeatMode: _currentRepeatMode,
                shuffleMode: _currentShuffleMode,
                isDynamic: true,
                onPlayPausePressed: () async {
                  _toggleYoutubePlayPause();
                },
                onNextPressed: () async {
                  if (_currentTrackIndex < _youtubeTracks.length - 1) {
                    _currentTrackIndex++;
                    _youtubeController!.load(_youtubeTracks[_currentTrackIndex].trackId);
                    setState(() {
                      // Reset position so UI updates.
                      _youtubeCurrentPosition = Duration.zero;
                    });
                  } else {
                    // Optionally: Handle end-of-playlist, e.g. loop or stop.
                    print("Reached end of playlist");
                  }
                },
                onPreviousPressed: () async {
                  if (_currentTrackIndex > 0) {
                    _currentTrackIndex--;
                    _youtubeController!.load(_youtubeTracks[_currentTrackIndex].trackId);
                    setState(() {
                      _youtubeCurrentPosition = Duration.zero;
                    });
                  } else {
                    print("At the beginning of the playlist");
                  }
                },
                onSeek: (newPosition) async {
                  _youtubeController!.seekTo(newPosition);
                  return;
                },
                onRepeatPressed: () async {
                  // Optionally implement repeat toggle for YouTube.
                },
                onShufflePressed: () async {
                  // Optionally implement shuffle toggle for YouTube.
                },
              ),
            ],
          );
        } else {
          return const Center(child: Text('No valid video available.'));
        }
      } else {
        return const Center(child: Text('No songs available.'));
      }
    } else {
      // Spotify branch remains unchanged.
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
          await spotifyAPI.seekToPosition(userID, deviceId, newPosition.inMilliseconds.toString());
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
    // For Spotify, ensure a valid userID exists.
    if (widget.selectedApp == MusicApp.Spotify && (userID == null || userID!.isEmpty)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('No track is currently playing.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        actions: [
          if (_lastPlayerData != null)
            Builder(builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppIcons.getAppIcon(widget.selectedApp),
              );
            }),
        ],
      ),
      body: widget.selectedApp == MusicApp.YouTube
          ? _buildPlayerWidget({}, widget.selectedApp)
          : FutureBuilder<Map<String, dynamic>>(
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
