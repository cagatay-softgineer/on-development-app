import '../interactor/player_control_interactor.dart';

class PlayerControlPresenter {
  final PlayerControlInteractor _interactor = PlayerControlInteractor();

  bool get isPlaying => _interactor.isPlaying;
  String get currentTrack => _interactor.currentTrack;

  void togglePlay() {
    if (_interactor.isPlaying) {
      _interactor.pause();
    } else {
      _interactor.play();
    }
  }

  void next() {
    _interactor.nextTrack();
  }

  void previous() {
    _interactor.previousTrack();
  }
}
