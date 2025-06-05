import 'package:flutter/material.dart';
import '../presenter/custom_timer_presenter.dart';
import '../router/custom_timer_router.dart';

class CustomTimerView extends StatefulWidget {
  const CustomTimerView({super.key});

  @override
  State<CustomTimerView> createState() => _CustomTimerViewState();
}

class _CustomTimerViewState extends State<CustomTimerView> {
  late final CustomTimerPresenter presenter;
  late final CustomTimerRouter router;

  @override
  void initState() {
    super.initState();
    presenter = CustomTimerPresenter();
    router = CustomTimerRouter();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final minutes = presenter.remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = presenter.remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Timer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: presenter.workController,
              decoration: const InputDecoration(labelText: 'Work Minutes'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: presenter.breakController,
              decoration: const InputDecoration(labelText: 'Break Minutes'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Text('$minutes:$seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (presenter.isRunning) {
                  presenter.stop();
                } else {
                  presenter.start(_update, _update);
                }
                setState(() {});
              },
              child: Text(presenter.isRunning ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
