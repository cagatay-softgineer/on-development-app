import 'package:flutter/material.dart';
import 'models/button_params.dart';
import 'widgets/custom_button.dart'; // Ensure the correct path
import 'styles/button_styles.dart';
import 'api_service.dart';
import 'authlib.dart';


class AppLinks extends StatefulWidget {
  const AppLinks({super.key});

  @override
  AppLinksState createState() => AppLinksState();
}

class AppLinksState extends State<AppLinks> {
  String Spotify_Button_Text = "Loading...";
  String AppleMusic_Button_Text = "Loading...";
  String YoutubeMusic_Button_Text = "Loading...";
  final userId = AuthService.getUserId();
  final ApiService apiService = ApiService();

   @override
  void initState() {
    super.initState();

    // Initialize the button texts
    _loadingText();

    // Check the link states asynchronously
    _initializeLinkedApps();
  }

  Future<void> _loadingText() async {
    Spotify_Button_Text = "Loading...";
    AppleMusic_Button_Text = "Loading...";
    YoutubeMusic_Button_Text = "Loading...";
  }

  Future<void> _initializeLinkedApps() async {
    // Fetch user ID once (if needed)
    final userId = await AuthService.getUserId();

    // Fetch link states
    bool isSpotifyLinked =
        await checkLinkedApp(spotifyButtonParams, userId, "Spotify");
    bool isAppleMusicLinked =
        await checkLinkedApp(appleMusicButtonParams, userId, "AppleMusic");
    bool isYoutubeMusicLinked =
        await checkLinkedApp(youtubeMusicButtonParams, userId, "YoutubeMusic");

    // Update button texts based on the results
    setState(() {
      Spotify_Button_Text =
          isSpotifyLinked ? "Unlink Spotify" : "Link Spotify";
      spotifyButtonParams.trailingIcon = 
          isSpotifyLinked ? Icons.link_off : Icons.link;

      AppleMusic_Button_Text =
          isAppleMusicLinked ? "Unlink Apple Music" : "Link Apple Music";
      appleMusicButtonParams.trailingIcon = 
          isAppleMusicLinked ? Icons.link_off : Icons.link;

      YoutubeMusic_Button_Text =
          isYoutubeMusicLinked ? "Unlink Youtube Music" : "Link Youtube Music";
      youtubeMusicButtonParams.trailingIcon = 
          isYoutubeMusicLinked ? Icons.link_off : Icons.link;
    });
  }

  Future<bool> checkLinkedApp(
      ButtonParams custom_button, String? email, String app_name) async {
    // Show loading state
    if (mounted) {
      setState(() => custom_button.isLoading = true);
    }

    try {
      final response = await apiService.check_linked_app(email, app_name);
      //print("Get Response for $app_name : $response");

      if (response['error'] == true) {
        // Log the error or show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'App Linked Check failed'),
            ),
          );
        }
        return false;
      } else {
        final userLinked = response['user_linked'];
        return userLinked; // Return true if "user_linked" is "true", else false
      }
    } catch (e) {
      // Handle exceptions gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
          ),
        );
      }
      return false;
    } finally {
      // Hide loading state
      if (mounted) {
        setState(() => custom_button.isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apps')),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adds padding around the content
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
            children: [
              const SizedBox(height: 40), // Adds space from the top
              // Welcome Message
              const Text(
                'Apps',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // Adds vertical spacing
              // Spotify Button
              CustomButton(
                text: Spotify_Button_Text,
                onPressed: () async {
                  bool isSpotifyLinked = await checkLinkedApp(
                      spotifyButtonParams,
                      await AuthService.getUserId(),
                      "Spotify");
                  if(isSpotifyLinked){
                    print("Unlink Proccess");
                    _loadingText();
                    await apiService.unlinkApp("Spotify");
                    _initializeLinkedApps();
                  }
                  else{
                    print("Link Proccess");
                    _loadingText();
                    await apiService.openSpotifyLogin(context);
                    _initializeLinkedApps();
                  }
                  setState(() {
                    Spotify_Button_Text = isSpotifyLinked
                        ? "Unlink Spotify"
                        : "Link Spotify";
                  });
                },
                buttonParams: spotifyButtonParams,
              ),
              const SizedBox(height: 20), // Adds vertical spacing
              // Apple Music Button
              CustomButton(
                text: AppleMusic_Button_Text,
                onPressed: () async {
                  bool isAppleMusicLinked = await checkLinkedApp(
                      appleMusicButtonParams,
                      await AuthService.getUserId(),
                      "AppleMusic");

                  setState(() {
                    AppleMusic_Button_Text = isAppleMusicLinked
                        ? "Unlink Apple Music"
                        : "Link Apple Music";
                  });
                  print("Apple Music: $AppleMusic_Button_Text");
                },
                buttonParams: appleMusicButtonParams,
              ),
              const SizedBox(height: 20), // Adds vertical spacing
              // Youtube Music Button
              CustomButton(
                text: YoutubeMusic_Button_Text,
                onPressed: () async {
                  bool isYoutubeMusicLinked = await checkLinkedApp(
                      youtubeMusicButtonParams,
                      await AuthService.getUserId(),
                      "YoutubeMusic");

                  setState(() {
                    YoutubeMusic_Button_Text = isYoutubeMusicLinked
                        ? "Unlink Youtube Music"
                        : "Link Youtube Music";
                  });
                  print("Youtube Music: $YoutubeMusic_Button_Text");
                },
                buttonParams: youtubeMusicButtonParams,
              ),
            ],
          ),
        ),
      ),
    );
  }
}