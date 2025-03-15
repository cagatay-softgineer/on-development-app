import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/models/button_params.dart';
import 'package:ssdk_rsrc/models/linked_app.dart';
import 'package:ssdk_rsrc/widgets/app_card.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/services/api_service.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';


class AppLinkPage extends StatefulWidget {
  const AppLinkPage({super.key});

  @override
  AppLinkPageState createState() => AppLinkPageState();
}

class AppLinkPageState extends State<AppLinkPage> with WidgetsBindingObserver {

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
      if (appName == "Spotify"){
        final userDisplayName = response['user_profile']['display_name'] ?? "No Display Name";
        final userPic = response['user_profile']['images'][0]['url'] ?? "";
        return {
          'userLinked': userLinked,
          'userDisplayName': userDisplayName,
          'userPic': userPic,
        };
      } else if (appName == "AppleMusic"){
        // Implement AppleMusic specific logic here
      } else if (appName == "YoutubeMusic"){
        final userDisplayName = response['user_profile']['name'] ?? "No Display Name";
        final userPic = response['user_profile']['picture'] ?? "";
        return {
          'userLinked': userLinked,
          'userDisplayName': userDisplayName,
          'userPic': userPic,
        };
      } 
    }
  } catch (e) {
    debugPrint('Error in checkLinkedApp: $e');
    return null;
  }
  return null;
}

  Future<void> _initializeLinkedApps() async {
    final userId = await AuthService.getUserId();

    // Update the state of each app
    for (var app in linkedApps) {
      final result = await checkLinkedApp(ButtonParams(), userId, app.name);
      setState(() {
        app.isLinked = result?['userLinked'] ?? false;
        app.buttonText = app.isLinked ? "Unlink ${app.name}" : "Link ${app.name}";
        app.userPic = result?['userPic'] ?? UserConstants.defaultAvatarUrl;
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