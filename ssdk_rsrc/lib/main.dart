import 'dart:async';
import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:app_links/app_links.dart' as deepLink;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/pages/timer_page.dart';
import 'package:ssdk_rsrc/pages/custom_timer_page.dart';
import 'package:ssdk_rsrc/pages/button_customizer_app.dart';
import 'package:ssdk_rsrc/pages/widgets_page.dart';
import 'package:ssdk_rsrc/pages/login_page.dart';
import 'package:ssdk_rsrc/pages/register_page.dart';
import 'package:ssdk_rsrc/pages/home_page.dart';
import 'package:ssdk_rsrc/pages/app_links.dart';
import 'package:ssdk_rsrc/pages/playlist_page.dart';
import 'package:ssdk_rsrc/pages/player_control_page.dart';
import 'package:ssdk_rsrc/widgets/skeleton_provider.dart';

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

                        // const SkeletonImage(
                        //   width: 50,
                        //   height: 50,
                        //   image: NetworkImage(
                        //     "https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Placeholder/PNG/Placeholder-Circle.png",
                        //   ),
                        // ),
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
              // SkeletonFormPage(
              //   formFieldCount: 2,
              //   formFieldWidths: [0.8, 0.8],
              //   formFieldHeight: 78,
              //   formFieldSpacing: 40,
              //   formButtonCount: 1,
              //   formButtonWidths: [0.5],
              //   appBar: AppBar(title: Align(alignment: Alignment.center, child:  Text('Welcome Aboard'))),
              // )
              : StartPage(),
      routes: {
        '/button_customizer': (context) => ButtonCustomizerApp(),
        '/login_page': (context) => LoginPage(),
        '/main': (context) => HomePage(),
        '/applinks': (context) => AppLinkPage(),
        '/register_page': (context) => RegisterPage(),
        '/playlists': (context) => PlaylistPage(),
        '/player':
            (context) => PlayerControlPage(selectedApp: MusicApp.Spotify),
        '/timer': (context) => TimerPage(),
        '/custom_timer': (context) => CustomTimerPage(),
        '/widget_page': (context) => WidgetShowroomPage(),
      },
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  StartPageState createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin(); // Trigger auto-login after widget build
    });
  }

  Future<void> _checkAutoLogin() async {
    String? savedUsername = await _secureStorage.read(key: 'username');
    String? savedPassword = await _secureStorage.read(key: 'password');

    if (savedUsername != null && savedPassword != null) {
      emailController.text = savedUsername;
      passwordController.text = savedPassword;

      final isLoggedIn = await login(context);

      if (isLoggedIn && mounted) {
        Navigator.pushNamed(context, '/main');
      }
    }
  }

  Future<bool> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    setState(
      () => whiteButtonParams.isLoading = true,
    ); // Activate loading overlay
    if (email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return false;
    }

    try {
      final response = await mainAPI.login(email, password);

      if (response['error'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Login failed')),
          );
        }
        return false;
      } else {
        final token = response['access_token'];
        final user_id = response['user_id'];
        //print("Saved USER_ID : $user_id");
        if (token != null) {
          await _secureStorage.write(key: 'jwt_token', value: token);
          await _secureStorage.write(key: 'user_id', value: user_id);

          await _secureStorage.write(
            key: 'username',
            value: emailController.text,
          );
          await _secureStorage.write(
            key: 'password',
            value: passwordController.text,
          );
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during login')),
        );
      }
      return false;
    } finally {
      setState(
        () => whiteButtonParams.isLoading = false,
      ); // Deactivate loading overlay
    }
  }

  @override
  Widget build(BuildContext context) {
    return
    //Align(
    //  alignment: Alignment.topCenter,
    //  child: Padding(
    //    padding: const EdgeInsets.only(top: 50.0),
    //    child:
    //    CustomButton(
    //      text: "Button Customizer",
    //      onPressed: () {
    //        Navigator.pushNamed(context, '/button_customizer');
    //      },
    //      buttonParams: mainButtonParams,
    //    ),
    //  ),
    //),
    Scaffold(
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

            Image(
              color: ColorPalette.gold,
              colorBlendMode: BlendMode.srcIn,
              width: 200,
              height: 200,
              image: const NetworkImage(
                "https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Aurevia/PNG/Asset%201_1.png",
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Aurevia",
              style: TextStyle(
                color: ColorPalette.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Email",
              textAlign: TextAlign.left,
              style: TextStyle(color: ColorPalette.white),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              style: TextStyle(color: ColorPalette.white),
              decoration: InputDecoration(
                hintText: 'Email',
                // Unfocused border
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color:
                        ColorPalette.lightGray, // your unfocused border color
                    width: 1.0,
                  ),
                ),
                // Focused border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.gold, // your focused border color
                    width: 2.0,
                  ),
                ),
                // If you also want an error border:
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.youtubeRed,
                    width: 1.0,
                  ),
                ),
                // And a focused error border:
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.youtubeRed,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Password",
              textAlign: TextAlign.left,
              style: TextStyle(color: ColorPalette.white),
            ),

            const SizedBox(height: 20),

            // another form field
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: ColorPalette.white),
              decoration: InputDecoration(
                hintText: 'Password',
                // Unfocused border
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color:
                        ColorPalette.lightGray, // your unfocused border color
                    width: 1.0,
                  ),
                ),
                // Focused border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.gold, // your focused border color
                    width: 2.0,
                  ),
                ),
                // If you also want an error border:
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.youtubeRed,
                    width: 1.0,
                  ),
                ),
                // And a focused error border:
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: ColorPalette.youtubeRed,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                // your tap handler here
                showGeneralDialog(
                  context: context,
                  barrierLabel: '',
                  barrierDismissible: true,
                  barrierColor: Transparent.a77,
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, __, ___) {
                    return SafeArea(
                      child: Scaffold(
                        backgroundColor: Transparent.a00,
                        body: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 24,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorPalette.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: ColorPalette.gold)],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Expanded + TextAlign.center will center this text in the available space
                                    Expanded(
                                      child: Text(
                                        'How Would You Like To Join Us',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ColorPalette.white,
                                        ),
                                      ),
                                    ),

                                    // Your “X” button stays at the right edge
                                    CustomButton(
                                      text: "",
                                      buttonParams: closeButtonParams,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: Size(800, 100),
                                    elevation:
                                        0, // Avoid double shadows when using BoxShadow
                                    shadowColor: ColorPalette.gold,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: ColorPalette.gold,
                                      width: 1,
                                    ),
                                    backgroundColor:
                                        ColorPalette
                                            .backgroundColor, // Make background transparent
                                  ),
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image(
                                        // We Can't Color Google Logo (https://developers.google.com/identity/branding-guidelines)
                                        // color: ColorPalette.gold,
                                        // colorBlendMode: BlendMode.xor,
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.centerLeft,
                                        image: const NetworkImage(
                                          "https://www.gstatic.com/marketing-cms/assets/images/d5/dc/cfe9ce8b4425b410b49b7f2dd3f3/g.webp=s48-fcrop64=1,00000000ffffffff-rw",
                                        ),
                                      ),
                                      Text(
                                        "Google",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: ColorPalette.white,
                                          fontSize: 32,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 32,
                                        color: ColorPalette.gold,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: Size(800, 100),
                                    elevation:
                                        0, // Avoid double shadows when using BoxShadow
                                    shadowColor: ColorPalette.gold,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: ColorPalette.gold,
                                      width: 1,
                                    ),
                                    backgroundColor:
                                        ColorPalette
                                            .backgroundColor, // Make background transparent
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showGeneralDialog(
                                      context: context,
                                      barrierLabel: '',
                                      barrierDismissible: true,
                                      barrierColor: Transparent.a77,
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      pageBuilder: (_, __, ___) {
                                        return SafeArea(
                                          child: Scaffold(
                                            backgroundColor: Transparent.a00,
                                            floatingActionButtonLocation:
                                                FloatingActionButtonLocation
                                                    .miniCenterDocked,
                                            floatingActionButton: Container(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  SizedBox(height: 500),
                                                  Center(
                                                    child: CustomButton(
                                                      text: 'Sign In',
                                                      buttonParams:
                                                          whiteButtonParams,
                                                      onPressed: () {
                                                        print("Click!");
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            body: Center(
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 24,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      ColorPalette
                                                          .backgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: ColorPalette.gold,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        // Expanded + TextAlign.center will center this text in the available space
                                                        Expanded(
                                                          child: Text(
                                                            'First, We Need Your Information',
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  ColorPalette
                                                                      .white,
                                                            ),
                                                          ),
                                                        ),

                                                        // Your “X” button stays at the right edge
                                                        CustomButton(
                                                          text: "",
                                                          buttonParams:
                                                              closeButtonParams,
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),

                                                    Text(
                                                      "Email",
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        color:
                                                            ColorPalette.white,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 10),

                                                    TextField(
                                                      style: TextStyle(
                                                        color:
                                                            ColorPalette.white,
                                                      ),
                                                      decoration: InputDecoration(
                                                        hintText: 'Email',
                                                        // Unfocused border
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .lightGray, // your unfocused border color
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        // Focused border
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .gold, // your focused border color
                                                            width: 2.0,
                                                          ),
                                                        ),
                                                        // If you also want an error border:
                                                        errorBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .youtubeRed,
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        // And a focused error border:
                                                        focusedErrorBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8.0,
                                                                  ),
                                                              borderSide: BorderSide(
                                                                color:
                                                                    ColorPalette
                                                                        .youtubeRed,
                                                                width: 2.0,
                                                              ),
                                                            ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 12.0,
                                                              horizontal: 16.0,
                                                            ),
                                                      ),
                                                    ),

                                                    const SizedBox(height: 10),

                                                    Text(
                                                      "Password",
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        color:
                                                            ColorPalette.white,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 10),

                                                    TextField(
                                                      style: TextStyle(
                                                        color:
                                                            ColorPalette.white,
                                                      ),
                                                      obscureText: true,
                                                      decoration: InputDecoration(
                                                        hintText: 'Password',
                                                        // Unfocused border
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .lightGray, // your unfocused border color
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        // Focused border
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .gold, // your focused border color
                                                            width: 2.0,
                                                          ),
                                                        ),
                                                        // If you also want an error border:
                                                        errorBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                ColorPalette
                                                                    .youtubeRed,
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        // And a focused error border:
                                                        focusedErrorBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8.0,
                                                                  ),
                                                              borderSide: BorderSide(
                                                                color:
                                                                    ColorPalette
                                                                        .youtubeRed,
                                                                width: 2.0,
                                                              ),
                                                            ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 12.0,
                                                              horizontal: 16.0,
                                                            ),
                                                      ),
                                                    ),

                                                    const SizedBox(height: 30),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      transitionBuilder: (_, anim, __, child) {
                                        // simple fade + scale transition
                                        return FadeTransition(
                                          opacity: anim,
                                          child: ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 40,
                                        color: ColorPalette.gold,
                                      ),
                                      Text(
                                        "Via App",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: ColorPalette.white,
                                          fontSize: 32,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 32,
                                        color: ColorPalette.gold,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  transitionBuilder: (_, anim, __, child) {
                    // simple fade + scale transition
                    return FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    );
                  },
                );
              },
              child: Text(
                "Don't Have An Account",
                style: TextStyle(color: ColorPalette.clickable, fontSize: 12),
              ),
            ),

            const SizedBox(height: 10),

            const SizedBox(height: 50),

            //
            // GestureDetector(
            //   onTap: () {
            //     // your tap handler here
            //     print('Image tapped!');
            //   },
            //   child: Image(
            //     // We Can't Color Google Logo (https://developers.google.com/identity/branding-guidelines)
            //     // color: ColorPalette.gold,
            //     // colorBlendMode: BlendMode.xor,
            //     width: 50,
            //     height: 50,
            //     image: const NetworkImage(
            //       "https://www.gstatic.com/marketing-cms/assets/images/d5/dc/cfe9ce8b4425b410b49b7f2dd3f3/g.webp=s48-fcrop64=1,00000000ffffffff-rw",
            //     ),
            //   ),
            // ),
            const SizedBox(height: 50),

            // submit button placeholder
            CustomButton(
              text: 'Login',
              onPressed: () async {
                final isLoggedIn = await login(context);
                if (isLoggedIn && mounted) {
                  Navigator.pushNamed(context, '/main');
                }
                ;
              }, // will be ignored during loading
              buttonParams: whiteButtonParams,
            ),
          ],
        ),
      ),
    );
    // Align(
    //   alignment: Alignment.topCenter,
    //   child: Padding(
    //     padding: const EdgeInsets.only(top: 50.0),
    //     child: CustomButton(
    //       text: "Login Page",
    //       onPressed: () {
    //         Navigator.pushNamed(context, '/login_page');
    //       },
    //       buttonParams: mainButtonParams,
    //     ),
    //   ),
    // ),
    // Align(
    //   alignment: Alignment.topCenter,
    //   child: Padding(
    //     padding: const EdgeInsets.only(top: 200.0),
    //     child: CustomButton(
    //       text: "Register Page",
    //       onPressed: () {
    //         Navigator.pushNamed(context, '/register_page');
    //       },
    //       buttonParams: mainButtonParams,
    //     ),
    //   ),
    // ),
    // Align(
    //   alignment: Alignment.topCenter,
    //   child: Padding(
    //     padding: const EdgeInsets.only(top: 350.0),
    //     child: CustomButton(
    //       text: "Widget Page",
    //       onPressed: () {
    //         Navigator.pushNamed(context, '/widget_page');
    //       },
    //       buttonParams: mainButtonParams,
    //     ),
    //   ),
    // ),
    // Additional widgets can be added here.
  }
}
