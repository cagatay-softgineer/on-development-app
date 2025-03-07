import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/custom_button.dart';
import 'styles/button_styles.dart';
import 'dart:async';
import 'package:ssdk_rsrc/api_service.dart';
import 'authlib.dart';
import 'widgets/music_player.dart';
import 'models/playlist.dart';

class CustomTimerPage extends StatefulWidget {
  const CustomTimerPage({Key? key}) : super(key: key);

  @override
  _CustomTimerPageState createState() => _CustomTimerPageState();
}

class _CustomTimerPageState extends State<CustomTimerPage> {
  String? userID = "";
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  bool _isLoadingPlaylists = true;

  // Pomodoro Timer State Variables
  Timer? _pomodoroTimer;
  Duration _pomodoroRemaining = Duration.zero;
  bool _isWorkPhase = true;
  int _sessionCount = 0;
  Duration _workDuration = Duration.zero;
  Duration _shortBreakDuration = Duration.zero;
  Duration _longBreakDuration = Duration.zero;

  // Time selector values (in minutes and count)
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 30;
  int _sessionsBeforeLongBreak = 4;

  // Control for expansion toggle.
  bool _isTimeSelectorExpanded = false;

  final ApiService apiService = ApiService();
  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // Local state for repeat and shuffle modes.
  String _currentRepeatMode = "off"; // possible values: "off", "track", "context"
  bool _currentShuffleMode = false;
  bool focusMode = false;

  // GlobalKey for the MusicPlayerWidget.
  final GlobalKey<MusicPlayerWidgetState> _musicPlayerKey =
      GlobalKey<MusicPlayerWidgetState>();

