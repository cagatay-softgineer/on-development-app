import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/pages/player_control_page.dart';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/widgets/playlist_card.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/enums/enums.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  PlaylistPageState createState() => PlaylistPageState();
}

class PlaylistPageState extends State<PlaylistPage> {
  List<Playlist> playlists = [];
  final Map<String, String> _userPicCache = {}; // Cache for user images
  String? userID = "";
  
  // Use a FutureBuilder for initialization.
  late Future<void> _initializationFuture;

  // Filter variables.
  String selectedAppFilter = "all"; // "all", "spotify", or "youtube"
  String _searchQuery = "";

  // We fetch both Spotify and YouTube playlists concurrently.
  final Map<int, bool> shuffleStates = {};
  final Map<int, String> repeatStates = {};

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      userID = userId;
      // Fetch Spotify and YouTube playlists concurrently.
      final spotifyPlaylistsFuture =
          mainAPI.fetchPlaylists("$userId", app: MusicApp.Spotify);
      final youtubePlaylistsFuture =
          mainAPI.fetchPlaylists("$userId", app: MusicApp.YouTube);

      final results = await Future.wait([spotifyPlaylistsFuture, youtubePlaylistsFuture]);
      final mergedPlaylists = <Playlist>[];
      mergedPlaylists.addAll(results[0]);
      mergedPlaylists.addAll(results[1]);

      setState(() {
        playlists = mergedPlaylists;
      });
    } catch (e) {
      print("Error fetching playlists: $e");
    }
  }

  Future<String> getUserPic(Playlist playlist) async {
    // For YouTube, if the playlist already includes a channelImage, use it.
    if (playlist.app == MusicApp.YouTube &&
        playlist.channelImage != null &&
        playlist.channelImage!.isNotEmpty) {
      return playlist.channelImage!;
    }
  
    final ownerId = playlist.playlistOwnerID;
    if (_userPicCache.containsKey(ownerId)) {
      print("Cache hit for $ownerId");
      return _userPicCache[ownerId]!;
    }
    try {
      final response = await mainAPI.getUserInfo(ownerId);
      String image;
      if (response["images"] != null &&
          response["images"] is List &&
          response["images"].isNotEmpty) {
        image = response["images"][0]["url"];
        print("Fetched from API: $image");
      } else {
        image = UserConstants.defaultAvatarUrl;
        print("Using default image for $ownerId");
      }
      _userPicCache[ownerId] = image;
      return image;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        print("HTTP 429 Too Many Requests for $ownerId. Using fallback image.");
      } else {
        print("Error fetching user pic: $e");
      }
      return UserConstants.defaultAvatarUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter playlists by app.
    final appFilteredPlaylists = selectedAppFilter == "all"
        ? playlists
        : playlists.where((p) {
            if (selectedAppFilter == "spotify") {
              return p.app == MusicApp.Spotify;
            } else if (selectedAppFilter == "youtube") {
              return p.app == MusicApp.YouTube;
            }
            return true;
          }).toList();
    // Filter by search query (playlist name or owner name).
    final filteredPlaylists = _searchQuery.isEmpty
        ? appFilteredPlaylists
        : appFilteredPlaylists.where((p) {
            final combined = (p.playlistName + " " + p.playlistOwner).toLowerCase();
            return combined.contains(_searchQuery.toLowerCase());
          }).toList();

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Playlists Page')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Playlists Page')),
          body: Column(
            children: [
              // Row with App filter dropdown and search bar.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        value: selectedAppFilter,
                        onChanged: (newValue) {
                          setState(() {
                            selectedAppFilter = newValue!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: "all",
                            child: Text("All Apps"),
                          ),
                          DropdownMenuItem(
                            value: "spotify",
                            child: Text("Spotify"),
                          ),
                          DropdownMenuItem(
                            value: "youtube",
                            child: Text("YouTube"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Search by Playlist or Owner",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Display filtered playlists.
              Expanded(
                child: filteredPlaylists.isEmpty
                    ? const Center(
                        child: Text(
                          'No playlists for selected filter',
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPlaylists.length,
                        itemBuilder: (context, index) {
                          final playlist = filteredPlaylists[index];
                          final shuffleState = shuffleStates[index] ?? false;
                          final repeatState = repeatStates[index] ?? "off";
                
                          return PlaylistCard(
                            playlist: playlist,
                            shuffleState: shuffleState,
                            repeatState: repeatState,
                            getUserPic: getUserPic,
                            onShuffleChanged: (bool? value) {
                              setState(() {
                                shuffleStates[index] = value ?? false;
                              });
                            },
                            onRepeatChanged: (String? newValue) {
                              setState(() {
                                repeatStates[index] = newValue ?? "off";
                              });
                            },
                            onPlayButtonPressed: () async {
                              // For YouTube, use our backend endpoint to fetch all playlist tracks.
                              if (playlist.app == MusicApp.YouTube) {
                                try {
                                  // Assuming AuthService provides the user's email.
                                  final userEmail = await AuthService.getUserId();
                                  // Call your custom backend endpoint.
                                  final List<Track> songs = await mainAPI.fetchPlaylistTracks(userEmail, playlist.playlistId);
                                  print('Playlist ID: ${playlist.playlistId}');
                                  print('App: ${playlist.app}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerControlPage(
                                        selectedPlaylistId: playlist.playlistId,
                                        selectedApp: playlist.app,
                                        songs: songs, // songs is now a List<Playlist>
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error fetching playlist tracks: $e');
                                  // Optionally, show an error message.
                                }
                              } else {
                                // For Spotify, navigate as before.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerControlPage(
                                      selectedPlaylistId: playlist.playlistId,
                                      selectedApp: playlist.app,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
