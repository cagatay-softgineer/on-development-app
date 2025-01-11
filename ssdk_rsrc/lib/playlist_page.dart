import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/api_service.dart';
import 'authlib.dart';
import 'models/playlist.dart';


class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  PlaylistPageState createState() => PlaylistPageState();
}

class PlaylistPageState extends State<PlaylistPage> {
  final ApiService apiService = ApiService();
  List<Playlist> playlists = [];
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  _initializeData(); // Call the async method without awaiting
}

 Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      final fetchedPlaylists = await apiService.fetchPlaylists("$userId");
      setState(() {
        playlists = fetchedPlaylists; // Store the playlists
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading even if there's an error
      });
      print("Error fetching playlists: $e");
    }
  }


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists Page')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : playlists.isEmpty
              ? const Center(
                  child: Text(
                    'No playlists available',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return GestureDetector(
                      onTap: () async {
                        // Add functionality for tapping on a playlist
                        try {
                            // Fetch the playlist duration data
                            final response = await apiService.getPlaylistDuration("${playlist.playlistId}");
                            // ignore: unnecessary_null_comparison
                            if (response != null) {
                              print("Formatted Duration: ${response['formatted_duration']}");
                              print("Playlist ID: ${response['playlist_id']}");
                              print("Total Duration (ms): ${response['total_duration_ms']}");
                            } else {
                              print("No data returned from getPlaylistDuration");
                            }
                          } catch (e) {
                            print("Error fetching playlist duration: $e");
                          }
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Image.network(
                                playlist.playlistImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  playlist.playlistName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}