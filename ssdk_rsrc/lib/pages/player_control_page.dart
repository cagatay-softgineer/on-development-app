import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssdk_rsrc/constants/default/apple_playlist.dart';
import 'package:ssdk_rsrc/constants/default/spotify_playlist.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/widgets/music_player.dart'; // Contains MusicPlayerWidget and Track model
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/constants/default/youtube_playlist.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// A service class that communicates with the native Apple Music SDK via a MethodChannel.
class AppleMusicService {
  static const MethodChannel _channel = MethodChannel('apple_music');

  Future<String> initialize(String playlistId) async {
    final String result = await _channel.invokeMethod('initialize', {
      'playlistId': playlistId,
    });
    return result;
  }

  Future<String> play() async {
    final String result = await _channel.invokeMethod('play');
    return result;
  }

  Future<String> pause() async {
    final String result = await _channel.invokeMethod('pause');
    return result;
  }

  Future<Map<String, dynamic>> getPlaybackDetails() async {
    final Map<dynamic, dynamic> details = await _channel.invokeMethod(
      'getPlaybackDetails',
    );
    return details.cast<String, dynamic>();
  }

  Future<String> skipToNext() async {
    final String result = await _channel.invokeMethod('skipToNext');
    return result;
  }

  Future<String> skipToPrevious() async {
    final String result = await _channel.invokeMethod('skipToPrevious');
    return result;
  }

  Future<String> setShuffleMode(String mode) async {
    final String result = await _channel.invokeMethod('setShuffleMode', {
      'mode': mode,
    });
    return result;
  }
}

/// A Flutter page that provides a unified player interface for Spotify, YouTube, and Apple Music.
class PlayerControlPage extends StatefulWidget {
  final String? selectedPlaylistId;
  final MusicApp selectedApp; // Indicates Spotify, YouTube, or Apple
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
  // ------------------ Spotify Variables ------------------
  String? userID = "";
  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // ------------------ YouTube Variables ------------------
  YoutubePlayerController? _youtubeController;
  Duration _youtubeCurrentPosition = Duration.zero;
  Duration _youtubeTotalDuration = Duration.zero;
  bool _youtubeIsPlaying = false;
  List<Track> _youtubeTracks = [];
  int _currentTrackIndex = 0;

  // ------------------ Apple Music Variables ------------------
  final AppleMusicService appleMusicService = AppleMusicService();
  Map<String, dynamic>? _applePlaybackDetails;
  Timer? _appleDetailsPollingTimer;

  @override
  void initState() {
    super.initState();

    if (widget.selectedApp == MusicApp.Spotify) {
      _initializeSpotifyData().then((_) {
        _startStateCheckTimer();
      });
    } else if (widget.selectedApp == MusicApp.YouTube) {
      if (widget.songs != null && widget.songs!.isNotEmpty) {
        _youtubeTracks = widget.songs!.cast<Track>();
        _currentTrackIndex = 0;
        _initializeYoutubePlayer(_youtubeTracks[_currentTrackIndex].trackId);
      }
    } else if (widget.selectedApp == MusicApp.Apple) {
      _initializeAppleMusic();
    }
  }

  // ------------------ Spotify Methods ------------------
  Future<void> _initializeSpotifyData() async {
    try {
      final userId = await AuthService.getUserId();
      setState(() {
        userID = userId;
      });
      if (widget.selectedPlaylistId != null &&
          widget.selectedPlaylistId!.isNotEmpty) {
        final responseDevices = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(responseDevices);
        await spotifyAPI.playPlaylist(
          widget.selectedPlaylistId!,
          userID,
          deviceId,
        );
      }
      setState(() {
        _playerFuture = spotifyAPI.getPlayer(userID);
      });
    } catch (e) {
      print("Error during Spotify initialization: $e");
    }
  }

  String _extractFirstDeviceId(Map<String, dynamic> response) {
    if (response.containsKey('devices') && response['devices'] is List) {
      List<dynamic> devices = response['devices'];
      if (devices.isNotEmpty) {
        Map<String, dynamic> firstDevice = devices[0];
        if (firstDevice.containsKey('id') && firstDevice['id'] is String) {
          return firstDevice['id'];
        }
      }
    }
    return 'unknown';
  }

