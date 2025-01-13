import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'models/button_params.dart';
import 'models/linked_app.dart';
import 'widgets/app_card.dart';
import 'authlib.dart';
import '/api_service.dart';


class AppLinks extends StatefulWidget {
  const AppLinks({super.key});

  @override
  AppLinksState createState() => AppLinksState();
}

class AppLinksState extends State<AppLinks> with WidgetsBindingObserver {
  final String defaultUserPicUrl = "https://sync-branch.yggbranch.dev/assets/default_user.png";

  // Define a list of apps
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

  Future<Map<String, dynamic>?> checkLinkedApp(ButtonParams customButton, String? email, String appName) async {
  try {
    final response = await mainAPI.checkLinkedApp(email, appName); // Assuming ApiService() has a method for this
    if (response['error'] == true) {
      return null;
    } else {
      final userLinked = response['user_linked'];
      final userDisplayName = response['user_profile']['display_name'] ?? "No Display Name";
      final userPic = response['user_profile']['images'][0]['url'] ?? "";
      return {
        'userLinked': userLinked,
        'userDisplayName': userDisplayName,
        'userPic': userPic,
      };
    }
  } catch (e) {
    debugPrint('Error in checkLinkedApp: $e');
    return null;
  }
}

  Future<void> _initializeLinkedApps() async {
    final userId = await AuthService.getUserId();

    // Update the state of each app
    for (var app in linkedApps) {
      final result = await checkLinkedApp(ButtonParams(), userId, app.name);
      setState(() {
        app.isLinked = result?['userLinked'] ?? false;
        app.buttonText = app.isLinked ? "Unlink ${app.name}" : "Link ${app.name}";
        app.userPic = result?['userPic'] ?? defaultUserPicUrl;
        app.userDisplayName = result?['userDisplayName'] ?? "No Display Name";
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
                    defaultUserPicUrl: defaultUserPicUrl,
                    onReinitializeApps: _initializeLinkedApps,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}