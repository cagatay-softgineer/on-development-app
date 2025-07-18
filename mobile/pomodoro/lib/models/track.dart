import 'package:pomodoro/models/music_app.dart';

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
    case MusicApp.youtube:
      return Track(
        trackName: json['title'] ?? '',
        // You can assign a default or empty value for artistName if it isn’t provided
        artistName: json['channelTitle'] ?? '',
        trackId: json['video_id'] ?? '',
        // If your JSON doesn’t include an image, you can provide a default image or an empty string
        trackImage: json['thumbnail_url'],
      );
    case MusicApp.spotify:
      return Track(
        trackName: json['track_name'] ?? '',
        artistName: json['artist_name'] ?? '',
        trackId: json['track_id'] ?? '',
        trackImage: json['track_image'] ?? '',
      );
    case MusicApp.apple:
    return Track(
      trackName: json['track_name'] ?? '',
      artistName: json['artist_name'] ?? '',
      trackId: json['track_id'] ?? '',
      trackImage: json['track_image'] ?? '',
    );
  }
}
}
