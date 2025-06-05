import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../presenter/overlay_tutorial_presenter.dart';
import '../router/overlay_tutorial_router.dart';

class OverlayTutorialView extends StatefulWidget {
  const OverlayTutorialView({Key? key}) : super(key: key);

  @override
  State<OverlayTutorialView> createState() => _OverlayTutorialViewState();
}

class _OverlayTutorialViewState extends State<OverlayTutorialView> {
  late final OverlayTutorialPresenter presenter;
  late final OverlayTutorialRouter router;

  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _registerBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    presenter = OverlayTutorialPresenter();
    router = OverlayTutorialRouter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([
        _emailKey,
        _passwordKey,
        _registerBtnKey,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Page')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Showcase(
              key: _emailKey,
              description: 'Enter your email address here.',
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Showcase(
              key: _passwordKey,
              description: 'Choose a secure password.',
              child: const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Showcase(
              key: _registerBtnKey,
              description: 'Tap here to create your account!',
              child: ElevatedButton(
                onPressed: () async {
                  await presenter.finishTutorial();
                  router.close(context);
                },
                child: const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
