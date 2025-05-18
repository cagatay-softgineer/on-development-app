// appsSession.dart
import 'package:ssdk_rsrc/models/linked_app.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart'; // Needed for Color, if you use appColor

class AppsSession {
  static String? userEmail;
  static List<LinkedApp> linkedApps = [
    LinkedApp(
      name: "Spotify",
      appButtonParams: spotifyButtonParams,
      appPic:
          "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png",
      appColor: Spotify.green,
      buttonText: "",
    ),
    LinkedApp(
      name: "AppleMusic",
      appButtonParams: appleMusicButtonParams,
      appPic:
          "https://play-lh.googleusercontent.com/mOkjjo5Rzcpk7BsHrsLWnqVadUK1FlLd2-UlQvYkLL4E9A0LpyODNIQinXPfUMjUrbE=w240-h480-rw",
      appColor: AppleMusic.pink,
      buttonText: "",
    ),
    LinkedApp(
      name: "YoutubeMusic",
      appButtonParams: youtubeMusicButtonParams,
      appPic:
          "https://upload.wikimedia.org/wikipedia/commons/d/d8/YouTubeMusic_Logo.png",
      appColor: Youtube.red,
      buttonText: "",
    ),
  ];

  // You may also want to store other session info here (e.g., tokens)
}
