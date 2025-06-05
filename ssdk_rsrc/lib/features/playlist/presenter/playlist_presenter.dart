import '../interactor/playlist_interactor.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/constants/default/user.dart';
import 'package:ssdk_rsrc/enums/enums.dart';

class PlaylistPresenter {
  final PlaylistInteractor _interactor = PlaylistInteractor();
  List<Playlist> playlists = [];
  final Map<String, String> _userPicCache = {};
  String userId = '';

  String selectedAppFilter = 'all';
  String searchQuery = '';

  Future<void> loadPlaylists() async {
    final result = await _interactor.fetchPlaylists();
    userId = result.$1;
    playlists = result.$2;
  }

  Future<String> getUserPic(Playlist playlist) async {
    if (playlist.app == MusicApp.YouTube) {
      if (playlist.channelImage != null && playlist.channelImage!.isNotEmpty) {
        return playlist.channelImage!;
      } else {
        return UserConstants.defaultAvatarUrl;
      }
    }
    if (playlist.app == MusicApp.Apple) {
      return UserConstants.defaultAvatarUrl;
    }
    final ownerId = playlist.playlistOwnerID;
    if (_userPicCache.containsKey(ownerId)) {
      return _userPicCache[ownerId]!;
    }
    final image = await _interactor.getOwnerPic(ownerId);
    _userPicCache[ownerId] = image;
    return image;
  }

  List<Playlist> get filteredPlaylists {
    final appFiltered = selectedAppFilter == 'all'
        ? playlists
        : playlists.where((p) {
            if (selectedAppFilter == 'spotify') {
              return p.app == MusicApp.Spotify;
            } else if (selectedAppFilter == 'youtube') {
              return p.app == MusicApp.YouTube;
            } else if (selectedAppFilter == 'apple') {
              return p.app == MusicApp.Apple;
            }
            return true;
          }).toList();
    return searchQuery.isEmpty
        ? appFiltered
        : appFiltered
            .where((p) =>
                '${p.playlistName} ${p.playlistOwner}'
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();
  }
}
