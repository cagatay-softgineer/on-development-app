import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/userSession.dart';
import '../../../widgets/app_card.dart';
import '../../../constants/default/user.dart';
import '../../../constants/default/apps.dart';
import '../../../styles/color_palette.dart';
import '../../../widgets/glowing_icon.dart';
import '../../../widgets/top_bar.dart';
import '../presenter/app_links_presenter.dart';
import '../router/app_links_router.dart';

class AppLinksView extends StatefulWidget {
  const AppLinksView({Key? key}) : super(key: key);

  @override
  State<AppLinksView> createState() => _AppLinksViewState();
}

class _AppLinksViewState extends State<AppLinksView> with WidgetsBindingObserver {
  late final AppLinksPresenter presenter;
  late final AppLinksRouter router;

  @override
  void initState() {
    super.initState();
    presenter = AppLinksPresenter();
    router = AppLinksRouter();
    presenter.initializeLinkedApps().then((_) => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      presenter.initializeLinkedApps().then((_) => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: SafeArea(
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
                        TopBar(
                          imageUrl: UserSession.userPIC ??
                              UserConstants.defaultAvatarUrl,
                          userName: UserSession.userNAME ?? '',
                          chainPoints: UserSession.currentChainStreak ?? 0,
                          storePoints: 0,
                          onChainTap: () => router.showChain(context),
                        ),
                        const SizedBox(height: 50),
                        Container(
                          width: 800,
                          decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: ColorPalette.backgroundColor,
                            border: BorderDirectional(
                              bottom: BorderSide(
                                color: ColorPalette.lightGray,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Linked Apps',
                                style: TextStyle(
                                  color: ColorPalette.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GlowingIconButton(
                                  icon: FontAwesomeIcons.arrowsRotate,
                                  iconColor: ColorPalette.white,
                                  iconGlowColor: ColorPalette.gold,
                                  onPressed: () async {
                                    await presenter.initializeLinkedApps();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...presenter.linkedApps.map((app) {
                          return AppCard(
                            userPic: app.userPic,
                            userDisplayName: app.userDisplayName,
                            isLinked: app.isLinked,
                            appPic: app.appPic,
                            appColor: app.appColor,
                            appParams: app.appButtonParams,
                            appName: app.name,
                            appText: app.buttonText,
                            defaultUserPicUrl: UserConstants.defaultAvatarUrl,
                            defaultAppPicUrl: AppsConstants.defaultAppsUrl,
                            onReinitializeApps: () async {
                              await presenter.initializeLinkedApps();
                              setState(() {});
                            },
                          );
                        }),
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
