import 'dart:async';
import 'package:flutter/material.dart';

enum PlayerLayoutType {
  compact,
  expanded,
  focus,
}

class MusicPlayerWidget extends StatefulWidget {
  final PlayerLayoutType layoutType;
  final String albumArtUrl;
  final String songTitle;
  final String artistName;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final bool isDynamic;
  final Future<void> Function() onPlayPausePressed;
  final Future<void> Function() onNextPressed;
  final Future<void> Function() onPreviousPressed;
  final Future<void> Function(Duration newPosition)? onSeek;
  // New required parameters for repeat and shuffle mode from the parent.
  final String repeatMode; // expected values: "off", "track", "context"
  final bool shuffleMode;
  // Optional callbacks for when the user presses these buttons.
  final Future<void> Function()? onRepeatPressed;
  final Future<void> Function()? onShufflePressed;

  const MusicPlayerWidget({
    super.key,
    required this.layoutType,
    required this.albumArtUrl,
    required this.songTitle,
    required this.artistName,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.isDynamic,
    this.onSeek,
    required this.repeatMode,
    required this.shuffleMode,
    this.onRepeatPressed,
    this.onShufflePressed,
  });

  @override
  MusicPlayerWidgetState createState() => MusicPlayerWidgetState();

  static void switchLayout(PlayerLayoutType compact) {}
}

class MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late Duration _currentPosition;
  Timer? _progressTimer;
  // Local copies of repeat and shuffle mode.
  late String _repeatMode;
  late bool _shuffleMode;
  late bool _isDynamic;

  // Use a state variable to control the current layout.
  late PlayerLayoutType _currentLayout;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _repeatMode = widget.repeatMode;
    _shuffleMode = widget.shuffleMode;
    _isDynamic = widget.isDynamic;
    _currentLayout = widget.layoutType;
    if (widget.isPlaying) {
      _startProgressTimer();
    }
  }

  @override
  void didUpdateWidget(covariant MusicPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition) {
      setState(() {
        _currentPosition = widget.currentPosition;
      });
    }
    if (widget.repeatMode != oldWidget.repeatMode) {
      setState(() {
        _repeatMode = widget.repeatMode;
      });
    }
    if (widget.shuffleMode != oldWidget.shuffleMode) {
      setState(() {
        _shuffleMode = widget.shuffleMode;
      });
    }
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startProgressTimer();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopProgressTimer();
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentPosition += const Duration(seconds: 1);
        if (_currentPosition >= widget.totalDuration) {
          if (widget.isPlaying) {
            _currentPosition = Duration.zero;
          } else {
            _currentPosition = widget.totalDuration;
            timer.cancel();
          }
        }
      });
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
  }

  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Build extra controls for shuffle and repeat.
  Widget _buildShuffledButton() {
    return IconButton(
      icon: Icon(
        Icons.shuffle,
        color: _shuffleMode ? Colors.black : Colors.grey,
      ),
      iconSize: 32,
      onPressed: () async {
        if (widget.onShufflePressed != null) {
          await widget.onShufflePressed!();
        }
      },
    );
  }

  Widget _buildRepeatButton() {
    return IconButton(
      icon: Icon(
        _repeatMode == 'off'
            ? Icons.repeat
            : _repeatMode == 'track'
                ? Icons.repeat_one
                : Icons.repeat,
        color: _repeatMode == 'off' ? Colors.grey : Colors.black,
      ),
      iconSize: 32,
      onPressed: () async {
        if (widget.onRepeatPressed != null) {
          await widget.onRepeatPressed!();
        }
      },
    );
  }

  Widget _buildSkipPrevButton() {
    return IconButton(
      icon: const Icon(Icons.skip_previous),
      onPressed: () async {
        await widget.onPreviousPressed();
        setState(() {
          _currentPosition = Duration.zero;
        });
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return IconButton(
      icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
      iconSize: 48,
      onPressed: () async {
        await widget.onPlayPausePressed();
      },
    );
  }

  Widget _buildSkipNextButton() {
    return IconButton(
      icon: const Icon(Icons.skip_next),
      onPressed: () async {
        await widget.onNextPressed();
        setState(() {
          _currentPosition = Duration.zero;
        });
      },
    );
  }

  /// Public method to switch layout from outside.
  void switchLayout(PlayerLayoutType newLayout) {
    setState(() {
      _currentLayout = newLayout;
    });
  }

  /// Internal helper to toggle/cycle through the layouts.
  void _toggleLayout() {
    setState(() {
      if (_currentLayout == PlayerLayoutType.compact) {
        _currentLayout = PlayerLayoutType.expanded;
      } else if (_currentLayout == PlayerLayoutType.expanded) {
        _currentLayout = PlayerLayoutType.focus;
      } else {
        _currentLayout = PlayerLayoutType.compact;
      }
    });
  }

  /// Build the UI based on the current layout type.
  Widget _buildPlayerContent() {
    if (_currentLayout == PlayerLayoutType.compact) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album Art
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(widget.albumArtUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Song Info and Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.songTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.artistName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble(),
                            max: widget.totalDuration.inSeconds.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _currentPosition = Duration(seconds: value.toInt());
                              });
                            },
                            onChangeEnd: (value) async {
                              if (widget.onSeek != null) {
                                await widget.onSeek!(Duration(seconds: value.toInt()));
                              }
                            },
                          ),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildShuffledButton(),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSkipPrevButton(),
                              _buildPlayPauseButton(),
                              _buildSkipNextButton(),
                            ],
                          ),
                        ),
                        _buildRepeatButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_currentLayout == PlayerLayoutType.expanded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(widget.albumArtUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.songTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.artistName,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 16),
              Text(_formatDuration(_currentPosition)),
              Expanded(
                child: Slider(
                  value: _currentPosition.inSeconds.toDouble(),
                  max: widget.totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = Duration(seconds: value.toInt());
                    });
                  },
                  onChangeEnd: (value) async {
                    if (widget.onSeek != null) {
                      await widget.onSeek!(Duration(seconds: value.toInt()));
                    }
                  },
                ),
              ),
              Text(_formatDuration(widget.totalDuration)),
              const SizedBox(width: 16),
            ],
          ),
          Row(
            children: [
              _buildShuffledButton(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSkipPrevButton(),
                    _buildPlayPauseButton(),
                    _buildSkipNextButton(),
                  ],
                ),
              ),
              _buildRepeatButton(),
            ],
          ),
        ],
      );
    } else {
      // For the 'focus' layout (or any other layout), adjust as needed.
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album Art
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(widget.albumArtUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Song Info (simplified)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.songTitle,
                        style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center-align the text
                      ),
                      Text(
                        widget.artistName,
                        style: const TextStyle(fontSize: 14,color: Colors.grey),
                        textAlign: TextAlign.center, // Center-align the text
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the player content in a Stack so we can overlay a toggle button.
    if (_isDynamic){
      return Stack(
        children: [
          _buildPlayerContent(),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _toggleLayout,
              tooltip: 'Change Layout',
            ),
          ),
        ],
      );
    }
    else{
      
      return Stack(
        children: [
          _buildPlayerContent(),
          ],
        );
    }
  }
}
