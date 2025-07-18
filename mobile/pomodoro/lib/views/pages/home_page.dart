import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pomodoro/views/pages/navigation_page.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pomodoro/viewmodels/home_viewmodel.dart';
import 'package:pomodoro/resources/themes.dart';
import 'package:pomodoro/widgets/components/top_bar.dart';
import 'package:pomodoro/widgets/text/glowing_text.dart';
import 'package:pomodoro/widgets/bar/chain_step.dart';
import 'package:pomodoro/core/constants/user.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder:
          (ctx) => ChangeNotifierProvider(
            create: (_) => HomeViewModel(),
            child: const HomePageBody(),
          ),
    );
  }
}

class HomePageBody extends StatelessWidget {
  const HomePageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        // Prepare showcase keys
        final profileKey = GlobalKey();
        final chainKey = GlobalKey();
        final pomodoroKey = GlobalKey();
        final playBtnKey = GlobalKey();
        final settingsKey = GlobalKey();

        if (vm.enableShowcase) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ShowCaseWidget.of(context).startShowCase([
              profileKey,
              chainKey,
              pomodoroKey,
              playBtnKey,
              settingsKey,
            ]);
            vm.enableShowcase = false; // disable after first run
          });
        }

        return Scaffold(
          backgroundColor: ColorPalette.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Showcase(
                      key: profileKey,
                      title: 'Profile',
                      description: 'See your profile picture and name here.',
                      child: TopBar(
                        imageUrl: vm.userPic ?? UserConstants.defaultAvatarUrl,
                        userName: vm.userName ?? '',
                        chainPoints: vm.chainStreak,
                        storePoints: 0,
                        onChainTap:
                            () => {
                              print("Clicked!"),
                              NavigationPage.of(context).showChain(),
                            },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Showcase(
                      key: chainKey,
                      title: 'Progress Chain',
                      description: 'Track your weekly progress here.',
                      child: CustomChainStepProgress(
                        steps: 7,
                        activeStep: vm.activeStep,
                        iconSize: 70,
                      ),
                    ),
                    GlowingText(
                      text: vm.currentDay,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.white,
                      glowColor: ColorPalette.gold,
                    ),
                    const SizedBox(height: 20),
                    Showcase(
                      key: pomodoroKey,
                      title: 'Pomodoro Timer',
                      description: 'Your main focus timer appears here.',
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/timer'),
                        child: Container(
                          width: 300,
                          height: 350,
                          decoration: BoxDecoration(
                            color: ColorPalette.backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: BorderDirectional(
                              top: BorderSide(color: ColorPalette.gold),
                              start: BorderSide(color: ColorPalette.gold),
                              end: BorderSide(color: ColorPalette.gold),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pomodoro',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: ColorPalette.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Showcase(
                          key: playBtnKey,
                          title: 'Start Focus',
                          description: 'Start your Pomodoro session.',
                          child: IconButton(
                            icon: Icon(
                              FontAwesomeIcons.circlePlay,
                              size: 48,
                              color: ColorPalette.gold,
                            ),
                            onPressed:
                                () => Navigator.pushNamed(context, '/timer'),
                          ),
                        ),
                        const SizedBox(width: 50),
                        Showcase(
                          key: settingsKey,
                          title: 'Settings',
                          description: 'Access more features and settings.',
                          child: IconButton(
                            icon: Icon(
                              FontAwesomeIcons.gear,
                              size: 48,
                              color: ColorPalette.gold,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
