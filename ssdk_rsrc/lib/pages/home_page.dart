// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ssdk_rsrc/pages/navigation_page.dart';
import 'package:ssdk_rsrc/providers/user_session.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
// ignore: unused_import
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/widgets/chain_step.dart';
// ignore: unused_import
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/widgets/custom_staus_bar.dart';
import 'package:ssdk_rsrc/widgets/glowing_icon.dart';
import 'package:ssdk_rsrc/widgets/glowing_text.dart';
import 'package:ssdk_rsrc/widgets/top_bar.dart';
import 'package:ssdk_rsrc/utils/util.dart';
import 'package:showcaseview/showcaseview.dart'; // <-- Import this
import 'dart:async';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      // <-- wrap here!
      builder: (showcaseContext) => HomePageBody(),
    );
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  HomePageBodyState createState() => HomePageBodyState();
}

class HomePageBodyState extends State<HomePageBody> {
  String currentDay = "";
  DateTime currentDate = DateTime.now();
  int activeStep = 0;
  bool showcase = false;

  // Showcase Keys
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _bigChainKey = GlobalKey();
  final GlobalKey _pomodoroKey = GlobalKey();
  final GlobalKey _playBtnKey = GlobalKey();
  final GlobalKey _settingsBtnKey = GlobalKey();
  final GlobalKey _addBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeUserPic();
    initilazeCurrentDay();
    _initializeChainStreak();

