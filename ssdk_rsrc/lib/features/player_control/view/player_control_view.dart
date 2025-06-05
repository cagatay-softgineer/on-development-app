import 'package:flutter/material.dart';
import '../presenter/player_control_presenter.dart';
import '../router/player_control_router.dart';

class PlayerControlView extends StatefulWidget {
  const PlayerControlView({super.key});

  @override
  State<PlayerControlView> createState() => _PlayerControlViewState();
}

class _PlayerControlViewState extends State<PlayerControlView> {
  late final PlayerControlPresenter presenter;
  late final PlayerControlRouter router;

  @override
  void initState() {
    super.initState();
    presenter = PlayerControlPresenter();
    router = PlayerControlRouter();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Track: ${presenter.currentTrack}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    presenter.previous();
                    _refresh();
                  },
                ),
                IconButton(
                  icon: Icon(presenter.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    presenter.togglePlay();
                    _refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    presenter.next();
                    _refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => router.openPlaylist(context),
              child: const Text('Choose Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
