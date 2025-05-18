import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/providers/userSession.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/widgets/chain_step.dart';
import 'package:ssdk_rsrc/widgets/top_bar.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int activeStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeUserPic();
  }

  Future<void> _initializeUserPic() async {
    try {
      final userId = await AuthService.getUserId();
      UserSession.userID = userId;
      UserSession.userPIC;
      UserSession.userNAME;

      // Await the user info response.
      final userInfo = await mainAPI.getUserProfile();

      // Get avatar_url from API response.
      final userPic = userInfo['avatar_url'] as String? ?? '';
      final userName = userInfo['first_name'] as String? ?? '';

      // Validate URL, use default if empty or invalid.
      final validUserPic =
          (userPic.isNotEmpty && Uri.tryParse(userPic)?.hasAbsolutePath == true)
              ? userPic
              : UserConstants.defaultAvatarUrl;

      setState(() {
        UserSession.userPIC =
            validUserPic; // This should be your state variable for the avatar URL.
        UserSession.userNAME =
            userName; // This should be your state variable for the avatar URL.
      });
    } catch (e) {
      print("Error fetching user profile: $e");
      setState(() {
        UserSession.userPIC = UserConstants.defaultAvatarUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('', style: TextStyle(color: Youtube.white)),
      //   backgroundColor: ColorPalette.backgroundColor,
      //   centerTitle: true,
      //   automaticallyImplyLeading: false, // Removes the back button
      // ),
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
                          chainPoints: 0,
                          storePoints: 0,
                        ),
                        SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 300,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorPalette.white.withAlpha(50),
                                        blurRadius: 30,
                                        offset: Offset(0, -10),
                                      ),
                                      BoxShadow(
                                        color: ColorPalette.almostBlack,
                                        blurRadius: 30,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                    color: ColorPalette.backgroundColor,
                                    border: Border.all(color: Transparent.a22),
                                  ),
                                  child: Center(
                                    child: CustomChainStepProgress(
                                      steps: 7,
                                      activeStep: activeStep,
                                      iconSize: 70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
