import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// One global audio handler that the whole app talks to.
///
/// * Registers a MediaSession so Android/iOS show media controls.
/// * Streams playback state & position for the UI to observe.
class PlaybackService extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  PlaybackService() {
    _bridgeToSystemControls();
  }

  /* ------------------------------------------------------------------ */
  /* Public API your view-models & pages will call                      */
  /* ------------------------------------------------------------------ */

  Future<void> loadAndPlay(Uri url, MediaItem meta) async {
    mediaItem.add(meta);
    await _player.setUrl(url.toString());
    await _player.play();
  }

  @override
  Future<void> play()  => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToNext()     => _player.seekToNext();
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /* ------------------------------------------------------------------ */
  /* Plumbing: push events from just_audio to the system & UI           */
  /* ------------------------------------------------------------------ */

  void _bridgeToSystemControls() {
    // Position updates
    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    // Processing + playing flags
    _player.playerStateStream.listen((s) {
      final processing = {
        ProcessingState.idle:       AudioProcessingState.idle,
        ProcessingState.loading:    AudioProcessingState.loading,
        ProcessingState.buffering:  AudioProcessingState.buffering,
        ProcessingState.ready:      AudioProcessingState.ready,
        ProcessingState.completed:  AudioProcessingState.completed,
      }[s.processingState]!;

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            s.playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          playing: s.playing,
          processingState: processing,
        ),
      );
    });
  }

  @override
  Future<void> stop() async {
    await _player.dispose();
    await super.stop();
  }
}
