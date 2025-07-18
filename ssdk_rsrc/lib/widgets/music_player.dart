// ignore_for_file: avoid_unnecessary_containers

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/styles/color_palette.dart';
import 'package:ssdk_rsrc/widgets/custom_player_bar.dart';
import 'package:ssdk_rsrc/widgets/glowing_icon.dart';

enum PlayerLayoutType { compact, expanded, focus }

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
  final MusicApp currentApp;

  final bool onPomodoroPage;

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
    this.onPomodoroPage = false,
    required this.repeatMode,
    required this.shuffleMode,
    this.onRepeatPressed,
    this.onShufflePressed,
    required this.currentApp,
  });

  @override
  MusicPlayerWidgetState createState() => MusicPlayerWidgetState();

  static void switchLayout(PlayerLayoutType compact) {}
  static void switchColor(MusicApp currentApp) {}
}

class MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late Duration _currentPosition;
  Timer? _progressTimer;
  // Local copies of repeat and shuffle mode.
  late String _repeatMode;
  late bool _shuffleMode;
  late bool _isDynamic;
  late MusicApp _currentApp;
  late Color currentAppColor;

  // Use a state variable to control the current layout.
  // ignore: unused_field
  late PlayerLayoutType _currentLayout;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _repeatMode = widget.repeatMode;
    _shuffleMode = widget.shuffleMode;
    _isDynamic = widget.isDynamic;
    _currentLayout = widget.layoutType;
    _currentApp = widget.currentApp;
    if (widget.isPlaying) {
      _startProgressTimer();
    }
    switchColor(_currentApp);
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
  // ignore: unused_element
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

  // ignore: unused_element
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

  Widget _buildSkipPrevButton(double iconSize) {
    return GlowingIconButton(
      icon: FontAwesomeIcons.backwardStep,
      iconSize: iconSize,
      iconColor: ColorPalette.white,
      iconGlowColor: ColorPalette.white.withAlpha(64),
      onPressed: () async {
        await widget.onPreviousPressed();
        setState(() {
          _currentPosition = Duration.zero;
        });
      },
    );
  }

  Widget _buildPlayPauseButton(double iconSize, {bool isCompact = false}) {
    return GlowingIconButton(
      icon: widget.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
      iconSize: iconSize,
      iconColor: ColorPalette.white,
      iconGlowColor:
          isCompact
              ? ColorPalette.backgroundColor.withAlpha(255)
              : ColorPalette.white.withAlpha(64),
      onPressed: () async {
        await widget.onPlayPausePressed();
      },
    );
  }

  Widget _buildSkipNextButton(double iconSize) {
    return GlowingIconButton(
      icon: FontAwesomeIcons.forwardStep,
      iconSize: iconSize,
      iconColor: ColorPalette.white,
      iconGlowColor: ColorPalette.white.withAlpha(64),
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

  void switchColor(MusicApp currentApp) {
    if (currentApp == MusicApp.Spotify) {
      setState(() {
        currentAppColor = Spotify.green;
      });
    }
  }

  Color getAppColor(MusicApp currentApp) {
    if (currentApp == MusicApp.Spotify) {
      return Spotify.green;
    }
    return Spotify.green;
  }

  IconData getAppIcon(MusicApp currentApp) {
    if (currentApp == MusicApp.Spotify) {
      return FontAwesomeIcons.spotify;
    }
    return FontAwesomeIcons.borderNone;
  }

  /// Internal helper to toggle/cycle through the layouts.
  // ignore: unused_element
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
    if (_currentLayout == PlayerLayoutType.expanded) {
      return expandedLayout(context);
    } else if (_currentLayout == PlayerLayoutType.compact) {
      return compactLayout(context);
    } else if (_currentLayout == PlayerLayoutType.focus) {
      return focusLayout(context);
    } else {
      return expandedLayout(context);
    }

    // if (_currentLayout == PlayerLayoutType.compact) {
    //   return Card(
    //     color: Transparent.a00,
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //     child: Padding(
    //       padding: const EdgeInsets.all(12.0),
    //       child: Row(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           // Album Art
    //           Container(
    //             width: 50,
    //             height: 50,
    //             decoration: BoxDecoration(
    //               borderRadius: BorderRadius.circular(4),
    //               image: DecorationImage(
    //                 image: NetworkImage(widget.albumArtUrl),
    //                 fit: BoxFit.cover,
    //               ),
    //             ),
    //           ),
    //           const SizedBox(width: 12),
    //           // Song Info and Controls
    //           Expanded(
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   widget.songTitle,
    //                   style: const TextStyle(fontWeight: FontWeight.bold),
    //                 ),
    //                 Text(
    //                   widget.artistName,
    //                   style: const TextStyle(color: Colors.grey),
    //                 ),
    //                 Row(
    //                   children: [
    //                     Text(
    //                       _formatDuration(_currentPosition),
    //                       style: const TextStyle(fontSize: 12),
    //                     ),
    //                     Expanded(
    //                       child: Slider(
    //                         value: _currentPosition.inSeconds.toDouble(),
    //                         max: widget.totalDuration.inSeconds.toDouble(),
    //                         onChanged: (value) {
    //                           setState(() {
    //                             _currentPosition = Duration(
    //                               seconds: value.toInt(),
    //                             );
    //                           });
    //                         },
    //                         onChangeEnd: (value) async {
    //                           if (widget.onSeek != null) {
    //                             await widget.onSeek!(
    //                               Duration(seconds: value.toInt()),
    //                             );
    //                           }
    //                         },
    //                       ),
    //                     ),
    //                     Text(
    //                       _formatDuration(widget.totalDuration),
    //                       style: const TextStyle(fontSize: 12),
    //                     ),
    //                   ],
    //                 ),
    //                 Row(
    //                   children: [
    //                     _buildShuffledButton(),
    //                     Expanded(
    //                       child: Row(
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                         children: [
    //                           _buildSkipPrevButton(),
    //                           _buildPlayPauseButton(),
    //                           _buildSkipNextButton(),
    //                         ],
    //                       ),
    //                     ),
    //                     _buildRepeatButton(),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // } else if (_currentLayout == PlayerLayoutType.expanded) {
    //   return Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Container(
    //         width: 200,
    //         height: 200,
    //         decoration: BoxDecoration(
    //           color: Transparent.a00,
    //           borderRadius: BorderRadius.circular(8),
    //           image: DecorationImage(
    //             image: NetworkImage(widget.albumArtUrl),
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //       ),
    //       const SizedBox(height: 16),
    //       Text(
    //         widget.songTitle,
    //         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    //       ),
    //       Text(
    //         widget.artistName,
    //         style: const TextStyle(fontSize: 16, color: Colors.grey),
    //       ),
    //       const SizedBox(height: 16),
    //       Row(
    //         children: [
    //           const SizedBox(width: 16),
    //           Text(_formatDuration(_currentPosition)),
    //           Expanded(
    //             child: Slider(
    //               value: _currentPosition.inSeconds.toDouble(),
    //               max: widget.totalDuration.inSeconds.toDouble(),
    //               onChanged: (value) {
    //                 setState(() {
    //                   _currentPosition = Duration(seconds: value.toInt());
    //                 });
    //               },
    //               onChangeEnd: (value) async {
    //                 if (widget.onSeek != null) {
    //                   await widget.onSeek!(Duration(seconds: value.toInt()));
    //                 }
    //               },
    //             ),
    //           ),
    //           Text(_formatDuration(widget.totalDuration)),
    //           const SizedBox(width: 16),
    //         ],
    //       ),
    //       Row(
    //         children: [
    //           _buildShuffledButton(),
    //           Expanded(
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 _buildSkipPrevButton(),
    //                 _buildPlayPauseButton(),
    //                 _buildSkipNextButton(),
    //               ],
    //             ),
    //           ),
    //           _buildRepeatButton(),
    //         ],
    //       ),
    //     ],
    //   );
    // } else {
    //   // For the 'focus' layout (or any other layout), adjust as needed.
    //   return Card(
    //     color: Transparent.a00,
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //     child: Padding(
    //       padding: const EdgeInsets.all(12.0),
    //       child: Row(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           // Album Art
    //           Container(
    //             width: 150,
    //             height: 150,
    //             decoration: BoxDecoration(
    //               borderRadius: BorderRadius.circular(4),
    //               image: DecorationImage(
    //                 image: NetworkImage(widget.albumArtUrl),
    //                 fit: BoxFit.cover,
    //               ),
    //             ),
    //           ),
    //           const SizedBox(width: 12),
    //           // Song Info (simplified)
    //           Expanded(
    //             child: Center(
    //               child: Column(
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: [
    //                   Text(
    //                     widget.songTitle,
    //                     style: const TextStyle(
    //                       fontSize: 18,
    //                       fontWeight: FontWeight.bold,
    //                     ),
    //                     textAlign: TextAlign.center, // Center-align the text
    //                   ),
    //                   Text(
    //                     widget.artistName,
    //                     style: const TextStyle(
    //                       fontSize: 14,
    //                       color: Colors.grey,
    //                     ),
    //                     textAlign: TextAlign.center, // Center-align the text
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }
  }

  Widget expandedLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ColorPalette.backgroundColor,
                  border: BorderDirectional(
                    top: BorderSide(color: getAppColor(_currentApp)),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200),
                    topRight: Radius.circular(200),
                  ),
                  boxShadow: [
                    BoxShadow(color: getAppColor(_currentApp), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowingIconButton(
                      onPressed: () {
                        _toggleLayout();
                      },
                      iconSize: 72,
                      icon: getAppIcon(_currentApp),
                      iconColor: getAppColor(_currentApp),
                      iconGlowColor: getAppColor(_currentApp).withAlpha(64),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: 400,
                      height: 400,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Transparent.a77, blurRadius: 30),
                        ],
                        color: Transparent.a00,
                        border: Border.all(
                          color: ColorPalette.white.withAlpha(50),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(150),
                          topRight: Radius.circular(150),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(widget.albumArtUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.songTitle,
                      style: TextStyle(
                        color: ColorPalette.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.artistName,
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorPalette.lightGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0, // Thin track
                            inactiveTrackColor: ColorPalette.lightGray,
                            activeTrackColor: ColorPalette.white,
                            trackShape: CustomCenterGlowTrackShape(),
                            thumbShape: CustomGlowThumbShape(),
                            thumbColor: ColorPalette.gold.withAlpha(128),
                            overlayColor: ColorPalette.gold.withAlpha(50),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 0,
                            ),
                            // Remove overlay for a cleaner look
                          ),
                          child: Expanded(
                            child: Slider(
                              value: _currentPosition.inSeconds.toDouble(),
                              max: widget.totalDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _currentPosition = Duration(
                                    seconds: value.toInt(),
                                  );
                                });
                              },
                              onChangeEnd: (value) async {
                                if (widget.onSeek != null) {
                                  await widget.onSeek!(
                                    Duration(seconds: value.toInt()),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                        Text(
                          "  /  ",
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    SizedBox(height: 50),
                    Row(
                      children: [
                        // _buildShuffledButton(),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSkipPrevButton(60),
                              _buildPlayPauseButton(96),
                              _buildSkipNextButton(60),
                            ],
                          ),
                        ),
                        // _buildRepeatButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget compactLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor.withAlpha(0),
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ColorPalette.backgroundColor,
                  border: BorderDirectional(
                    top: BorderSide(color: getAppColor(_currentApp)),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                  boxShadow: [
                    BoxShadow(color: getAppColor(_currentApp), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.onPomodoroPage
                        ? SizedBox(height: 5)
                        : GlowingIconButton(
                          onPressed: () {
                            _toggleLayout();
                          },
                          iconSize: 24,
                          icon: getAppIcon(_currentApp),
                          iconColor: getAppColor(_currentApp),
                          iconGlowColor: getAppColor(_currentApp).withAlpha(64),
                        ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSkipPrevButton(20),
                              Container(
                                width: 100,
                                height: 100,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Transparent.a77,
                                      blurRadius: 30,
                                    ),
                                  ],
                                  color: Transparent.a00,
                                  border: Border.all(
                                    color: ColorPalette.white.withAlpha(50),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                    topRight: Radius.circular(50),
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(widget.albumArtUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: _buildPlayPauseButton(
                                  32,
                                  isCompact: true,
                                ),
                              ),
                              _buildSkipNextButton(20),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.songTitle,
                      style: TextStyle(
                        color: ColorPalette.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.artistName,
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorPalette.lightGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0, // Thin track
                            inactiveTrackColor: ColorPalette.lightGray,
                            activeTrackColor: ColorPalette.white,
                            trackShape: CustomCenterGlowTrackShape(),
                            thumbShape: CustomGlowThumbShape(),
                            thumbColor: ColorPalette.gold.withAlpha(128),
                            overlayColor: ColorPalette.gold.withAlpha(50),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 0,
                            ),
                            // Remove overlay for a cleaner look
                          ),
                          child: Expanded(
                            child: Slider(
                              value: _currentPosition.inSeconds.toDouble(),
                              max: widget.totalDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _currentPosition = Duration(
                                    seconds: value.toInt(),
                                  );
                                });
                              },
                              onChangeEnd: (value) async {
                                if (widget.onSeek != null) {
                                  await widget.onSeek!(
                                    Duration(seconds: value.toInt()),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                        Text(
                          "  /  ",
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorPalette.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget focusLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor.withAlpha(0),
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ColorPalette.backgroundColor,
                  border: BorderDirectional(
                    top: BorderSide(color: getAppColor(_currentApp)),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200),
                    topRight: Radius.circular(200),
                  ),
                  boxShadow: [
                    BoxShadow(color: getAppColor(_currentApp), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.onPomodoroPage
                        ? SizedBox(height: 5)
                        : GlowingIconButton(
                          onPressed: () {
                            _toggleLayout();
                          },
                          iconSize: 24,
                          icon: getAppIcon(_currentApp),
                          iconColor: getAppColor(_currentApp),
                          iconGlowColor: getAppColor(_currentApp).withAlpha(64),
                        ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Transparent.a77,
                                      blurRadius: 30,
                                    ),
                                  ],
                                  color: Transparent.a00,
                                  border: Border.all(
                                    color: ColorPalette.white.withAlpha(50),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(150),
                                    topRight: Radius.circular(150),
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(widget.albumArtUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.songTitle,
                      style: TextStyle(
                        color: ColorPalette.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.artistName,
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorPalette.lightGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     SliderTheme(
                    //       data: SliderTheme.of(context).copyWith(
                    //         trackHeight: 4.0, // Thin track
                    //         inactiveTrackColor: ColorPalette.lightGray,
                    //         activeTrackColor: ColorPalette.white,
                    //         trackShape: CustomCenterGlowTrackShape(),
                    //         thumbShape: CustomGlowThumbShape(),
                    //         thumbColor: ColorPalette.gold.withAlpha(128),
                    //         overlayColor: ColorPalette.gold.withAlpha(50),
                    //         overlayShape: RoundSliderOverlayShape(
                    //           overlayRadius: 0,
                    //         ),
                    //         // Remove overlay for a cleaner look
                    //       ),
                    //       child: Expanded(
                    //         child: Slider(
                    //           value: _currentPosition.inSeconds.toDouble(),
                    //           max: widget.totalDuration.inSeconds.toDouble(),
                    //           onChanged: (value) {
                    //             setState(() {
                    //               _currentPosition = Duration(
                    //                 seconds: value.toInt(),
                    //               );
                    //             });
                    //           },
                    //           onChangeEnd: (value) async {
                    //             if (widget.onSeek != null) {
                    //               await widget.onSeek!(
                    //                 Duration(seconds: value.toInt()),
                    //               );
                    //             }
                    //           },
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 5),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(
                    //       _formatDuration(_currentPosition),
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         color: ColorPalette.white,
                    //       ),
                    //     ),
                    //     Text(
                    //       "  /  ",
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         color: ColorPalette.white,
                    //       ),
                    //     ),
                    //     Text(
                    //       _formatDuration(widget.totalDuration),
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         color: ColorPalette.white,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the player content in a Stack so we can overlay a toggle button.
    if (_isDynamic) {
      return Scaffold(
        backgroundColor: Transparent.a00,
        body: SafeArea(
          child: Stack(
            children: [
              _buildPlayerContent(),
              // Positioned(
              //   top: 0,
              //   right: 0,
              //   child: IconButton(
              //     icon: const Icon(Icons.swap_horiz),
              //     onPressed: _toggleLayout,
              //     tooltip: 'Change Layout',
              //   ),
              // ),
            ],
          ),
        ),
      );
    } else {
      return Stack(children: [_buildPlayerContent()]);
    }
  }
}
