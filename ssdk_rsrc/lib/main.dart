import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart' as deepLink;
import 'package:ssdk_rsrc/timer_page.dart';
import 'button_customizer_app.dart';
import 'widgets/custom_button.dart'; // Import the CustomButton widget
import 'styles/button_styles.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'app_links.dart';
import 'playlist_page.dart';
import 'player_control_page.dart';

void main() {
  runApp(const MyApp());
}

// Global navigator key for navigation from deep link callbacks.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late deepLink.AppLinks _appLinks;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = deepLink.AppLinks();
    _initDeepLinkListener();
  }

  Future<void> _initDeepLinkListener() async {
    // Handle the deep link that might have launched the app.
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print("Error retrieving initial link: $e");
    }

    // Listen for deep links while the app is running.
    _sub = _appLinks.uriLinkStream.listen((link) {
      _handleDeepLink(link);
    }, onError: (err) {
      print("Error in link stream: $err");
    });
  }

  void _handleDeepLink(Uri link) {
    // Process the deep link. If needed, convert the Uri to a String using link.toString()
    print('Deep link received: $link');
    //navigatorKey.currentState?.pushNamed('/applinks');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Button Customizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/button_customizer': (context) => ButtonCustomizerApp(),
        '/login_page': (context) => LoginPage(),
        '/main': (context) => HomePage(),
        '/applinks': (context) => AppLinks(), // Your custom widget for deep links.
        '/register_page': (context) => RegisterPage(),
        '/playlists': (context) => PlaylistPage(),
        '/player': (context) => PlayerControlPage(),
        '/timer': (context) => TimerPage(),
      },
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: CustomButton(
                text: "Button Customizer",
                onPressed: () {
                  Navigator.pushNamed(context, '/button_customizer');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: CustomButton(
                text: "Login Page",
                onPressed: () {
                  Navigator.pushNamed(context, '/login_page');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 350.0),
              child: CustomButton(
                text: "Register Page",
                onPressed: () {
                  Navigator.pushNamed(context, '/register_page');
                },
                buttonParams: mainButtonParams,
              ),
            ),
          ),
          // Additional widgets can be added here.
        ],
      ),
    );
  }
}