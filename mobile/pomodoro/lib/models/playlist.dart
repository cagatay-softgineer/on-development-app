import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/models/track.dart';

class Playlist {
  final String playlistName;
  final String playlistId;
  final String playlistImage;
  final String playlistOwner;
  final String playlistOwnerID;
  int playlistTrackCount;
  final String? playlistDuration;
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
    this.playlistDuration,
    this.channelImage,
    required this.tracks,
    required this.app,
  });

  factory Playlist.fromJson(Map<String, dynamic> json, MusicApp app) {
    switch (app) {
      case MusicApp.spotify:
        return Playlist(
          playlistName: json['playlist_name'] ?? '',
          playlistId: json['playlist_id'] ?? '',
          playlistImage: json['playlist_image'] ?? '',
          playlistOwner: json['playlist_owner'] ?? '',
          playlistOwnerID: json['playlist_owner_id'] ?? '',
          playlistTrackCount: json['playlist_track_count'] ?? 0,
          playlistDuration: json['playlist_duration'] ?? "0",
          channelImage: null,
          tracks:
              (json['tracks'] as List<dynamic>?)
                  ?.map((trackJson) => Track.fromJson(trackJson, app))
                  .toList() ??
              [],
          app: app,
        );
      case MusicApp.youtube:
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
          app: app,
        );
      case MusicApp.apple:
        final attributes = json['attributes'] ?? {};
        final artwork = attributes['artwork'] ?? {};
        String imageUrl = '';
        if (artwork.isNotEmpty && artwork['url'] != null) {
          // Replace placeholders with desired dimensions.
          imageUrl = artwork['url']
              .toString()
              .replaceAll('{w}', '200')
              .replaceAll('{h}', '200');
        }
        return Playlist(
          playlistName: attributes['name'] ?? '',
          playlistId: json['id'] ?? '',
          playlistImage: imageUrl,
          playlistOwner:
              '', // Apple Music does not provide owner details in this response.
          playlistOwnerID: '', // Not provided by Apple Music.
          playlistTrackCount: json['total_tracks'] ?? 0,
          playlistDuration: json['formatted_duration'] ?? "0",
          channelImage: null, // Not applicable for Apple Music.
          tracks: [], // Tracks should be fetched separately.
          app: app,
        );
    }
  }
}
