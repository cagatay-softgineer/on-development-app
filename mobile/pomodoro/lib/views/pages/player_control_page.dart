import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/viewmodels/player_control_viewmodel.dart';
import 'package:pomodoro/resources/themes.dart';
import 'package:pomodoro/widgets/components/music_player/music_player.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/models/track.dart';

/// Page hosting the unified music player UI.
class PlayerControlPage extends StatelessWidget {
  final String? selectedPlaylistId;
  final MusicApp selectedApp;
  final List<Track>? songs;

  const PlayerControlPage({
    super.key,
    this.selectedPlaylistId,
    required this.selectedApp,
    this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => PlayerControlViewModel(
            selectedApp: selectedApp,
            selectedPlaylistId: selectedPlaylistId,
            songs: songs,
     ),
      child: Consumer<PlayerControlViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: ColorPalette.backgroundColor,
            body: SafeArea(child: _buildBody(context, vm)),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PlayerControlViewModel vm) {
    switch (vm.selectedApp) {
      case MusicApp.apple:
        return _buildApple(vm);
      case MusicApp.youtube:
        return _buildYouTube(vm);
      case MusicApp.spotify:
        return _buildSpotify(vm);
    }
  }

  Widget _buildSpotify(PlayerControlViewModel vm) {
    return FutureBuilder<Map<String, dynamic>>(
      future: vm.playerFuture,
      builder: (context, snap) {
        final data = snap.hasData ? snap.data! : vm.lastPlayerData;
        if (data == null) return const Center(child: Text('Loading...'));
        return MusicPlayerWidget(
          layoutType: PlayerLayoutType.expanded,
          albumArtUrl: data['item']['album']['images'][0]['url'],
          songTitle: data['item']['name'],
          artistName: data['item']['artists'][0]['name'],
          currentPosition: Duration(milliseconds: data['progress_ms']),
          totalDuration: Duration(milliseconds: data['item']['duration_ms']),
          isPlaying: data['is_playing'],
          repeatMode: data['repeat_state'],
          shuffleMode: data['shuffle_state'],
          isDynamic: true,
          currentApp: MusicApp.spotify,
          onPlayPausePressed: () async => await vm.playPauseSpotify(),
          onNextPressed: () async => await vm.nextSpotify(),
          onPreviousPressed: () async => await vm.previousSpotify(),
          onSeek: (pos) async => await vm.seekSpotify(pos),
          onRepeatPressed:
              () async =>
                  await vm.repeatSpotify(_nextRepeatMode(data['repeat_state'])),
          onShufflePressed:
              () async =>
                  await vm.shuffleSpotify(!(data['shuffle_state'] ?? false)),
        );
      },
    );
  }

  String _nextRepeatMode(String current) {
    switch (current) {
      case 'off':
        return 'track';
      case 'track':
        return 'context';
      default:
        return 'off';
    }
  }

  Widget _buildYouTube(PlayerControlViewModel vm) {
    return vm.youtubeController == null
        ? const Center(child: Text('No songs available'))
        : MusicPlayerWidget(
          layoutType: PlayerLayoutType.compact,
          albumArtUrl: vm.youtubeTracks[vm.currentTrackIndex].trackImage,
          songTitle: vm.youtubeTracks[vm.currentTrackIndex].trackName,
          artistName: vm.youtubeTracks[vm.currentTrackIndex].artistName,
          currentPosition: vm.youtubeCurrentPosition,
          totalDuration: vm.youtubeTotalDuration,
          isPlaying: vm.youtubeIsPlaying,
          repeatMode: 'off',
          shuffleMode: false,
          isDynamic: true,
          currentApp: MusicApp.youtube,
          onPlayPausePressed: () async => await vm.playPauseYouTube(),
          onNextPressed: () async => await vm.nextYouTube(),
          onPreviousPressed: () async => await vm.previousYouTube(),
          onSeek: (pos) async => await vm.seekYouTube(pos),
          onRepeatPressed: null,
          onShufflePressed: null,
        );
  }

  Widget _buildApple(PlayerControlViewModel vm) {
    final details = vm.applePlaybackDetails;
    if (details == null) return const Center(child: Text('Loading...'));
    return MusicPlayerWidget(
      layoutType: PlayerLayoutType.compact,
      albumArtUrl: details['albumArtUrl'],
      songTitle: details['songTitle'],
      artistName: details['artistName'],
      currentPosition: Duration(milliseconds: details['currentTime']),
      totalDuration: Duration(milliseconds: details['totalDuration']),
      isPlaying: details['isPlaying'],
      repeatMode: 'off',
      shuffleMode: false,
      isDynamic: true,
      currentApp: MusicApp.apple,
      onPlayPausePressed: () async => await vm.playPauseApple(),
      onNextPressed: () async => await vm.nextApple(),
      onPreviousPressed: () async => await vm.previousApple(),
      onSeek: (pos) async => await vm.seekApple(pos),
      onRepeatPressed: null,
      onShufflePressed: () async => await vm.shuffleApple('songs'),
    );
  }
}
