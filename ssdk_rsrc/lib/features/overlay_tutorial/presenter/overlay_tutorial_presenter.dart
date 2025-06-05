import '../interactor/overlay_tutorial_interactor.dart';

class OverlayTutorialPresenter {
  final OverlayTutorialInteractor _interactor = OverlayTutorialInteractor();

  Future<void> finishTutorial() async {
    await _interactor.completeTutorial();
  }
}
