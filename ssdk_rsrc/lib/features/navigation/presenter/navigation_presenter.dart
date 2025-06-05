import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/features/app_links/view/app_links_view.dart';
import 'package:ssdk_rsrc/pages/home_page.dart';
import 'package:ssdk_rsrc/features/player_control/view/player_control_view.dart';

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
        return const PlayerControlView();
      case 2:
        return const AppLinksView();
      case 1:
      default:
        return const HomePage();
    }
  }
}
