import 'package:flutter/material.dart';
import 'package:pomodoro/models/playlist.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/widgets/button/custom_button.dart';
import 'package:pomodoro/resources/themes.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final bool shuffleState;
  final String repeatState;
  final ValueChanged<bool?> onShuffleChanged;
  final ValueChanged<String?> onRepeatChanged;
  final Future<String> Function(Playlist) getUserPic;
  final Future<void> Function() onPlayButtonPressed;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    required this.shuffleState,
    required this.repeatState,
    required this.onShuffleChanged,
    required this.onRepeatChanged,
    required this.getUserPic,
    required this.onPlayButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using the current theme for styling consistency.
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Optionally, handle card tap.
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // First Row: Playlist image and information.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Playlist image with rounded corners.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      playlist.playlistImage,
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 75,
                          height: 75,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 40, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Playlist details.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.playlistName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${playlist.playlistTrackCount} tracks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Display the app icon.
                            Icon(playlist.app.icon, color: playlist.app.color, size: playlist.app.size),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: mainAPI.getPlaylistDuration(playlist.playlistId, playlist.app, playlist.playlistTrackCount),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      "Loading duration...",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text(
                                      "Error loading duration",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  } else if (snapshot.hasData) {
                                    final data = snapshot.data!;
                                    // Check if an error was returned in the response.
                                    if (data['error'] == true) {
                                      return Text(
                                        data['message'] ?? "Unavailable",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    } else {
                                      return Text(
                                        "${data['formatted_duration']}",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                  } else {
                                    return Text(
                                      "Unknown",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        //const SizedBox(height: 8),
                        // Owner or channel image using FutureBuilder with a refined placeholder.
                      ],
                    ),
                  ),
                ],
              ),
              //const SizedBox(height: 16),
              // Second Row: Playback controls.
              Row(
                children: [
                  //Expanded(
                  //  child: Row(
                  //    children: [
                  //      Checkbox(
                  //        value: shuffleState,
                  //        onChanged: onShuffleChanged,
                  //      ),
                  //      const SizedBox(width: 4),
                  //      const Text(
                  //        "Shuffle",
                  //        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  //      ),
                  //    ],
                  //  ),
                  //),
                  //Expanded(
                  //  child: DropdownButtonHideUnderline(
                  //    child: DropdownButton<String>(
                  //      value: repeatState,
                  //      items: const [
                  //        DropdownMenuItem(value: "off", child: Text("Repeat Off")),
                  //        DropdownMenuItem(value: "track", child: Text("Repeat Track")),
                  //        DropdownMenuItem(value: "context", child: Text("Repeat Context")),
                  //      ],
                  //      onChanged: onRepeatChanged,
                  //      style: const TextStyle(fontSize: 14, color: Colors.black),
                  //      icon: const Icon(Icons.arrow_drop_down),
                  //    ),
                  //  ),
                  //),
                  FutureBuilder<String>(
                    future: getUserPic(playlist),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.error, color: Colors.red, size: 20),
                        );
                      } else {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(snapshot.data!),
                          backgroundColor: Colors.grey.shade300,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${playlist.playlistOwner}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: CustomButton(
                      text: "",
                      onPressed: onPlayButtonPressed,
                      buttonParams: spotifyPlayButtonParams,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