  String get formattedPomodoroTime {
    final minutes = _pomodoroRemaining.inMinutes.remainder(60).toString();
    final seconds =
        _pomodoroRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --------------------------------------------------------------
  Future<void> _initializeUserAndPlaylists() async {
    try {
      final uid = await AuthService.getUserId();
      setState(() {
        userID = uid;
      });
      final fetchedPlaylists = await mainAPI.fetchPlaylists("$uid");
      setState(() {
        _playlists = fetchedPlaylists;
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      print("Error fetching userID or playlists: $e");
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  // Helper function to extract the first available device ID.
  String extractFirstDeviceId(Map<String, dynamic> response) {
    if (response.containsKey('devices') && response['devices'] is List) {
      List<dynamic> devices = response['devices'];
      if (devices.isNotEmpty) {
        Map<String, dynamic> firstDevice = devices[0];
        if (firstDevice.containsKey('id') && firstDevice['id'] is String) {
          return firstDevice['id'];
        } else {
          return 'Device ID not found or is not a string.';
        }
      } else {
        return 'No devices available.';
      }
    } else {
      return 'Invalid response format: "devices" key missing or not a list.';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData().then((_) {
      _startStateCheckTimer();
      _initializeUserAndPlaylists();
    });
  }

  Future<void> _initializeData() async {
    try {
      final userId = await AuthService.getUserId();
      setState(() {
        userID = userId;
        _playerFuture = spotifyAPI.getPlayer(userID);
      });
    } catch (e) {
      print("Error fetching userID: $e");
    }
  }

  /// Starts a periodic timer to check the player state every 4 seconds.
  void _startStateCheckTimer() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (userID != null && userID!.isNotEmpty) {
        try {
          final newData = await spotifyAPI.getPlayer(userID);
          // ignore: unnecessary_null_comparison
          if (newData != null && newData['item'] != null) {
            final String newRepeat = newData["repeat_state"] ?? "off";
            final bool newShuffle = newData["shuffle_state"] ?? false;
            if (_currentRepeatMode != newRepeat ||
                _currentShuffleMode != newShuffle) {
              setState(() {
                _currentRepeatMode = newRepeat;
                _currentShuffleMode = newShuffle;
              });
            }
            setState(() {
              _playerFuture = Future.value(newData);
              _lastPlayerData = newData;
            });
          }
        } catch (e) {
          print("Error in state check: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  Widget _buildPlayerWidget(Map<String, dynamic> data) {
    final String repeatState = data["repeat_state"] ?? "off";
    final bool shuffleState = data["shuffle_state"] ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentRepeatMode != repeatState ||
          _currentShuffleMode != shuffleState) {
        setState(() {
          _currentRepeatMode = repeatState;
          _currentShuffleMode = shuffleState;
        });
      }
    });

    final track = data['item'];
    final album = track['album'];
    final String albumArtUrl = (album['images'] as List).isNotEmpty
        ? album['images'][0]['url']
        : 'https://via.placeholder.com/300';
    final String songTitle = track['name'] ?? 'Song Title';
    final String artistName = (track['artists'] as List).isNotEmpty
        ? track['artists'][0]['name']
        : 'Artist Name';
    final Duration currentPosition =
        Duration(milliseconds: data['progress_ms'] ?? 0);
    final Duration totalDuration =
        Duration(milliseconds: track['duration_ms'] ?? 0);
    final bool isPlaying = data['is_playing'] ?? false;

    return MusicPlayerWidget(
      key: _musicPlayerKey,
      layoutType: PlayerLayoutType.compact,
      albumArtUrl: albumArtUrl,
      songTitle: songTitle,
      artistName: artistName,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      isPlaying: isPlaying,
      repeatMode: _currentRepeatMode,
      shuffleMode: _currentShuffleMode,
      isDynamic: false,
      onPlayPausePressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        if (isPlaying) {
          await spotifyAPI.pausePlayer(userID, deviceId);
        } else {
          await spotifyAPI.resumePlayer(userID, deviceId);
        }
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onNextPressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.skipToNext(userID, deviceId);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onPreviousPressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.skipToPrevious(userID, deviceId);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onSeek: (newPosition) async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        await spotifyAPI.seekToPosition(
            userID, deviceId, newPosition.inMilliseconds.toString());
      },
      onRepeatPressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        String newMode;
        if (repeatState == "off") {
          newMode = "track";
        } else if (repeatState == "track") {
          newMode = "context";
        } else {
          newMode = "off";
        }
        await spotifyAPI.setRepeatMode(userID, deviceId, newMode);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
      onShufflePressed: () async {
        final response = await spotifyAPI.getDevices(userID);
        final String deviceId = extractFirstDeviceId(response);
        bool newShuffle = !shuffleState;
        await spotifyAPI.setShuffleMode(userID, deviceId, newShuffle);
        setState(() {
          _playerFuture = spotifyAPI.getPlayer(userID);
        });
      },
    );
  }

  // -------------------- Pomodoro Timer Methods --------------------
  Future<void> startPomodoroSession({
    required Duration workDuration,
    required Duration shortBreak,
    required Duration longBreak,
  }) async {
    // Cancel any existing timer.
    _pomodoroTimer?.cancel();
    setState(() {
      _workDuration = workDuration;
      _shortBreakDuration = shortBreak;
      _longBreakDuration = longBreak;
      _isWorkPhase = true;
      _sessionCount = 0;
      _pomodoroRemaining = workDuration;
    });
    // Switch the player layout to focus mode.
    _musicPlayerKey.currentState?.switchLayout(PlayerLayoutType.focus);

    // If a playlist is selected, start playing it.
    if (_selectedPlaylist != null && userID != null && userID!.isNotEmpty) {
      final response = await spotifyAPI.getDevices(userID);
      final String deviceId = extractFirstDeviceId(response);
      await spotifyAPI.playPlaylist(
          _selectedPlaylist!.playlistId, userID, deviceId);
    }

    _pomodoroTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickPomodoro();
      _initializeData();
    });
  }

  Future<void> _tickPomodoro() async {
    if (_pomodoroRemaining.inSeconds > 0) {
      setState(() {
        _pomodoroRemaining =
            Duration(seconds: _pomodoroRemaining.inSeconds - 1);
      });
    } else {
      if (_isWorkPhase) {
        _sessionCount++;
        // Use the user-specified count to decide if it’s time for a long break.
        if (_sessionCount % _sessionsBeforeLongBreak == 0) {
          setState(() {
            _pomodoroRemaining = _longBreakDuration;
          });
        } else {
          setState(() {
            _pomodoroRemaining = _shortBreakDuration;
          });
        }
        if (userID != null && userID!.isNotEmpty) {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          await spotifyAPI.pausePlayer(userID, deviceId);
        }
      } else {
        setState(() {
          _pomodoroRemaining = _workDuration;
        });
        if (userID != null && userID!.isNotEmpty) {
          final response = await spotifyAPI.getDevices(userID);
          final String deviceId = extractFirstDeviceId(response);
          await spotifyAPI.skipToNext(userID, deviceId);
          await spotifyAPI.resumePlayer(userID, deviceId);
        }
      }
      setState(() {
        _isWorkPhase = !_isWorkPhase;
      });
    }
  }

  Future<void> stopPomodoro() async {
    _musicPlayerKey.currentState?.switchLayout(PlayerLayoutType.compact);
    _pomodoroTimer?.cancel();
    // Also pause the player.
    if (userID != null && userID!.isNotEmpty) {
      final response = await spotifyAPI.getDevices(userID);
      final String deviceId = extractFirstDeviceId(response);
      await spotifyAPI.pausePlayer(userID, deviceId);
    }
  }

  Future<void> _showStopConfirmation(BuildContext context) async {
    if (_pomodoroTimer != null && _pomodoroTimer!.isActive) {
      final shouldStop = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Stop Session'),
            content:
                const Text('Are you sure you want to stop the session?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Stop'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
      if (shouldStop == true) {
        await stopPomodoro();
      }
    } else {
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Stop Session'),
            content: const Text(
                'Session is already stopped or not started yet!'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _isWorkPhase ? 'Work Time' : 'Break Time',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedPomodoroTime,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Playlist Dropdown remains unchanged.
                _isLoadingPlaylists
                    ? const CircularProgressIndicator()
                    : DropdownButton<Playlist>(
                        hint: const Text("Select Playlist"),
                        value: _selectedPlaylist,
                        isExpanded: true,
                        items: _playlists.map((playlist) {
                          return DropdownMenuItem<Playlist>(
                            value: playlist,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(playlist.playlistImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlist.playlistName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        playlist.playlistOwner,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Playlist? newPlaylist) {
                          setState(() {
                            _selectedPlaylist = newPlaylist;
                          });
                        },
                      ),
                const SizedBox(height: 20),
                // Expandable Timer Settings Section using Pie Chart Selectors.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: const Text(
                      'Timer Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _isTimeSelectorExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isTimeSelectorExpanded = expanded;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            PieTimeSelector(
                              label: 'Work (min)',
                              value: _workMinutes,
                              min: 10,
                              max: 120,
                              onChanged: (val) {
                                setState(() {
                                  _workMinutes = val;
                                });
                              },
                            ),
                            PieTimeSelector(
                              label: 'Short Break (min)',
                              value: _shortBreakMinutes,
                              min: 1,
                              max: 30,
                              onChanged: (val) {
                                setState(() {
                                  _shortBreakMinutes = val;
                                });
                              },
                            ),
                            PieTimeSelector(
                              label: 'Long Break (min)',
                              value: _longBreakMinutes,
                              min: 5,
                              max: 60,
                              onChanged: (val) {
                                setState(() {
                                  _longBreakMinutes = val;
                                });
                              },
                            ),
                            PieTimeSelector(
                              label: 'Sessions',
                              value: _sessionsBeforeLongBreak,
                              min: 1,
                              max: 10,
                              onChanged: (val) {
                                setState(() {
                                  _sessionsBeforeLongBreak = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start Timer button.
                    CustomButton(
                      text: "Start Timer",
                      onPressed: () async {
                        if (_pomodoroTimer == null ||
                            !_pomodoroTimer!.isActive) {
                          await startPomodoroSession(
                            workDuration: Duration(minutes: _workMinutes),
                            shortBreak:
                                Duration(minutes: _shortBreakMinutes),
                            longBreak: Duration(minutes: _longBreakMinutes),
                          );
                        } else {
                          await _showStopConfirmation(context);
                        }
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                    const SizedBox(width: 10),
                    // Stop Timer button.
                    CustomButton(
                      text: "Stop Timer",
                      onPressed: () async {
                        await _showStopConfirmation(context);
                      },
                      buttonParams: stopSessionSmallButtonParams,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Change Player Layout button.
                CustomButton(
                  text: "Change Player Type",
                  onPressed: () {
                    if (_musicPlayerKey.currentState != null) {
                      if (focusMode) {
                        _musicPlayerKey.currentState!
                            .switchLayout(PlayerLayoutType.compact);
                        focusMode = false;
                      } else {
                        _musicPlayerKey.currentState!
                            .switchLayout(PlayerLayoutType.focus);
                        focusMode = true;
                      }
                    }
                  },
                  buttonParams: changeLayoutButtonParams,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _playerFuture,
        builder: (context, snapshot) {
          Widget content;
          if (snapshot.connectionState == ConnectionState.waiting) {
            content = _lastPlayerData != null
                ? _buildPlayerWidget(_lastPlayerData!)
                : const Center(child: Text('Loading...'));
          } else if (snapshot.hasError) {
            content = _lastPlayerData != null
                ? _buildPlayerWidget(_lastPlayerData!)
                : Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['item'] == null) {
            content = _lastPlayerData != null
                ? _buildPlayerWidget(_lastPlayerData!)
                : const Center(child: Text('No track is currently playing.'));
          } else {
            _lastPlayerData = snapshot.data;
            content = _buildPlayerWidget(snapshot.data!);
          }
          return Container(
            height: 210,
            child: content,
          );
        },
      ),
    );
  }
}

// -------------------- PieTimeSelector Widget --------------------
class PieTimeSelector extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const PieTimeSelector({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PieTimeSelectorState createState() => _PieTimeSelectorState();
}

class _PieTimeSelectorState extends State<PieTimeSelector> {
  // Calculate the angle based on the current value.
  double get angle => ((widget.value - widget.min) / (widget.max - widget.min)) * 2 * pi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        Offset center = renderBox.size.center(Offset.zero);
        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        double dx = localPosition.dx - center.dx;
        double dy = localPosition.dy - center.dy;
        double theta = atan2(dy, dx);
        if (theta < 0) theta += 2 * pi;
        int newValue = (widget.min + (theta / (2 * pi)) * (widget.max - widget.min)).round();
        newValue = newValue.clamp(widget.min, widget.max);
        widget.onChanged(newValue);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _PieTimePainter(angle: angle),
              child: Center(
                child: Text('${widget.value}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieTimePainter extends CustomPainter {
  final double angle;
  _PieTimePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 10;
    Offset center = size.center(Offset.zero);
    double radius = (size.width / 2) - strokeWidth;
    Paint basePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, basePaint);
    Paint progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Draw arc starting at the top (-pi/2).
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, angle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _PieTimePainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}