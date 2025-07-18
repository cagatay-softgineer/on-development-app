import 'dart:async';
import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:app_links/app_links.dart' as deepLink;
import 'package:pomodoro/di/injection.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/widgets/loading/skeleton/skeleton_provider.dart';
import 'package:pomodoro/resources/themes.dart';
import 'package:pomodoro/views/pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(ShowCaseWidget(builder: (context) => MyApp()));
  // This one-liner registers the MediaSession & default notification.
}

// Global navigator key for navigation from deep link callbacks.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  late deepLink.AppLinks _appLinks;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = deepLink.AppLinks();
    _initDeepLinkListener();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Wait for your API to be ready
    await mainAPI.initializeBaseUrl();

    // 2. When done, update state to remove loading UI
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initDeepLinkListener() async {
    // Handle the deep link that might have launched the app.
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      //print("Error retrieving initial link: $e");
    }

    // Listen for deep links while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      (link) {
        _handleDeepLink(link);
      },
      onError: (err) {
        //print("Error in link stream: $err");
      },
    );
  }

  void _handleDeepLink(Uri link) {
    // Process the deep link. If needed, convert the Uri to a String using link.toString()
    //print('Deep link received: $link');
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
      title: 'Home Page',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      home:
          _isLoading
              ? SkeletonProvider(
                isLoading: _isLoading,
                baseColor: ColorPalette.lightGray,
                highlightColor: ColorPalette.gold,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('', style: TextStyle(color: Youtube.white)),
                    backgroundColor: ColorPalette.backgroundColor,
                  ),
                  backgroundColor: ColorPalette.backgroundColor,
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // form field placeholder
                        const SizedBox(height: 10),

                        const SkeletonImage(
                          width: 200,
                          height: 200,
                          image: NetworkImage(
                            "https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Aurevia/PNG/Asset%201_1.png",
                          ),
                        ),

                        const SizedBox(height: 30),

                        const SkeletonText(
                          text: "Aurevia",
                          width: 200,
                          style: TextStyle(fontSize: 48),
                        ),

                        const SizedBox(height: 30),

                        const SkeletonText(text: "Email", width: 50),

                        const SizedBox(height: 20),

                        const SkeletonTextField(
                          decoration: InputDecoration(hintText: 'Email'),
                        ),

                        const SizedBox(height: 30),

                        const SkeletonText(text: "Password", width: 50),

                        const SizedBox(height: 20),

                        // another form field
                        const SkeletonTextField(
                          decoration: InputDecoration(hintText: 'Password'),
                        ),

                        const SizedBox(height: 30),

                        const SkeletonText(
                          text: "Don't Have An Account",
                          width: 150,
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 50),

                        const SizedBox(height: 50),

                        // submit button placeholder
                        SkeletonButton(
                          width: 200,
                          onPressed: () {}, // will be ignored during loading
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : LoginView(),
      routes: {
        '/main': (context) => NavigationPage(),

        '/applinks': (context) => AppLinkPage(),
        '/player':
            (context) => PlayerControlPage(selectedApp: MusicApp.spotify),
        '/timer': (context) => TimerPage(),
        '/chain_page':
            (context) => ChainPage(
              onBack: () {
                NavigationPage.of(context).hideChain();
              },
            ),
      },
    );
  }
}
