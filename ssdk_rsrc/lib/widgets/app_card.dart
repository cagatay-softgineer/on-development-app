import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/button_params.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/services/main_api.dart';

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
    // Validate the user picture URL; fallback to default if invalid.
    final validUserPic = (userPic.isNotEmpty && Uri.tryParse(userPic)?.hasAbsolutePath == true)
        ? userPic
        : defaultUserPicUrl;
    // Set the trailing icon based on the linked state.
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
              // Conditionally render user information if the app is linked.
              if (isLinked) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      validUserPic,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          defaultUserPicUrl,
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
                        textAlign: TextAlign.center,
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
              // Render the action button.
              Center(
                child: CustomButton(
                  text: appText,
                  onPressed: () async {
                    try {
                      // Use the provided isLinked state to decide on linking or unlinking.
                      if (isLinked) {
                        await mainAPI.unlinkApp(appName);
                      } else {
                        // Open the corresponding login flow based on the app.
                        if (appName == "Spotify") {
                          await mainAPI.openSpotifyLogin(context);
                        } else if (appName == "YoutubeMusic") {
                          await mainAPI.openGoogleLogin(context);
                        }
                      }
                      // Reinitialize the app binding state.
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
