import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pomodoro/views/pages/home_page.dart';
import 'package:pomodoro/views/pages/navigation_page.dart';
import 'package:pomodoro/data/providers/apps_session.dart';
import 'package:pomodoro/data/providers/user_session.dart';
import 'package:pomodoro/models/linked_app.dart';
import 'package:pomodoro/widgets/card/app_card.dart';
import 'package:pomodoro/utils/authlib.dart';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/core/constants/user.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/resources/themes.dart';
import 'package:pomodoro/widgets/icon/glowing_icon.dart';
import 'package:pomodoro/widgets/components/top_bar.dart';

class AppLinkPage extends StatefulWidget {
  const AppLinkPage({super.key});

  @override
  AppLinkPageState createState() => AppLinkPageState();
}

class AppLinkPageState extends State<AppLinkPage> with WidgetsBindingObserver {
  // Define a list of apps with initial configurations.

  HomePageBody homepage = HomePageBody();

  final List<LinkedApp> linkedApps = [
    LinkedApp(
      name: "Spotify",
      appButtonParams: spotifyButtonParams,
      appPic:
          "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png",
      appColor: Spotify.green,
    ),
    LinkedApp(
      name: "AppleMusic",
      appButtonParams: appleMusicButtonParams,
      appPic:
          "https://play-lh.googleusercontent.com/mOkjjo5Rzcpk7BsHrsLWnqVadUK1FlLd2-UlQvYkLL4E9A0LpyODNIQinXPfUMjUrbE=w240-h480-rw",
      appColor: AppleMusic.pink,
    ),
    LinkedApp(
      name: "YoutubeMusic",
      appButtonParams: youtubeMusicButtonParams,
      appPic:
          "https://upload.wikimedia.org/wikipedia/commons/d/d8/YouTubeMusic_Logo.png",
      appColor: Youtube.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLinkedApps();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeLinkedApps();
    }
  }

  /// Fetches the binding state for all apps using the consolidated API endpoint and updates the local state.
  Future<void> _initializeLinkedApps() async {
    final String? userEmail = await AuthService.getUserId();
    if (userEmail == null) {
      return;
    }
    AppsSession.userEmail = userEmail;

    final response = await mainAPI.getAllAppsBinding(userEmail);

    if (response.containsKey('apps')) {
      // Map app name to app info
      final Map<String, dynamic> appsBindingMap = {};
      for (var app in response['apps']) {
        if (app is Map<String, dynamic> && app.containsKey('app_name')) {
          appsBindingMap[app['app_name']] = app;
        }
      }

      // Update the session
      for (var app in AppsSession.linkedApps) {
        if (appsBindingMap.containsKey(app.name)) {
          final appData = appsBindingMap[app.name];
          app.isLinked = appData['user_linked'] ?? false;

          if (app.isLinked &&
              appData['user_profile'] != null &&
              appData['user_profile'] is Map) {
            final profile = appData['user_profile'];
            if (app.name == "Spotify") {
              app.userDisplayName =
                  profile['display_name'] ?? "No Display Name";
              if (profile['images'] != null &&
                  profile['images'] is List &&
                  profile['images'].isNotEmpty) {
                app.userPic =
                    profile['images'][0]['url'] ??
                    UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
              } else {
                app.userPic = UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
              }
            } else if (app.name == "YoutubeMusic") {
              app.userDisplayName = profile['name'] ?? "No Display Name";
              app.userPic =
                  profile['picture'] ?? UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
            } else {
              app.userDisplayName = profile['name'] ?? "No Display Name";
              app.userPic =
                  profile['picture'] ?? UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
            }
          } else {
            app.userDisplayName = "User Not Linked";
            app.userPic = UserSession.userPIC ?? UserConstants.defaultAvatarUrl;
          }
        }
      }

      setState(() {}); // Just refresh UI, actual data lives in UserSession now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Apps')),
      backgroundColor: ColorPalette.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(
                    16.0,
                  ), // Adds padding around the content
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centers horizontally
                      children: [
                        TopBar(
                          imageUrl:
                              UserSession.userPIC ??
                              UserConstants.defaultAvatarUrl,
                          userName: UserSession.userNAME ?? "",
                          chainPoints: UserSession.currentChainStreak ?? 0,
                          storePoints: 0,
                          onChainTap: () => NavigationPage.of(context).showChain(),
                        ),
                        SizedBox(height: 50),
                        Container(
                          width: 800,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: ColorPalette.backgroundColor,
                            border: BorderDirectional(
                              bottom: BorderSide(
                                color: ColorPalette.lightGray,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Linked Apps",
                                style: TextStyle(
                                  color: ColorPalette.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GlowingIconButton(
                                  icon: FontAwesomeIcons.arrowsRotate,
                                  iconColor: ColorPalette.white,
                                  iconGlowColor: ColorPalette.gold,
                                  onPressed: _initializeLinkedApps,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ...AppsSession.linkedApps.map((app) {
                          return AppCard(
                            userPic: app.userPic,
                            userDisplayName: app.userDisplayName,
                            isLinked: app.isLinked,
                            appPic: app.appPic,
                            appColor: app.appColor,
                            appParams: app.appButtonParams,
                            appName: app.name,
                            appText: app.buttonText,
                            defaultUserPicUrl: UserConstants.defaultAvatarUrl,
                            defaultAppPicUrl: MusicAppProperties.defaultAppsImageUrl,
                            onReinitializeApps: _initializeLinkedApps,
                          );
                        }),
                        // SizedBox(height: 40),
                        // Align(
                        //   alignment: Alignment.center,
                        //   child: GlowingIconButton(
                        //     iconSize: 48,
                        //     icon: FontAwesomeIcons.userGear,
                        //     iconColor: ColorPalette.white,
                        //     iconGlowColor: ColorPalette.gold,
                        //     onPressed: _initializeLinkedApps,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
