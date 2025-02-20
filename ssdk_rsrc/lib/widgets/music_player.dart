import 'dart:async';
import 'package:flutter/material.dart';

enum PlayerLayoutType {
  compact,
  expanded,
}

class MusicPlayerWidget extends StatefulWidget {
  final PlayerLayoutType layoutType;
  final String albumArtUrl;
  final String songTitle;
  final String artistName;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
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
    Key? key,
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
    this.onSeek,
    required this.repeatMode,
    required this.shuffleMode,
    this.onRepeatPressed,
    this.onShufflePressed,
  }) : super(key: key);

  @override
  _MusicPlayerWidgetState createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late Duration _currentPosition;
  Timer? _progressTimer;
  // Local copies of repeat and shuffle mode.
  late String _repeatMode;
  late bool _shuffleMode;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _repeatMode = widget.repeatMode;
    _shuffleMode = widget.shuffleMode;
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
        // If the current position reaches or exceeds the total duration...
        if (_currentPosition >= widget.totalDuration) {
          // If the player is still playing (i.e. next track started),
          // reset _currentPosition to zero; otherwise, stop the timer.
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
        // Parent is responsible for updating the shuffleMode.
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
        // Parent is responsible for updating the repeatMode.
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

  @override
  Widget build(BuildContext context) {
    if (widget.layoutType == PlayerLayoutType.compact) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Top-left alignment.
            children: [
              // Album Art placed on top left.
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
              // Song info and controls.
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
                        _buildShuffledButton(), // Left-aligned.
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
                        _buildRepeatButton(), // Right-aligned.
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Expanded layout.
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
              _buildShuffledButton(), // Left-aligned.
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
              _buildRepeatButton(), // Right-aligned.
            ],
          ),
        ],
      );
    }
  }
}
