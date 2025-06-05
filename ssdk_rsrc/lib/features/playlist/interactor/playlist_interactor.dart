import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';

class PlaylistInteractor {
  Future<(String, List<Playlist>)> fetchPlaylists() async {
    final userId = await AuthService.getUserId();
    final spotify = mainAPI.fetchPlaylists("$userId", app: MusicApp.Spotify);
    final youtube = mainAPI.fetchPlaylists("$userId", app: MusicApp.YouTube);
    final apple = mainAPI.fetchPlaylists("$userId", app: MusicApp.Apple);
    final results = await Future.wait([spotify, youtube, apple]);
    final merged = <Playlist>[];
    merged.addAll(results[0]);
    merged.addAll(results[1]);
    merged.addAll(results[2]);
    return (userId, merged);
  }

  Future<String> getOwnerPic(String ownerId) async {
    try {
      final response = await mainAPI.getUserInfo(ownerId);
      if (response["images"] != null &&
          response["images"] is List &&
          response["images"].isNotEmpty) {
        return response["images"][0]["url"];
      }
      return UserConstants.defaultAvatarUrl;
    } catch (_) {
      return UserConstants.defaultAvatarUrl;
    }
  }
}
