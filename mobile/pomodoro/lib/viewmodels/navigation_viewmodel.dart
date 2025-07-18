import 'package:flutter/foundation.dart';

/// ViewModel for managing bottom navigation and chain overlay state.
class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 1;
  bool _showChainPage = false;

  int get currentIndex => _currentIndex;
  bool get showChainPage => _showChainPage;

  /// Switch bottom tab
  void selectTab(int index) {
    _currentIndex = index;
    _showChainPage = false;
    notifyListeners();
  }

  /// Show the chain (streak) overlay page
  void showChain() {
    _showChainPage = true;
    notifyListeners();
  }

  /// Hide the chain overlay
  void hideChain() {
    _showChainPage = false;
    notifyListeners();
  }
}
