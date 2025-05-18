import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/models/linked_app.dart';
import 'package:ssdk_rsrc/widgets/app_card.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/constants/default/apps.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';

class AppLinkPage extends StatefulWidget {
  const AppLinkPage({Key? key}) : super(key: key);

  @override
  AppLinkPageState createState() => AppLinkPageState();
}

class AppLinkPageState extends State<AppLinkPage> with WidgetsBindingObserver {
  // Define a list of apps with initial configurations.
  final List<LinkedApp> linkedApps = [
    LinkedApp(
      name: "Spotify",
      appButtonParams: spotifyButtonParams,
      appPic:
          "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png",
    ),
    LinkedApp(
      name: "AppleMusic",
      appButtonParams: appleMusicButtonParams,
      appPic:
          "https://play-lh.googleusercontent.com/mOkjjo5Rzcpk7BsHrsLWnqVadUK1FlLd2-UlQvYkLL4E9A0LpyODNIQinXPfUMjUrbE=w240-h480-rw",
    ),
    LinkedApp(
      name: "YoutubeMusic",
      appButtonParams: youtubeMusicButtonParams,
      appPic:
          "https://upload.wikimedia.org/wikipedia/commons/d/d8/YouTubeMusic_Logo.png",
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

    final response = await mainAPI.getAllAppsBinding(userEmail);

    // ignore: unnecessary_null_comparison
    if (response != null && response.containsKey('apps')) {
      // Create a mapping of app name to its binding data for ease of lookup.
      final Map<String, dynamic> appsBindingMap = {};
      for (var app in response['apps']) {
        if (app is Map<String, dynamic> && app.containsKey('app_name')) {
          appsBindingMap[app['app_name']] = app;
        }
      }

      setState(() {
        for (var app in linkedApps) {
          if (appsBindingMap.containsKey(app.name)) {
            final appData = appsBindingMap[app.name];
            app.isLinked = appData['user_linked'] ?? false;
            // app.buttonText = app.isLinked ? "Unlink ${app.name}" : "Link ${app.name}";

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
                      UserConstants.defaultAvatarUrl;
                } else {
                  app.userPic = UserConstants.defaultAvatarUrl;
                }
              } else if (app.name == "YoutubeMusic") {
                app.userDisplayName = profile['name'] ?? "No Display Name";
                app.userPic =
                    profile['picture'] ?? UserConstants.defaultAvatarUrl;
              } else {
                // For AppleMusic or other apps, adjust the logic as necessary.
                app.userDisplayName = profile['name'] ?? "No Display Name";
                app.userPic =
                    profile['picture'] ?? UserConstants.defaultAvatarUrl;
              }
            } else {
              // Reset user information when the app is not linked.
              app.userDisplayName = "No Display Name";
              app.userPic = UserConstants.defaultAvatarUrl;
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Apps')),
      backgroundColor: ColorPalette.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                // const Text(
                //   'Apps',
                //   style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                // ),
                const SizedBox(height: 40),

                Image(
                  color: ColorPalette.gold,
                  colorBlendMode: BlendMode.srcIn,
                  width: 200,
                  height: 200,
                  image: const NetworkImage(
                    "https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Aurevia/PNG/Asset%201_1.png",
                  ),
                ),

                ...linkedApps.map((app) {
                  return AppCard(
                    userPic: app.userPic,
                    userDisplayName: app.userDisplayName,
                    isLinked: app.isLinked,
                    appPic: app.appPic,
                    appParams: app.appButtonParams,
                    appName: app.name,
                    appText: app.buttonText,
                    defaultUserPicUrl: UserConstants.defaultAvatarUrl,
                    defaultAppPicUrl: AppsConstants.defaultAppsUrl,
                    onReinitializeApps: _initializeLinkedApps,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
