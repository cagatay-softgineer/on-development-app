import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/models/linked_app.dart';
import 'package:ssdk_rsrc/widgets/app_card.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';

class AppLinkPage extends StatefulWidget {
  const AppLinkPage({Key? key}) : super(key: key);

  @override
  AppLinkPageState createState() => AppLinkPageState();
}

class AppLinkPageState extends State<AppLinkPage> with WidgetsBindingObserver {
  // Define a list of apps with initial configurations.
  final List<LinkedApp> linkedApps = [
    LinkedApp(name: "Spotify", appButtonParams: spotifyButtonParams),
    LinkedApp(name: "AppleMusic", appButtonParams: appleMusicButtonParams),
    LinkedApp(name: "YoutubeMusic", appButtonParams: youtubeMusicButtonParams),
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
            app.buttonText = app.isLinked ? "Unlink ${app.name}" : "Link ${app.name}";

            if (app.isLinked &&
                appData['user_profile'] != null &&
                appData['user_profile'] is Map) {
              final profile = appData['user_profile'];
              if (app.name == "Spotify") {
                app.userDisplayName = profile['display_name'] ?? "No Display Name";
                if (profile['images'] != null &&
                    profile['images'] is List &&
                    profile['images'].isNotEmpty) {
                  app.userPic = profile['images'][0]['url'] ?? UserConstants.defaultAvatarUrl;
                } else {
                  app.userPic = UserConstants.defaultAvatarUrl;
                }
              } else if (app.name == "YoutubeMusic") {
                app.userDisplayName = profile['name'] ?? "No Display Name";
                app.userPic = profile['picture'] ?? UserConstants.defaultAvatarUrl;
              } else {
                // For AppleMusic or other apps, adjust the logic as necessary.
                app.userDisplayName = "No Display Name";
                app.userPic = UserConstants.defaultAvatarUrl;
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
      appBar: AppBar(title: const Text('Apps')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'Apps',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...linkedApps.map((app) {
                  return AppCard(
                    userPic: app.userPic,
                    userDisplayName: app.userDisplayName,
                    isLinked: app.isLinked,
                    appParams: app.appButtonParams,
                    appName: app.name,
                    appText: app.buttonText,
                    defaultUserPicUrl: UserConstants.defaultAvatarUrl,
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
