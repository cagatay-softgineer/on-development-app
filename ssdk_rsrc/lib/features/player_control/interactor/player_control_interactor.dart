class PlayerControlInteractor {
  bool isPlaying = false;
  String currentTrack = 'Unknown';

  void play() {
    isPlaying = true;
  }

  void pause() {
    isPlaying = false;
  }

  void nextTrack() {
    currentTrack = 'Next Track';
  }

  void previousTrack() {
    currentTrack = 'Previous Track';
  }
}