    // Trigger showcase after first frame (can check for first launch)
    if (showcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          _profileKey,
          _bigChainKey,
          _pomodoroKey,
          _playBtnKey,
          _settingsBtnKey,
          _addBtnKey,
        ]);
      });
    }
  }

  Future<void> _initializeChainStreak() async {
    try {
      final result = await mainAPI.getChainStatus();
      final streak = result['chain_streak'] ?? 0;
      setState(() {
        UserSession.currentChainStreak = streak;
      });
    } catch (e) {
      setState(() {
        UserSession.currentChainStreak = 0;
      });
    }
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
        UserSession.userPIC = validUserPic;
        UserSession.userNAME = userName;
      });
    } catch (e) {
      print("Error fetching user profile: $e");
      setState(() {
        UserSession.userPIC = UserConstants.defaultAvatarUrl;
      });
    }
  }

  void initilazeCurrentDay() {
    final (currentDayOfWeek, currentDateTime) = getCurrentDayName();
    setState(() {
      currentDay = currentDayOfWeek;
      currentDate = currentDateTime;
      activeStep = currentDate.weekday;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onLongPressEnd: (details) {
            print("123");
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Showcase(
                            key: _profileKey,
                            title: "Profile",
                            description:
                                "See your profile picture and name here.",
                            child: TopBar(
                              imageUrl:
                                  UserSession.userPIC ??
                                  UserConstants.defaultAvatarUrl,
                              userName: UserSession.userNAME ?? "",
                              chainPoints:
                                  UserSession.currentChainStreak ??
                                  0, // <--- UPDATED
                              storePoints: 0,
                              onChainTap: () => NavigationPage.of(context).showChain(),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Showcase(
                                    key: _bigChainKey,
                                    title: "Progress Chain",
                                    description:
                                        "Track your weekly progress here.",
                                    child: Container(
                                      width: 300,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: ColorPalette.white.withAlpha(
                                              50,
                                            ),
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
                                        border: Border.all(
                                          color: Transparent.a22,
                                        ),
                                      ),
                                      child: Center(
                                        child: CustomChainStepProgress(
                                          steps: 7,
                                          activeStep: activeStep,
                                          iconSize: 70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  GlowingText(
                                    text: currentDay,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.white,
                                    glowColor: ColorPalette.gold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/timer');
                            },
                            child: Container(
                              clipBehavior: Clip.none,
                              child: Column(
                                children: [
                                  Showcase(
                                    key: _pomodoroKey,
                                    title: "Pomodoro Timer",
                                    description:
                                        "Your main focus timer appears here.",
                                    child: Container(
                                      width: 500,
                                      height: 350,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: ColorPalette.white.withAlpha(
                                              50,
                                            ),
                                            blurRadius: 30,
                                            offset: Offset(0, -10),
                                          ),
                                          BoxShadow(
                                            color: ColorPalette.almostBlack,
                                            blurRadius: 30,
                                            offset: Offset(0, 10),
                                          ),
                                          BoxShadow(
                                            color: ColorPalette.backgroundColor,
                                            blurRadius: 10,
                                            offset: Offset(0, 30),
                                          ),
                                        ],
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        color: ColorPalette.backgroundColor,
                                        border: BorderDirectional(
                                          top: BorderSide(
                                            color: ColorPalette.gold,
                                          ),
                                          start: BorderSide(
                                            color: ColorPalette.gold,
                                          ),
                                          end: BorderSide(
                                            color: ColorPalette.gold,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Pomodoro",
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w300,
                                                  color: ColorPalette.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              GlowingText(
                                                text: "25:00",
                                                fontSize: 48,
                                                fontWeight: FontWeight.w300,
                                                color: ColorPalette.white,
                                                glowColor: ColorPalette.gold,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CustomStatusBar(
                                                stepCount: 4,
                                                currentStep: 0,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 50),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Showcase(
                                                key: _playBtnKey,
                                                title: "Start Focus",
                                                description:
                                                    "Start your Pomodoro session.",
                                                child: GlowingIconButton(
                                                  onPressed: () {Navigator.pushNamed(context, '/timer');},
                                                  icon: FontAwesomeIcons.play,
                                                  iconColor:
                                                      ColorPalette
                                                          .backgroundColor,
                                                  iconGlowColor:
                                                      ColorPalette.gold,
                                                  iconSize: 48,
                                                ),
                                              ),
                                              SizedBox(width: 100),
                                              Showcase(
                                                key: _settingsBtnKey,
                                                title: "Settings",
                                                description:
                                                    "Access more features and settings.",
                                                child: GlowingIconButton(
                                                  onPressed: () {Navigator.pushNamed(context, '/timer');},
                                                  icon: FontAwesomeIcons.gear,
                                                  iconColor:
                                                      ColorPalette
                                                          .backgroundColor,
                                                  iconGlowColor:
                                                      ColorPalette.gold,
                                                  iconSize: 48,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Showcase(
                                  //   key: _addBtnKey,
                                  //   title: "Add Button",
                                  //   description:
                                  //       "Create a new task or goal here.",
                                  //   child: GlowingIconButton(
                                  //     onPressed: () {
                                  //       showGeneralDialog(
                                  //         context: context,
                                  //         barrierLabel: '',
                                  //         barrierDismissible: true,
                                  //         barrierColor: Transparent.a77,
                                  //         transitionDuration: const Duration(
                                  //           milliseconds: 300,
                                  //         ),
                                  //         pageBuilder: (_, __, ___) {
                                  //           return SafeArea(
                                  //             child: Scaffold(
                                  //               backgroundColor:
                                  //                   Transparent.a00,
                                  //               body: Center(
                                  //                 child: Container(
                                  //                   margin:
                                  //                       const EdgeInsets.symmetric(
                                  //                         horizontal: 3,
                                  //                         vertical: 3,
                                  //                       ),
                                  //                   padding:
                                  //                       const EdgeInsets.all(3),
                                  //                   decoration: BoxDecoration(
                                  //                     color:
                                  //                         ColorPalette
                                  //                             .backgroundColor,
                                  //                     borderRadius:
                                  //                         BorderRadius.circular(
                                  //                           12,
                                  //                         ),
                                  //                     boxShadow: [
                                  //                       BoxShadow(
                                  //                         color:
                                  //                             ColorPalette.gold,
                                  //                       ),
                                  //                     ],
                                  //                   ),
                                  //                   child: Column(
                                  //                     mainAxisSize:
                                  //                         MainAxisSize.min,
                                  //                     children: [
                                  //                       Row(
                                  //                         mainAxisSize:
                                  //                             MainAxisSize.max,
                                  //                         mainAxisAlignment:
                                  //                             MainAxisAlignment
                                  //                                 .spaceBetween,
                                  //                         children: [
                                  //                           GlowingIconButton(
                                  //                             onPressed: () {},
                                  //                             icon:
                                  //                                 FontAwesomeIcons
                                  //                                     .borderNone,
                                  //                             iconColor:
                                  //                                 Transparent
                                  //                                     .a00,
                                  //                             iconGlowColor:
                                  //                                 Transparent
                                  //                                     .a00,
                                  //                           ),
                                  //                           Expanded(
                                  //                             child: Text(
                                  //                               'Pick Your Preset!',
                                  //                               textAlign:
                                  //                                   TextAlign
                                  //                                       .center,
                                  //                               style: TextStyle(
                                  //                                 fontSize: 20,
                                  //                                 fontWeight:
                                  //                                     FontWeight
                                  //                                         .bold,
                                  //                                 color:
                                  //                                     ColorPalette
                                  //                                         .white,
                                  //                               ),
                                  //                             ),
                                  //                           ),
                                  //                           // Your “X” button stays at the right edge
                                  //                           CustomButton(
                                  //                             text: "",
                                  //                             buttonParams:
                                  //                                 closeButtonParams,
                                  //                             onPressed: () {
                                  //                               Navigator.of(
                                  //                                 context,
                                  //                               ).pop();
                                  //                             },
                                  //                           ),
                                  //                         ],
                                  //                       ),
                                  //                       SizedBox(height: 50),
                                  //                       Column(
                                  //                         children: [
                                  //                           ElevatedButton(
                                  //                             style: ElevatedButton.styleFrom(
                                  //                               fixedSize: Size(
                                  //                                 250,
                                  //                                 75,
                                  //                               ),
                                  //                               elevation:
                                  //                                   0, // Avoid double shadows when using BoxShadow
                                  //                               shadowColor:
                                  //                                   ColorPalette
                                  //                                       .gold,
                                  //                               shape: RoundedRectangleBorder(
                                  //                                 borderRadius:
                                  //                                     BorderRadius.circular(
                                  //                                       16,
                                  //                                     ),
                                  //                               ),
                                  //                               side: BorderSide(
                                  //                                 color:
                                  //                                     ColorPalette
                                  //                                         .gold,
                                  //                                 width: 1,
                                  //                               ),
                                  //                               backgroundColor:
                                  //                                   ColorPalette
                                  //                                       .backgroundColor, // Make background transparent
                                  //                             ),
                                  //                             onPressed: () {},
                                  //                             child: Row(
                                  //                               mainAxisSize:
                                  //                                   MainAxisSize
                                  //                                       .max,
                                  //                               mainAxisAlignment:
                                  //                                   MainAxisAlignment
                                  //                                       .spaceBetween,
                                  //                               crossAxisAlignment:
                                  //                                   CrossAxisAlignment
                                  //                                       .center,
                                  //                               children: [
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .chessKing,
                                  //                                   iconColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                   iconGlowColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                 ),
                                  //                                 Text(
                                  //                                   "25' Work / 5' Rest",
                                  //                                   textAlign:
                                  //                                       TextAlign
                                  //                                           .center,
                                  //                                   style: TextStyle(
                                  //                                     color:
                                  //                                         ColorPalette
                                  //                                             .white,
                                  //                                     fontSize:
                                  //                                         14,
                                  //                                   ),
                                  //                                 ),
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .borderNone,
                                  //                                   iconColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                   iconGlowColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                 ),
                                  //                               ],
                                  //                             ),
                                  //                           ),
                                  //                           const SizedBox(
                                  //                             height: 50,
                                  //                           ),
                                  //                           ElevatedButton(
                                  //                             style: ElevatedButton.styleFrom(
                                  //                               fixedSize: Size(
                                  //                                 250,
                                  //                                 75,
                                  //                               ),
                                  //                               elevation:
                                  //                                   0, // Avoid double shadows when using BoxShadow
                                  //                               shadowColor:
                                  //                                   ColorPalette
                                  //                                       .gold,
                                  //                               shape: RoundedRectangleBorder(
                                  //                                 borderRadius:
                                  //                                     BorderRadius.circular(
                                  //                                       16,
                                  //                                     ),
                                  //                               ),
                                  //                               side: BorderSide(
                                  //                                 color:
                                  //                                     ColorPalette
                                  //                                         .gold,
                                  //                                 width: 1,
                                  //                               ),
                                  //                               backgroundColor:
                                  //                                   ColorPalette
                                  //                                       .backgroundColor, // Make background transparent
                                  //                             ),
                                  //                             onPressed: () {},
                                  //                             child: Row(
                                  //                               mainAxisSize:
                                  //                                   MainAxisSize
                                  //                                       .max,
                                  //                               mainAxisAlignment:
                                  //                                   MainAxisAlignment
                                  //                                       .spaceBetween,
                                  //                               crossAxisAlignment:
                                  //                                   CrossAxisAlignment
                                  //                                       .center,
                                  //                               children: [
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .chessBishop,
                                  //                                   iconColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                   iconGlowColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                 ),
                                  //                                 Text(
                                  //                                   "40' Work / 10' Rest",
                                  //                                   textAlign:
                                  //                                       TextAlign
                                  //                                           .center,
                                  //                                   style: TextStyle(
                                  //                                     color:
                                  //                                         ColorPalette
                                  //                                             .white,
                                  //                                     fontSize:
                                  //                                         14,
                                  //                                   ),
                                  //                                 ),
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .borderNone,
                                  //                                   iconColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                   iconGlowColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                 ),
                                  //                               ],
                                  //                             ),
                                  //                           ),
                                  //                           const SizedBox(
                                  //                             height: 50,
                                  //                           ),
                                  //                           ElevatedButton(
                                  //                             style: ElevatedButton.styleFrom(
                                  //                               fixedSize: Size(
                                  //                                 250,
                                  //                                 75,
                                  //                               ),
                                  //                               elevation:
                                  //                                   0, // Avoid double shadows when using BoxShadow
                                  //                               shadowColor:
                                  //                                   ColorPalette
                                  //                                       .gold,
                                  //                               shape: RoundedRectangleBorder(
                                  //                                 borderRadius:
                                  //                                     BorderRadius.circular(
                                  //                                       16,
                                  //                                     ),
                                  //                               ),
                                  //                               side: BorderSide(
                                  //                                 color:
                                  //                                     ColorPalette
                                  //                                         .gold,
                                  //                                 width: 1,
                                  //                               ),
                                  //                               backgroundColor:
                                  //                                   ColorPalette
                                  //                                       .backgroundColor, // Make background transparent
                                  //                             ),
                                  //                             onPressed: () {},
                                  //                             child: Row(
                                  //                               mainAxisSize:
                                  //                                   MainAxisSize
                                  //                                       .max,
                                  //                               mainAxisAlignment:
                                  //                                   MainAxisAlignment
                                  //                                       .spaceBetween,
                                  //                               crossAxisAlignment:
                                  //                                   CrossAxisAlignment
                                  //                                       .center,
                                  //                               children: [
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .chessKnight,
                                  //                                   iconColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                   iconGlowColor:
                                  //                                       ColorPalette
                                  //                                           .white,
                                  //                                 ),
                                  //                                 Text(
                                  //                                   "Custom Settings",
                                  //                                   textAlign:
                                  //                                       TextAlign
                                  //                                           .center,
                                  //                                   style: TextStyle(
                                  //                                     color:
                                  //                                         ColorPalette
                                  //                                             .white,
                                  //                                     fontSize:
                                  //                                         14,
                                  //                                   ),
                                  //                                 ),
                                  //                                 GlowingIconButton(
                                  //                                   onPressed:
                                  //                                       () {},
                                  //                                   icon:
                                  //                                       FontAwesomeIcons
                                  //                                           .borderNone,
                                  //                                   iconColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                   iconGlowColor:
                                  //                                       Transparent
                                  //                                           .a00,
                                  //                                 ),
                                  //                               ],
                                  //                             ),
                                  //                           ),
                                  //                           const SizedBox(
                                  //                             height: 50,
                                  //                           ),
                                  //                         ],
                                  //                       ),
                                  //                     ],
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           );
                                  //         },
                                  //       );
                                  //     },
                                  //     icon: FontAwesomeIcons.circlePlus,
                                  //     iconColor: ColorPalette.backgroundColor,
                                  //     iconGlowColor: ColorPalette.gold,
                                  //     iconSize: 300,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}
