import 'package:flutter/material.dart';
import '../../../styles/color_palette.dart';
import '../../../widgets/view/navbar.dart';
import '../presenter/navigation_presenter.dart';
import '../router/navigation_router.dart';
import '../../chain/view/chain_view.dart';

class NavigationView extends StatefulWidget {
  const NavigationView({super.key});

  @override
  NavigationViewState createState() => NavigationViewState();

  static NavigationViewState of(BuildContext context) {
    final state = context.findAncestorStateOfType<NavigationViewState>();
    if (state == null) throw Exception('No NavigationView ancestor found');
    return state;
  }
}

class NavigationViewState extends State<NavigationView> {
  late final NavigationPresenter presenter;
  late final NavigationRouter router;

  @override
  void initState() {
    super.initState();
    presenter = NavigationPresenter();
    router = NavigationRouter();
  }

  void showChain() => setState(() => presenter.showChain());
  void hideChain() => setState(() => presenter.hideChain());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: presenter.showChainPage
          ? ChainView(onBack: hideChain)
          : presenter.getCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: ColorPalette.backgroundColor,
          border: BorderDirectional(top: BorderSide(color: ColorPalette.gold)),
        ),
        child: CustomBottomNavBar(
          currentIndex: presenter.currentIndex,
          onTap: (i) => setState(() => presenter.onTabSelected(i)),
          isChainPageOpened: presenter.showChainPage,
        ),
      ),
    );
  }
}
