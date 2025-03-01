import 'package:flutter/material.dart';
import 'widgets/custom_button.dart';
import 'styles/button_styles.dart';
import 'dart:async';
import 'package:ssdk_rsrc/api_service.dart';
import 'authlib.dart';
import 'widgets/music_player.dart';
import 'models/playlist.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
    String? userID = "";
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  bool _isLoadingPlaylists = true;

  // Pomodoro Timer State Variables
  Timer? _pomodoroTimer;
  Duration _pomodoroRemaining = Duration.zero;
  bool _isWorkPhase = true;
  int _sessionCount = 0;
  // ignore: unused_field
  Duration _workDuration = Duration.zero;
  // ignore: unused_field
  Duration _shortBreakDuration = Duration.zero;
  // ignore: unused_field
  Duration _longBreakDuration = Duration.zero;

  final ApiService apiService = ApiService();
  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // Local state for repeat and shuffle modes.
  String _currentRepeatMode = "off"; // possible values: "off", "track", "context"
  bool _currentShuffleMode = false;
  bool focusMode = false;

  // Create a GlobalKey to access MusicPlayerWidget's state.
  final GlobalKey<MusicPlayerWidgetState> _musicPlayerKey =
      GlobalKey<MusicPlayerWidgetState>();

  String get formattedPomodoroTime {
    final minutes = _pomodoroRemaining.inMinutes.remainder(60).toString();
    final seconds = _pomodoroRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
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
            if (_currentRepeatMode != newRepeat || _currentShuffleMode != newShuffle) {
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
      if (_currentRepeatMode != repeatState || _currentShuffleMode != shuffleState) {
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
      key: _musicPlayerKey, // Pass the GlobalKey here.
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
      final deviceId = extractFirstDeviceId(response);
      await spotifyAPI.playPlaylist(_selectedPlaylist!.playlistId, userID, deviceId);
    }

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickPomodoro();
      _initializeData();
    });
  }

  Future<void> _tickPomodoro() async {
    if (_pomodoroRemaining.inSeconds > 0) {
      setState(() {
        _pomodoroRemaining = Duration(seconds: _pomodoroRemaining.inSeconds - 1);
      });
    } else {
      if (_isWorkPhase) {
        _sessionCount++;
        // After 4 work sessions, use long break.
        if (_sessionCount % 4 == 0) {
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
          final deviceId = extractFirstDeviceId(response);
          await spotifyAPI.pausePlayer(userID, deviceId);
        }
      } else {
        setState(() {
          _pomodoroRemaining = _workDuration;
        });
        if (userID != null && userID!.isNotEmpty) {
          final response = await spotifyAPI.getDevices(userID);
          final deviceId = extractFirstDeviceId(response);
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
      final deviceId = extractFirstDeviceId(response);
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
            content: const Text('Are you sure you want to stop session?'),
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
            content: const Text('Session is already stopped or not started yet!'),
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

  // ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //const SizedBox(height: 40),
                const Text(
                  'Pomodoro Timer',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Display the current session phase and time remaining.
                Text(
                  _isWorkPhase ? 'Work Time' : 'Break Time',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedPomodoroTime,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Playlist Dropdown
                _isLoadingPlaylists
                ? const CircularProgressIndicator()
                : DropdownButton<Playlist>(
                    hint: const Text("Select Playlist"),
                    value: _selectedPlaylist,
                    isExpanded: true, // Ensures the dropdown uses the available width
                    items: _playlists.map((playlist) {
                      return DropdownMenuItem<Playlist>(
                        value: playlist,
                        child: Row(
                          children: [
                            // Playlist Image
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(playlist.playlistImage),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Playlist Name and Owner
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.playlistName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    playlist.playlistOwner,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                // Session start buttons.
                CustomButton(
                  text: "25/5 Session",
                  onPressed: () async {
                    if (_pomodoroTimer == null) {
                      await startPomodoroSession(
                        workDuration: const Duration(minutes: 25),
                        shortBreak: const Duration(minutes: 5),
                        longBreak: const Duration(minutes: 30),
                      );
                    } else if (_pomodoroTimer!.isActive) {
                      await _showStopConfirmation(context);
                    } else {
                      await startPomodoroSession(
                        workDuration: const Duration(minutes: 25),
                        shortBreak: const Duration(minutes: 5),
                        longBreak: const Duration(minutes: 30),
                      );
                    }
                  },
                  buttonParams: startSessionButtonParams,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "40/10 Session",
                  onPressed: () async {
                    if (_pomodoroTimer == null) {
                      await startPomodoroSession(
                        workDuration: const Duration(minutes: 40),
                        shortBreak: const Duration(minutes: 10),
                        longBreak: const Duration(minutes: 30),
                      );
                    } else if (_pomodoroTimer!.isActive) {
                      await _showStopConfirmation(context);
                    } else {
                      await startPomodoroSession(
                        workDuration: const Duration(minutes: 40),
                        shortBreak: const Duration(minutes: 10),
                        longBreak: const Duration(minutes: 30),
                      );
                    }
                  },
                  buttonParams: startSessionButtonParams,
                ),
                const SizedBox(height: 20),
                // Stop Timer button.
                CustomButton(
                  text: "Stop Timer",
                  onPressed: () async {
                    await _showStopConfirmation(context);
                  },
                  buttonParams: stopSessionButtonParams,
                ),
                const SizedBox(height: 20),
                // Change Player Type button.
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
                const SizedBox(height: 20),
                CustomButton(
                  text: "Debug Session",
                  onPressed: () async {
                    if (_pomodoroTimer == null) {
                      await startPomodoroSession(
                        workDuration: const Duration(seconds: 10),
                        shortBreak: const Duration(seconds: 5),
                        longBreak: const Duration(seconds: 10),
                      );
                    } else if (_pomodoroTimer!.isActive) {
                      await _showStopConfirmation(context);
                    } else {
                      await startPomodoroSession(
                        workDuration: const Duration(seconds: 10),
                        shortBreak: const Duration(seconds: 5),
                        longBreak: const Duration(seconds: 10),
                      );
                    }
                  },
                  buttonParams: startSessionButtonParams,
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
            height: 210, // Fixed height for your player widget.
            child: content,
          );
        },
      ),
    );
  }
}
