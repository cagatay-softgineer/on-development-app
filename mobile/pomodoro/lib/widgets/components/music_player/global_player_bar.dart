import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'package:pomodoro/widgets/components/music_player/music_player.dart';
import 'package:pomodoro/viewmodels/player_control_viewmodel.dart';
import 'package:pomodoro/models/music_app.dart';

class GlobalPlayerBar extends StatelessWidget {
  const GlobalPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerControlViewModel>();

    return StreamBuilder<MediaItem?>(
      stream: vm.currentTrack,
      builder: (_, trackSnap) {
        final item = trackSnap.data;
        if (item == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: vm.playback,
          builder: (_, stateSnap) {
            final state = stateSnap.data ?? vm.handler.playbackState.value;

            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: MusicPlayerWidget(
                  layoutType      : PlayerLayoutType.compact,
                  albumArtUrl     : item.artUri.toString(),
                  songTitle       : item.title,
                  artistName      : item.artist ?? '',
                  currentPosition : state.position,
                  totalDuration   : item.duration ?? Duration.zero,
                  isPlaying       : state.playing,
                  repeatMode      : state.repeatMode.name,
                  shuffleMode     : state.shuffleMode,
                  isDynamic       : false,
                  currentApp      : MusicApp.spotify,
                  onPlayPausePressed: vm.togglePlayPause,
                  onNextPressed     : vm.next,
                  onPreviousPressed : vm.previous,
                  onSeek            : vm.seek,
                  onRepeatPressed   : null,
                  onShufflePressed  : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
