import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/button_params.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/services/main_api.dart';

class AppCard extends StatelessWidget {
  final String userPic;
  final String userDisplayName;
  final bool isLinked;
  final String appPic;
  final Color appColor;
  final ButtonParams appParams;
  final String appName;
  final String appText;
  final String defaultUserPicUrl;
  final String defaultAppPicUrl;
  final Future<void> Function() onReinitializeApps;

  const AppCard({
    super.key,
    required this.userPic,
    required this.userDisplayName,
    required this.isLinked,
    required this.appPic,
    required this.appColor,
    required this.appParams,
    required this.appName,
    required this.appText,
    required this.defaultUserPicUrl,
    required this.defaultAppPicUrl,
    required this.onReinitializeApps,
  });

  @override
  Widget build(BuildContext context) {
    // Validate the user picture URL; fallback to default if invalid.
    final validUserPic =
        (userPic.isNotEmpty && Uri.tryParse(userPic)?.hasAbsolutePath == true)
            ? userPic
            : defaultUserPicUrl;

    final validAppPic =
        (appPic.isNotEmpty && Uri.tryParse(appPic)?.hasAbsolutePath == true)
            ? appPic
            : defaultAppPicUrl;
    // Set the trailing icon based on the linked state.
    appParams.trailingIcon = isLinked ? Icons.link_off : Icons.link;
    final borderColor = isLinked ? appColor : ColorPalette.lightGray;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(50),
            blurRadius: 30,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        color: ColorPalette.backgroundColor.withOpacity(0.5),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center elements vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center elements horizontally
              children: [
                // Conditionally render user information if the app is linked.
                if (true) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // User profile image (bottom)
                          ClipOval(
                            child: Image.network(
                              validUserPic,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  defaultUserPicUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),

                          // App logo image (top, slightly overlapping)
                          Positioned(
                            left: -10, // or right: -10 to overlap from right
                            top: 0, // adjust as needed for precise overlap
                            child: ClipOval(
                              child: Image.network(
                                validAppPic,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    defaultAppPicUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          userDisplayName.isNotEmpty
                              ? userDisplayName
                              : "Not Linked",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorPalette.white,
                            fontSize: 18,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      CustomButton(
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
                              } else if (appName == "AppleMusic") {
                                await mainAPI.openAppleLogin(context);
                              }
                            }
                            // Reinitialize the app binding state.
                            await onReinitializeApps();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update App link state: $e',
                                ),
                              ),
                            );
                          }
                        },
                        buttonParams: appParams,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
