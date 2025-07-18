import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeMusicPlayer extends StatefulWidget {
  final String videoId;
  final String videoName;

  const YouTubeMusicPlayer({
    Key? key,
    required this.videoId,
    required this.videoName,
  }) : super(key: key);

  @override
  _YouTubeMusicPlayerState createState() => _YouTubeMusicPlayerState();
}

class _YouTubeMusicPlayerState extends State<YouTubeMusicPlayer> {
  late YoutubePlayerController _controller;
  String currentVideoId = "";
  String currentVideoName = "";
  Duration currentVideoTimestamp = Duration.zero;
  Duration currentVideoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    currentVideoId = widget.videoId;
    currentVideoName = widget.videoName;
    _controller = YoutubePlayerController(
      initialVideoId: currentVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_controller.value.isReady) {
      setState(() {
        currentVideoTimestamp = _controller.value.position;
        currentVideoDuration = _controller.value.metaData.duration;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
        ),
        const SizedBox(height: 8),
        Text(
          "Now Playing: $currentVideoName",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text("Video ID: $currentVideoId"),
        const SizedBox(height: 8),
        Text("Current Position: ${currentVideoTimestamp.inSeconds} sec"),
        Text("Total Duration: ${currentVideoDuration.inSeconds} sec"),
      ],
    );
  }
}
