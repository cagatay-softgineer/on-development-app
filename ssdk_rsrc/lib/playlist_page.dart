import 'package:flutter/material.dart';

import 'package:ssdk_rsrc/api_service.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'authlib.dart';
import 'models/playlist.dart';
import 'styles/button_styles.dart';
// import 'player_control_page.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  PlaylistPageState createState() => PlaylistPageState();
}

class PlaylistPageState extends State<PlaylistPage> {
  final ApiService apiService = ApiService();
  List<Playlist> playlists = [];
  final Map<String, String> _userPicCache = {}; // Cache for user images
  final String defaultUserPicUrl = "https://sync-branch.yggbranch.dev/assets/default_user.png";
  String? userID = "";
  bool isLoading = true;

  final Map<int, bool> shuffleStates = {};
  final Map<int, String> repeatStates = {};

  @override
  void initState() {
    super.initState();
    _initializeData(); // Initialize playlists and fetch oEmbed data
  }

  Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      userID = userId;
      final fetchedPlaylists = await mainAPI.fetchPlaylists("$userId");
      setState(() {
        playlists = fetchedPlaylists; // Store the playlists
        isLoading = false;
      });
      // After fetching playlists, fetch oEmbed data
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading even if there's an error
      });
      print("Error fetching playlists: $e");
    }
  }

  Future<String> getUserPic(Playlist playlist) async {
    final ownerId = playlist.playlistOwnerID;

    // Check if the image URL is already in the cache
    if (_userPicCache.containsKey(ownerId)) {
      print("Cache hit for $ownerId");
      return _userPicCache[ownerId]!;
    }

    // If not in cache, fetch from the API
    try {
      final response = await mainAPI.getUserInfo(ownerId);
      String image;

      // Check if images are present in the API response
      if (response["images"] != null &&
          response["images"] is List &&
          response["images"].isNotEmpty) {
        image = response["images"][0]["url"];
        print("Fetched from API: $image");
      } else {
        // Use default URL if no images are available
        image = defaultUserPicUrl;
        print("Using default image for $ownerId");
      }

      // Cache the result
      _userPicCache[ownerId] = image;

      return image;
    } catch (e) {
      print("Error fetching user pic: $e");

      // Return default URL on error
      return defaultUserPicUrl;
    }
  }

  String extractFirstDeviceId(Map<String, dynamic> response) {
  // Check if 'devices' key exists and is a list
  if (response.containsKey('devices') && response['devices'] is List) {
    List<dynamic> devices = response['devices'];
    
    if (devices.isNotEmpty) {
      // Access the first device
      Map<String, dynamic> firstDevice = devices[0];
      
      // Check if 'id' key exists
      if (firstDevice.containsKey('id') && firstDevice['id'] is String) {
        String deviceId = firstDevice['id'];
        return deviceId;
      } else {
        return ('Device ID not found or is not a string.');
      }
    } else {
      return ('No devices available.');
    }
  } else {
    return ('Invalid response format: "devices" key missing or not a list.');
  }
}

String extractFirstSmartphoneDeviceId(Map<String, dynamic> response) {
  // Check if 'devices' key exists and is a list
  if (response.containsKey('devices') && response['devices'] is List) {
    List<dynamic> devices = response['devices'];
    
    if (devices.isNotEmpty) {
      // Iterate through devices to find the first Smartphone
      for (var device in devices) {
        if (device is Map<String, dynamic>) {
          if (device['type'] == 'Smartphone') {
            if (device.containsKey('id') && device['id'] is String) {
              String deviceId = device['id'];
              return deviceId;
            } else {
              return 'Device ID not found or is not a string.';
            }
          }
        }
      }
      return 'No Smartphone devices found.';
    } else {
      return 'No devices available.';
    }
  } else {
    return 'Invalid response format: "devices" key missing or not a list.';
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
                  style: TextStyle(color: Colors.black),
                ),
              )
            : ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final shuffleState = shuffleStates[index] ?? false; // Default false
                  final repeatState = repeatStates[index] ?? "off"; // Default "off"

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Playlist Info Row
                          Row(
                            children: [
                              Image.network(
                                playlist.playlistImage,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "${playlist.playlistName}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  playlist.playlistOwner,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: "Montserrat",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                              Expanded(
                                child: FutureBuilder<String>(
                                  future: getUserPic(playlist), // Call the async method here
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      // While waiting for the future to resolve
                                      return const SizedBox(
                                        width: 25,
                                        height: 50,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    } else if (snapshot.hasError) {
                                      // If there's an error
                                      return const SizedBox(
                                        width: 25,
                                        height: 50,
                                        child: Center(child: Icon(Icons.error)),
                                      );
                                    } else if (!snapshot.hasData || snapshot.data == null) {
                                      // If there's no data
                                      return const SizedBox(
                                        width: 25,
                                        height: 50,
                                        child: Center(child: Text('No Image')),
                                      );
                                    } else {
                                      // If the future resolves successfully
                                      return
                                      CircleAvatar(
                                          radius: 50,
                                          backgroundImage: NetworkImage("${snapshot.data!}")
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Second Row with Shuffle and Repeat Mode
                          Row(
                              children: [
                                // Shuffle Mode Checkbox
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text(
                                      "Shuffle",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                    value: shuffleState,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        shuffleStates[index] = value ?? false;
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                                const SizedBox(width: 0),
                                // Repeat Mode Dropdown
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: repeatState,
                                    items: const [
                                      DropdownMenuItem(
                                          value: "off", child: Text("Repeat Off")),
                                      DropdownMenuItem(
                                          value: "track", child: Text("Repeat Track")),
                                      DropdownMenuItem(
                                          value: "context", child: Text("Repeat Context")),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        repeatStates[index] = newValue ?? "off";
                                      });
                                    },
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Montserrat",
                                      color: Colors.black,
                                    ),
                                    dropdownColor: Colors.white,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: Colors.black),
                                  ),
                                ),
                          Expanded(
                            child:GestureDetector(
                            onTap: () {
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CustomButton(
                                text: "",
                                onPressed: () async {
                                  try {
                                    final response =
                                        await mainAPI.getPlaylistDuration(playlist.playlistId);
                                    // ignore: unnecessary_null_comparison
                                    if (response != null) {
                                      setState(() {
                                        //playlistDur = response['formatted_duration'];
                                      });
                                      print("Formatted Duration: ${response['formatted_duration']}");
                                      print("Playlist ID: ${response['playlist_id']}");
                                      print("Total Duration (ms): ${response['total_duration_ms']}");
                                    } else {
                                      print("No data returned from getPlaylistDuration");
                                    }
                                  } catch (e) {
                                    print("Error fetching playlist duration: $e");
                                  }
                                  print(repeatState);
                                  print(shuffleState);
                                  final response = await spotifyAPI.getDevices(userID);
                                  print(response);
                                  final deviceId = extractFirstDeviceId(response);
                                  print(deviceId);
                                  print(playlist.playlistId);
                                  print(userID);
                                  print(deviceId);
                                  if (response["status_code"] == 200 && !response["error"]) {
                                    await spotifyAPI.playPlaylist(
                                        playlist.playlistId, userID, deviceId);
                                    await spotifyAPI.setRepeatMode(userID, deviceId, repeatState);
                                    await spotifyAPI.setShuffleMode(userID, deviceId, shuffleState);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Playback started!")),
                                    );
                                    Navigator.pushNamed(
                                          context, '/player', );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("No suitable devices found.")),
                                    );
                                  }
                                },
                                buttonParams: spotifyPlayButtonParams,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}