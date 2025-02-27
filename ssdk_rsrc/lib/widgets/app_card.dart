import 'package:flutter/material.dart';
import '/models/button_params.dart';
import '/widgets/custom_button.dart';
import '/api_service.dart';
import '/authlib.dart';

class AppCard extends StatelessWidget {
  final String userPic;
  final String userDisplayName;
  final bool isLinked;
  final ButtonParams appParams;
  final String appName;
  final String appText;
  final String defaultUserPicUrl;
  final Future<void> Function() onReinitializeApps;

  const AppCard({
    Key? key,
    required this.userPic,
    required this.userDisplayName,
    required this.isLinked,
    required this.appParams,
    required this.appName,
    required this.appText,
    required this.defaultUserPicUrl,
    required this.onReinitializeApps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure valid userPic URL
    final validUserPic = (userPic.isNotEmpty && Uri.tryParse(userPic)?.hasAbsolutePath == true)
        ? userPic
        : defaultUserPicUrl;
    appParams.trailingIcon = isLinked ? Icons.link_off : Icons.link;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center elements vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center elements horizontally
            children: [
              // Conditionally render user info only if the app is linked
              if (isLinked) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center elements horizontally
                  children: [
                    Image.network(
                      validUserPic, // Use the validated URL
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          defaultUserPicUrl, // Fallback to the default image
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        userDisplayName.isNotEmpty ? userDisplayName : "No Display Name",
                        textAlign: TextAlign.center, // Center-align text
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Always render the button
              Center(
                child: CustomButton(
                  text: appText,
                  onPressed: () async {
                    try {
                      // Fetch current link state
                      final userId = await AuthService.getUserId();
                      final result = await mainAPI.checkLinkedApp(userId, appName);

                      final isLinked = result['user_linked'] ?? false;

                      // Handle linking or unlinking
                      if (isLinked) {
                        await mainAPI.unlinkApp(appName);
                      } else {
                        if (appName == "Spotify") {
                          await mainAPI.openSpotifyLogin(context);
                        }
                      }

                      // Reinitialize the linked apps state
                      await onReinitializeApps();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update App link state: $e'),
                        ),
                      );
                    }
                  },
                  buttonParams: appParams,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
