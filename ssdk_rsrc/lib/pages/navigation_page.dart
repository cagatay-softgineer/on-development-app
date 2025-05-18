import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/pages/app_links.dart';
import 'package:ssdk_rsrc/pages/button_customizer_app.dart';
import 'package:ssdk_rsrc/pages/home_page.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/widgets/navbar.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({Key? key}) : super(key: key);

  @override
  NavigationPageState createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('', style: TextStyle(color: Youtube.white)),
      //   backgroundColor: ColorPalette.backgroundColor,
      //   centerTitle: true,
      //   automaticallyImplyLeading: false, // Removes the back button
      // ),
      backgroundColor: ColorPalette.backgroundColor,
      body: _getCurrentPage(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.amber,
      //   onPressed: () => _onTabSelected(1),
      //   child: const Icon(Icons.home),
      // ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // boxShadow: [
          //   BoxShadow(
          //     color: ColorPalette.white.withAlpha(50),
          //     blurRadius: 30,
          //     offset: Offset(0, -10),
          //   ),
          //   BoxShadow(
          //     color: ColorPalette.almostBlack,
          //     blurRadius: 30,
          //     offset: Offset(0, 10),
          //   ),
          // ],
          shape: BoxShape.rectangle,
          // borderRadius: BorderRadius.all(Radius.circular(16)),
          color: ColorPalette.backgroundColor,
          border: BorderDirectional(top: BorderSide(color: ColorPalette.gold)),
        ),
        child: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const ButtonCustomizerApp();
      case 2:
        return const AppLinkPage();
      case 1:
        return const HomePage();
      default:
        return const HomePage();
    }
  }
}
