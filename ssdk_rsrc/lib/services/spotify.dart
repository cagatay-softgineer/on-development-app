import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/services/api_service.dart';

class SpotifyPlayerController {
  final SpotifyAPI spotifyAPI;

  SpotifyPlayerController({required this.spotifyAPI});

  /// Initiates playback of the given playlist for the specified user.
  Future<void> play(Playlist? selectedPlaylist, String? userID) async {
    if (selectedPlaylist != null && userID != null && userID.isNotEmpty) {
      final response = await spotifyAPI.getDevices(userID);
      final deviceId = _extractFirstDeviceId(response);
      await spotifyAPI.playPlaylist(selectedPlaylist.playlistId, userID, deviceId);
    }
  }

  /// Stops playback for the specified user.
  Future<void> stop(String? userID) async {
    if (userID != null && userID.isNotEmpty) {
      final response = await spotifyAPI.getDevices(userID);
      final deviceId = _extractFirstDeviceId(response);
      await spotifyAPI.pausePlayer(userID, deviceId);
    }
  }

  /// Extracts the first device ID from the device response.
  String _extractFirstDeviceId(dynamic response) {
    // This implementation is based on the expected structure of the response.
    // Adjust the code as necessary based on the actual response format.
    return response['devices'][0]['id'];
  }
}
