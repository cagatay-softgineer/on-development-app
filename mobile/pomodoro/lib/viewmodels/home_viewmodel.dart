import 'package:flutter/foundation.dart';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/utils/authlib.dart';
import 'package:pomodoro/data/providers/user_session.dart';
import 'package:pomodoro/core/constants/user.dart';
import 'package:pomodoro/utils/util.dart';

/// ViewModel for HomePage, handling user profile, chain streak, and showcase logic.
class HomeViewModel extends ChangeNotifier {
  // User profile
  String? userPic;
  String? userName;

  // Chain streak
  int chainStreak = 0;

  // Date & day info
  String currentDay = '';
  DateTime currentDate = DateTime.now();
  int activeStep = DateTime.now().weekday;

  // Showcase flag
  bool enableShowcase = false;

  HomeViewModel() {
    _init();
  }

  Future<void> _init() async {
    _initCurrentDay();
    await _initializeUserProfile();
    await _initializeChainStreak();
    notifyListeners();
  }

  void _initCurrentDay() {
    final tuple = getCurrentDayName();
    currentDay = tuple.$1;
    currentDate = tuple.$2;
    activeStep = currentDate.weekday;
  }

  Future<void> _initializeUserProfile() async {
    final userId = await AuthService.getUserId();
    UserSession.userID = userId;
    final profile = await mainAPI.getUserProfile();
    final pic = profile['avatar_url'] as String? ?? '';
    final name = profile['first_name'] as String? ?? '';
    userPic = (pic.isNotEmpty && Uri.tryParse(pic)?.hasAbsolutePath == true)
        ? pic
        : UserConstants.defaultAvatarUrl;
    userName = name;
    UserSession.userPIC = userPic;
    UserSession.userNAME = userName;
  }

  Future<void> _initializeChainStreak() async {
    try {
      final result = await mainAPI.getChainStatus();
      chainStreak = result['chain_streak'] as int? ?? 0;
    } catch (_) {
      chainStreak = 0;
    }
    UserSession.currentChainStreak = chainStreak;
  }

  /// Enable showcase tutorial
  void enableTutorial() {
    enableShowcase = true;
    notifyListeners();
  }
}
