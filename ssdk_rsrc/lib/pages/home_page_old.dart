// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/widgets/adaptive_widgets/appbar.dart';
import 'package:ssdk_rsrc/widgets/adaptive_widgets/buttons.dart';
import 'package:ssdk_rsrc/widgets/adaptive_widgets/icons.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart'; // Ensure the correct path
import 'package:ssdk_rsrc/styles/button_styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Çıkış yapma
              },
            ),
            TextButton(
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(context).pop(true); // Çıkış yapmayı onayla
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Kullanıcının giriş bilgilerini temizle
      AuthService.clearToken();

      // Kullanıcıyı LoginPage'e yönlendir
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptiveAppBar(
        title: Text('Welcome'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ), // Adds padding around the content
          child: Center(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centers horizontally
              children: [
                SizedBox(height: 20), // Adds space from the top
                // CustomButton to Navigate to Button Customizer
                CustomButton(
                  text: "Navigate To\nButton Customizer",
                  onPressed: () {
                    Navigator.pushNamed(context, '/button_customizer');
                  },
                  buttonParams: navigateButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Logout",
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                  buttonParams: logoutButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Linked Apps",
                  onPressed: () {
                    // Implement your logout logic here
                    // For example, navigate back to the login page
                    Navigator.pushNamed(context, '/applinks');
                  },
                  buttonParams: linkedAppsButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Playlists",
                  onPressed: () {
                    // Implement your logout logic here
                    // For example, navigate back to the login page
                    Navigator.pushNamed(context, '/playlists');
                  },
                  buttonParams: playlistButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Player",
                  onPressed: () {
                    // Implement your logout logic here
                    // For example, navigate back to the login page
                    Navigator.pushNamed(context, '/player');
                  },
                  buttonParams: playerButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Timer",
                  onPressed: () {
                    // Implement your logout logic here
                    // For example, navigate back to the login page
                    Navigator.pushNamed(context, '/timer');
                  },
                  buttonParams: timerButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                // CustomButton for Logout
                CustomButton(
                  text: "Custom Timer",
                  onPressed: () {
                    // Implement your logout logic here
                    // For example, navigate back to the login page
                    Navigator.pushNamed(context, '/custom_timer');
                  },
                  buttonParams: timerButtonParams,
                ),
                SizedBox(height: 20), // Adds vertical spacing
                AdaptiveButton(
                  child: Icon(AdaptiveIcons.home),
                  onPressed: () async {
                    await mainAPI.openOurWebSite(context);
                  },
                ),
                // Add more widgets or buttons as needed
              ],
            ),
          ),
        ),
      ),
    );
  }
}
