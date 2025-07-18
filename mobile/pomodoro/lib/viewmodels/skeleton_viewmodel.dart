import 'package:flutter/foundation.dart';

/// Generic loading state for skeleton pages.
class SkeletonViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Simulate or trigger real load
  Future<void> load({Duration delay = const Duration(seconds: 2)}) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(delay);
    _isLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await load();
  }
}