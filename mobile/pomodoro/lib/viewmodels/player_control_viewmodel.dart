// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/utils/authlib.dart';
import 'package:pomodoro/models/track.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
/// Service for Apple Music native integration.
class AppleMusicService {
  static const MethodChannel _channel = MethodChannel('apple_music');

  Future<void> initialize(String playlistId) async {
    await _channel.invokeMethod('initialize', {'playlistId': playlistId});
  }
  Future<void> play() async => await _channel.invokeMethod('play');
  Future<void> pause() async => await _channel.invokeMethod('pause');
  Future<Map<String, dynamic>> getPlaybackDetails() async {
    final details = await _channel.invokeMethod('getPlaybackDetails');
    return Map<String, dynamic>.from(details);
  }
  Future<void> skipToNext() async => await _channel.invokeMethod('skipToNext');
  Future<void> skipToPrevious() async => await _channel.invokeMethod('skipToPrevious');
  Future<void> setShuffleMode(String mode) async =>
      await _channel.invokeMethod('setShuffleMode', {'mode': mode});
}

/// ViewModel for unified music player control (Spotify, YouTube, Apple Music).
class PlayerControlViewModel extends ChangeNotifier {
  final MusicApp selectedApp;
  final String? selectedPlaylistId;
  final List<Track>? songs;

  // Spotify state
  String? userID;
  Future<Map<String, dynamic>>? playerFuture;
  Map<String, dynamic>? lastPlayerData;
  Timer? _stateCheckTimer;
  String? _deviceId;

  // YouTube state
  YoutubePlayerController? youtubeController;
  Duration youtubeCurrentPosition = Duration.zero;
  Duration youtubeTotalDuration = Duration.zero;
  bool youtubeIsPlaying = false;
  List<Track> youtubeTracks = [];
  int currentTrackIndex = 0;

  // Apple Music state
  final AppleMusicService appleMusicService = AppleMusicService();
  Map<String, dynamic>? applePlaybackDetails;
  Timer? _appleDetailsPollingTimer;

  var currentTrack;

  var playback;

  var handler;

  PlayerControlViewModel({
    required this.selectedApp,
    this.selectedPlaylistId,
    this.songs,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (selectedApp == MusicApp.spotify) {
      await _initSpotify();
      _startSpotifyPoll();
    } else if (selectedApp == MusicApp.youtube) {
      _initYouTube();
    } else if (selectedApp == MusicApp.apple) {
      await _initApple();
    }
  }

  // --- Spotify methods ---

  Future<void> _initSpotify() async {
    userID = await AuthService.getUserId();
    if (selectedPlaylistId != null && userID != null) {
      final devices = await spotifyAPI.getDevices(userID!);
      _deviceId = _extractFirstDeviceId(devices);
      await spotifyAPI.playPlaylist(selectedPlaylistId!, userID!, _deviceId!);
      playerFuture = spotifyAPI.getPlayer(userID!);
      notifyListeners();
    }
  }

  String _extractFirstDeviceId(Map<String, dynamic> resp) {
    final devices = resp['devices'] as List<dynamic>?;
    if (devices != null && devices.isNotEmpty) {
      return (devices[0]['id'] as String?) ?? '';
    }
    return '';
  }

  void _startSpotifyPoll() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (userID != null) {
        final data = await spotifyAPI.getPlayer(userID!);
        if (data['item'] != null) {
          lastPlayerData = data;
          playerFuture = Future.value(data);
          notifyListeners();
        }
      }
    });
  }

  Future<void> playPauseSpotify() async {
    if (lastPlayerData?['is_playing'] == true) {
      await spotifyAPI.pausePlayer(userID!, _deviceId!);
    } else {
      await spotifyAPI.resumePlayer(userID!, _deviceId!);
    }
    await _initSpotify();
  }

  Future<void> nextSpotify() async {
    await spotifyAPI.skipToNext(userID!, _deviceId!);
    await _initSpotify();
  }

  Future<void> previousSpotify() async {
    await spotifyAPI.skipToPrevious(userID!, _deviceId!);
    await _initSpotify();
  }

  Future<void> seekSpotify(Duration position) async {
    await spotifyAPI.seekToPosition(
      userID!,
      _deviceId!,
      position.inMilliseconds.toString(),
    );
  }

  Future<void> repeatSpotify(String newMode) async {
    await spotifyAPI.setRepeatMode(userID!, _deviceId!, newMode);
    await _initSpotify();
  }

  Future<void> shuffleSpotify(bool shuffle) async {
    await spotifyAPI.setShuffleMode(userID!, _deviceId!, shuffle);
    await _initSpotify();
  }

  // --- YouTube methods ---

  void _initYouTube() {
    if (songs != null && songs!.isNotEmpty) {
      youtubeTracks = songs!;
      final videoId = youtubeTracks[currentTrackIndex].trackId;
      youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      )..addListener(_youtubeListener);
      notifyListeners();
    }
  }

  void _youtubeListener() {
    final c = youtubeController!;
    if (c.value.isReady) {
      youtubeCurrentPosition = c.value.position;
      youtubeTotalDuration = c.metadata.duration;
      youtubeIsPlaying = c.value.isPlaying;
      notifyListeners();
    }
  }

  Future<void> playPauseYouTube() async {
    final c = youtubeController!;
    youtubeIsPlaying ? c.pause() : c.play();
    notifyListeners();
  }

  Future<void> nextYouTube() async {
    if (currentTrackIndex < youtubeTracks.length - 1) {
      currentTrackIndex++;
      youtubeController!.load(youtubeTracks[currentTrackIndex].trackId);
      youtubeCurrentPosition = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> previousYouTube() async {
    if (currentTrackIndex > 0) {
      currentTrackIndex--;
      youtubeController!.load(youtubeTracks[currentTrackIndex].trackId);
      youtubeCurrentPosition = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> seekYouTube(Duration position) async {
    youtubeController!.seekTo(position);
    notifyListeners();
  }

  // --- Apple Music methods ---

  Future<void> _initApple() async {
    if (selectedPlaylistId != null) {
      await appleMusicService.initialize(selectedPlaylistId!);
      await appleMusicService.play();
      _startApplePoll();
    }
  }

  void _startApplePoll() {
    _appleDetailsPollingTimer?.cancel();
    _appleDetailsPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      applePlaybackDetails = await appleMusicService.getPlaybackDetails();
      notifyListeners();
    });
  }

  Future<void> playPauseApple() async {
    final isPlaying = applePlaybackDetails?['isPlaying'] ?? false;
    isPlaying ? await appleMusicService.pause() : await appleMusicService.play();
    notifyListeners();
  }

  Future<void> nextApple() async {
    await appleMusicService.skipToNext();
    notifyListeners();
  }

  Future<void> previousApple() async {
    await appleMusicService.skipToPrevious();
    notifyListeners();
  }

  Future<void> seekApple(Duration position) async {
    // Apple Music SDK seeking if supported; otherwise no-op
    notifyListeners();
  }

  Future<void> shuffleApple(String mode) async {
    await appleMusicService.setShuffleMode(mode);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    youtubeController?..removeListener(_youtubeListener)..dispose();
    _appleDetailsPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> togglePlayPause() async {
  }

  Future<void> next() async {
  }

  Future<void> previous() async {
  }

  Future<void> seek(Duration newPosition) async {
  }
}
