import 'package:flutter/material.dart';
import '../presenter/timer_presenter.dart';
import '../router/timer_router.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late final TimerPresenter presenter;
  late final TimerRouter router;

  @override
  void initState() {
    super.initState();
    presenter = TimerPresenter();
    router = TimerRouter();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final minutes = presenter.remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = presenter.remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$minutes:$seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (presenter.isRunning) {
                  presenter.stop();
                } else {
                  presenter.start(const Duration(minutes: 25), _update, _update);
                }
                setState(() {});
              },
              child: Text(presenter.isRunning ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => router.openCustomTimer(context),
              child: const Text('Custom Timer'),
            ),
          ],
        ),
      ),
    );
  }
}
