import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/api_service.dart';
import 'widgets/custom_button.dart'; // Ensure the correct path
import 'styles/button_styles.dart';
import 'authlib.dart';

String playlistDur = "";

class PlayerControlPage extends StatefulWidget {
  const PlayerControlPage({Key? key}) : super(key: key);

  @override
  _PlayerControlPageState createState() => _PlayerControlPageState();
}

class _PlayerControlPageState extends State<PlayerControlPage> {
  String? userID = "";
  
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

  @override
  void initState() {
    super.initState();
    _initializeData(); // Initialize playlists and fetch oEmbed data
  }

  Future<void> _initializeData() async {
    try{
      final userId = await AuthService.getUserId();
      userID = userId;
    }
    catch (e) {
      print("Error fetching playlists: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adds padding around the content
        child: Center(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
          children: [
            SizedBox(height: 40), // Adds space from the top
            // Welcome Message
            Text(
              'Player Control',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            Text(
              playlistDur,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), 
            // CustomButton to Navigate to Button Customizer
            CustomButton(
              text: "Play/Resume",
              onPressed: () async{
                final response = await spotifyAPI.getDevices(userID);
                final deviceId = extractFirstDeviceId(response);
                spotifyAPI.resumePlayer(userID, deviceId);
              },
              buttonParams: playerPlayButtonParams,
            ),
            SizedBox(height: 20), // Adds vertical spacing
            // CustomButton for Logout
            CustomButton(
              text: "Pause",
              onPressed: () async {
                final response = await spotifyAPI.getDevices(userID);
                final deviceId = extractFirstDeviceId(response);
                spotifyAPI.pausePlayer(userID, deviceId);
              },
              buttonParams: playerPauseButtonParams,
            ),
            // Add more widgets or buttons as needed
          ],
        ),
        ),
      ),
    );
  }
}