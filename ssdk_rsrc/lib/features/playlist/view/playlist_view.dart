import 'package:flutter/material.dart';
import '../presenter/playlist_presenter.dart';
import '../router/playlist_router.dart';
import '../../../widgets/playlist_card.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  late final PlaylistPresenter presenter;
  late final PlaylistRouter router;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    presenter = PlaylistPresenter();
    router = PlaylistRouter();
    presenter.loadPlaylists().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists Page')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButton<String>(
                          value: presenter.selectedAppFilter,
                          onChanged: (value) {
                            setState(() {
                              presenter.selectedAppFilter = value!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Apps'),
                            ),
                            DropdownMenuItem(
                              value: 'spotify',
                              child: Text('Spotify'),
                            ),
                            DropdownMenuItem(
                              value: 'youtube',
                              child: Text('YouTube'),
                            ),
                            DropdownMenuItem(
                              value: 'apple',
                              child: Text('Apple'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by Playlist or Owner',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              presenter.searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: presenter.filteredPlaylists.isEmpty
                      ? const Center(child: Text('No playlists for selected filter'))
                      : ListView.builder(
                          itemCount: presenter.filteredPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = presenter.filteredPlaylists[index];
                            return PlaylistCard(
                              playlist: playlist,
                              shuffleState: false,
                              repeatState: 'off',
                              getUserPic: presenter.getUserPic,
                              onShuffleChanged: (_) {},
                              onRepeatChanged: (_) {},
                              onPlayButtonPressed: () => router.openPlayer(context, playlist),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
