import 'package:flutter/material.dart';
import '../../app_links/view/app_links_view.dart';
import '../../chain/view/chain_view.dart';
import '../../../pages/home_page.dart';
import '../../../pages/player_control_page.dart';
import '../../../enums/enums.dart';

class NavigationPresenter {
  int currentIndex = 1;
  bool showChainPage = false;

  void showChain() => showChainPage = true;
  void hideChain() => showChainPage = false;

  void onTabSelected(int index) {
    currentIndex = index;
    showChainPage = false;
  }

  Widget getCurrentPage() {
    switch (currentIndex) {
      case 0:
        return const PlayerControlPage(selectedApp: MusicApp.Spotify);
      case 2:
        return const AppLinksView();
      case 1:
      default:
        return const HomePage();
    }
  }
}