  void _startStateCheckTimer() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      if (userID != null && userID!.isNotEmpty) {
        try {
          final newData = await spotifyAPI.getPlayer(userID);
          // ignore: unnecessary_null_comparison
          if (newData != null && newData['item'] != null) {
            setState(() {
              _playerFuture = Future.value(newData);
              _lastPlayerData = newData;
            });
          }
        } catch (e) {
          print("Error in Spotify state check: $e");
        }
      }
    });
  }

  // ------------------ YouTube Methods ------------------
  void _initializeYoutubePlayer(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
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

  // ------------------ Apple Music Methods ------------------
  Future<void> _initializeAppleMusic() async {
    try {
      if (widget.selectedPlaylistId != null &&
          widget.selectedPlaylistId!.isNotEmpty) {
        // Initialize the Apple Music SDK with the playlist and start playback.
        await appleMusicService.initialize(widget.selectedPlaylistId!);
        await appleMusicService.play();
        _startAppleMusicDetailsPolling();
      }
    } catch (e) {
      print("Error during Apple Music initialization: $e");
    }
  }

  void _startAppleMusicDetailsPolling() {
    _appleDetailsPollingTimer?.cancel();
    _appleDetailsPollingTimer = Timer.periodic(Duration(seconds: 1), (
      timer,
    ) async {
      try {
        final details = await appleMusicService.getPlaybackDetails();
        setState(() {
          _applePlaybackDetails = details;
        });
      } catch (e) {
        print("Error polling Apple Music details: $e");
      }
    });
  }

  // ------------------ Cleanup ------------------
  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.dispose();
    _appleDetailsPollingTimer?.cancel();
    super.dispose();
  }

  // ------------------ UI Builders ------------------
  Widget _buildSpotifyPlayerWidget(Map<String, dynamic> data) {
    final track = data['item'];
    final album = track['album'];
    final String albumArtUrl =
        (album['images'] as List).isNotEmpty
            ? album['images'][0]['url']
            : SpotifyPlaylistConstants.defaultPlaylistImage;
    final String songTitle = track['name'] ?? 'Song Title';
    final String artistName =
        (track['artists'] as List).isNotEmpty
            ? track['artists'][0]['name']
            : 'Artist Name';
    final Duration currentPosition = Duration(
      milliseconds: data['progress_ms'] ?? 0,
    );
    final Duration totalDuration = Duration(
      milliseconds: track['duration_ms'] ?? 0,
    );
    final bool isPlaying = data['is_playing'] ?? false;

    return MusicPlayerWidget(
      layoutType: PlayerLayoutType.expanded,
      albumArtUrl: albumArtUrl,
      songTitle: songTitle,
      artistName: artistName,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      isPlaying: isPlaying,
      repeatMode: data["repeat_state"] ?? "off",
      shuffleMode: data["shuffle_state"] ?? false,
      isDynamic: true,
      currentApp: widget.selectedApp,
      onPlayPausePressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(response);
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
        final String deviceId = _extractFirstDeviceId(response);
        await spotifyAPI.skipToNext(userID, deviceId);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onPreviousPressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(response);
        await spotifyAPI.skipToPrevious(userID, deviceId);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onSeek: (newPosition) async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(response);
        await spotifyAPI.seekToPosition(
          userID,
          deviceId,
          newPosition.inMilliseconds.toString(),
        );
      },
      onRepeatPressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(response);
        String newMode;
        if (data["repeat_state"] == "off") {
          newMode = "track";
        } else if (data["repeat_state"] == "track") {
          newMode = "context";
        } else {
          newMode = "off";
        }
        await spotifyAPI.setRepeatMode(userID, deviceId, newMode);
      },
      onShufflePressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = _extractFirstDeviceId(response);
        bool newShuffle = !(data["shuffle_state"] ?? false);
        await spotifyAPI.setShuffleMode(userID, deviceId, newShuffle);
      },
    );
  }

  Widget _buildYoutubePlayerWidget() {
    if (_youtubeTracks.isNotEmpty) {
      final Track currentTrack = _youtubeTracks[_currentTrackIndex];
      final String videoId = currentTrack.trackId;
      final String videoTitle = currentTrack.trackName;
      if (videoId.isNotEmpty && _youtubeController != null) {
        return Column(
          children: [
            Offstage(
              offstage: true,
              child: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: false,
              ),
            ),
            MusicPlayerWidget(
              layoutType: PlayerLayoutType.compact,
              albumArtUrl:
                  currentTrack.trackImage.isNotEmpty
                      ? currentTrack.trackImage
                      : YouTubePlaylistConstants.defaultPlaylistImage,
              songTitle: videoTitle,
              artistName: currentTrack.artistName,
              currentPosition: _youtubeCurrentPosition,
              totalDuration: _youtubeTotalDuration,
              isPlaying: _youtubeIsPlaying,
              repeatMode: "off",
              shuffleMode: false,
              isDynamic: true,
              currentApp: widget.selectedApp,
              onPlayPausePressed: () async {
                _toggleYoutubePlayPause();
              },
              onNextPressed: () async {
                if (_currentTrackIndex < _youtubeTracks.length - 1) {
                  _currentTrackIndex++;
                  _youtubeController!.load(
                    _youtubeTracks[_currentTrackIndex].trackId,
                  );
                  setState(() {
                    _youtubeCurrentPosition = Duration.zero;
                  });
                } else {
                  print("Reached end of playlist");
                }
              },
              onPreviousPressed: () async {
                if (_currentTrackIndex > 0) {
                  _currentTrackIndex--;
                  _youtubeController!.load(
                    _youtubeTracks[_currentTrackIndex].trackId,
                  );
                  setState(() {
                    _youtubeCurrentPosition = Duration.zero;
                  });
                } else {
                  print("At the beginning of the playlist");
                }
              },
              onSeek: (newPosition) async {
                _youtubeController!.seekTo(newPosition);
              },
              onRepeatPressed: () async {
                // Implement YouTube repeat toggle if needed.
              },
              onShufflePressed: () async {
                // Implement YouTube shuffle toggle if needed.
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
  }

  Widget _buildApplePlayerWidget() {
    // Use playback details from the AppleMusicService.
    String albumArtUrl =
        _applePlaybackDetails?['albumArtUrl'] ??
        ApplePlaylistConstants.defaultPlaylistImage;
    String songTitle = _applePlaybackDetails?['songTitle'] ?? "Song Title";
    String artistName = _applePlaybackDetails?['artistName'] ?? "Artist Name";
    int currentTimeMillis = _applePlaybackDetails?['currentTime'] ?? 0;
    int totalDurationMillis = _applePlaybackDetails?['totalDuration'] ?? 0;
    bool isPlaying = _applePlaybackDetails?['isPlaying'] ?? false;

    Duration currentPosition = Duration(milliseconds: currentTimeMillis);
    Duration totalDuration = Duration(milliseconds: totalDurationMillis);

    return MusicPlayerWidget(
      layoutType: PlayerLayoutType.compact,
      albumArtUrl: albumArtUrl,
      songTitle: songTitle,
      artistName: artistName,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      isPlaying: isPlaying,
      repeatMode: "off",
      shuffleMode: false,
      isDynamic: true,
      currentApp: widget.selectedApp,
      onPlayPausePressed: () async {
        if (isPlaying) {
          await appleMusicService.pause();
        } else {
          await appleMusicService.play();
        }
      },
      onNextPressed: () async {
        await appleMusicService.skipToNext();
      },
      onPreviousPressed: () async {
        await appleMusicService.skipToPrevious();
      },
      onSeek: (newPosition) async {
        // If seeking is supported by the SDK, implement it here.
        print("Seeking not supported in Apple Music integration");
      },
      onRepeatPressed: () async {
        // Implement repeat toggle if supported.
        print("Apple Music repeat toggled");
      },
      onShufflePressed: () async {
        await appleMusicService.setShuffleMode("songs");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedApp == MusicApp.Apple) {
      return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Player - Apple Music'),
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: AppIcons.getAppIcon(widget.selectedApp),
        //     ),
        //   ],
        // ),
        backgroundColor: ColorPalette.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              _buildApplePlayerWidget(),
            ],
          ),
        ),
      );
    } else if (widget.selectedApp == MusicApp.YouTube) {
      return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Player - YouTube'),
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: AppIcons.getAppIcon(widget.selectedApp),
        //     ),
        //   ],
        // ),
        backgroundColor: ColorPalette.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              _buildYoutubePlayerWidget(),
            ],
          ),
        ),
      );
    } else {
      // Spotify branch.
      return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Player - Spotify'),
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: AppIcons.getAppIcon(widget.selectedApp),
        //     ),
        //   ],
        // ),
        backgroundColor: ColorPalette.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              FutureBuilder<Map<String, dynamic>>(
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
                  } else if (!snapshot.hasData ||
                      snapshot.data!['item'] == null) {
                    if (_lastPlayerData != null) {
                      data = _lastPlayerData;
                    } else {
                      return const Center(
                        child: Text('No track is currently playing.'),
                      );
                    }
                  } else {
                    data = snapshot.data;
                    _lastPlayerData = snapshot.data;
                  }
                  return _buildSpotifyPlayerWidget(data!);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
