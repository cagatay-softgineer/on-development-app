import 'package:ssdk_rsrc/enums/enums.dart';

class Playlist {
  final String playlistName;
  final String playlistId;
  final String playlistImage;
  final String playlistOwner;
  final String playlistOwnerID;
  final int playlistTrackCount;
  final String? channelImage; // Used for YouTube playlists (optional)
  final List<Track> tracks;
  final MusicApp app; // New field to mark the source

  Playlist({
    required this.playlistName,
    required this.playlistId,
    required this.playlistImage,
    required this.playlistOwner,
    required this.playlistOwnerID,
    required this.playlistTrackCount,
    this.channelImage,
    required this.tracks,
    required this.app,
  });

  factory Playlist.fromJson(Map<String, dynamic> json, MusicApp app) {
    switch (app) {
      case MusicApp.Spotify:
        return Playlist(
          playlistName: json['playlist_name'] ?? '',
          playlistId: json['playlist_id'] ?? '',
          playlistImage: json['playlist_image'] ?? '',
          playlistOwner: json['playlist_owner'] ?? '',
          playlistOwnerID: json['playlist_owner_id'] ?? '',
          playlistTrackCount: json['playlist_track_count'] ?? 0,
          channelImage: null,
          tracks: (json['tracks'] as List<dynamic>?)
                  ?.map((trackJson) => Track.fromJson(trackJson, app))
                  .toList() ??
              [],
          app: MusicApp.Spotify,
        );
      case MusicApp.YouTube:
        final snippet = json['snippet'] ?? {};
        final contentDetails = json['contentDetails'] ?? {};
        final thumbnails = snippet['thumbnails'] ?? {};

        // Choose a high-quality thumbnail if available.
        String imageUrl = '';
        if (thumbnails['high'] != null && thumbnails['high']['url'] != null) {
          imageUrl = thumbnails['high']['url'];
        } else if (thumbnails['default'] != null &&
            thumbnails['default']['url'] != null) {
          imageUrl = thumbnails['default']['url'];
        }
        // Extract channel image if provided.
        String? channelImg = snippet['channelImage'];
        return Playlist(
          playlistName: snippet['title'] ?? '',
          playlistId: json['id'] ?? '',
          playlistImage: imageUrl,
          playlistOwner: snippet['channelTitle'] ?? '',
          playlistOwnerID: snippet['channelId'] ?? '',
          playlistTrackCount: contentDetails['itemCount'] ?? 0,
          channelImage: channelImg,
          tracks: [], // YouTube tracks are typically fetched separately.
          app: MusicApp.YouTube,
        );
    }
  }
}

class Track {
  final String trackName;
  final String artistName;
  final String trackId;
  final String trackImage;

  Track({
    required this.trackName,
    required this.artistName,
    required this.trackId,
    required this.trackImage,
  });

  factory Track.fromJson(Map<String, dynamic> json, MusicApp app) {
    switch (app) {
      case MusicApp.Spotify:
        return Track(
          trackName: json['track_name'] ?? '',
          artistName: json['artist_name'] ?? '',
          trackId: json['track_id'] ?? '',
          trackImage: json['track_image'] ?? '',
        );
      case MusicApp.YouTube:
        final snippet = json['snippet'] ?? {};
        final resourceId = snippet['resourceId'] ?? {};
        final thumbnails = snippet['thumbnails'] ?? {};

        String imageUrl = '';
        if (thumbnails['high'] != null && thumbnails['high']['url'] != null) {
          imageUrl = thumbnails['high']['url'];
        } else if (thumbnails['default'] != null &&
            thumbnails['default']['url'] != null) {
          imageUrl = thumbnails['default']['url'];
        }

        return Track(
          trackName: snippet['title'] ?? '',
          artistName: snippet['videoOwnerChannelTitle'] ?? '',
          trackId: resourceId['videoId'] ?? '',
          trackImage: imageUrl,
        );
    }
  }
}
