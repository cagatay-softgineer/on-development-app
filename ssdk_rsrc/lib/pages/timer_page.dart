import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'dart:async';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/utils/timer_funcs.dart'; // Timer utilities (e.g. player state functions)
import 'package:ssdk_rsrc/utils/pomodoro_funcs.dart'; // Pomodoro mixin
import 'package:ssdk_rsrc/widgets/player_widget.dart'; // Custom player widget
import 'package:ssdk_rsrc/models/music_player.dart'; // Custom player widget
import 'package:ssdk_rsrc/utils/spotify_func.dart'; //spotify

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with PomodoroMixin {
  String? userID = "";
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  bool _isLoadingPlaylists = true;

  // User-configurable timer values.
  bool focusMode = false;
  
  late final SpotifyPlayerController spotifyPlayerController;
  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // GlobalKey for the MusicPlayerWidget.
  final GlobalKey<MusicPlayerWidgetState> _musicPlayerKey =
      GlobalKey<MusicPlayerWidgetState>();

  String get formattedPomodoroTime {
    final minutes = pomodoroRemaining.inMinutes.remainder(60).toString();
    final seconds = pomodoroRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _initializeData() async {
    await initializeData(
      updateUserId: (id) => setState(() => userID = id),
      updatePlayerFuture: (future) => setState(() => _playerFuture = future),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeData().then((_) {
      _stateCheckTimer = startStateCheckTimer(
        userID: userID ?? "",
        updatePlayerData: (data) {
          setState(() {
            _playerFuture = Future.value(data);
            _lastPlayerData = data;
          });
        },
        updateRepeatMode: (mode) {
          // Optionally update UI state for repeat mode.
        },
        updateShuffleMode: (shuffle) {
          // Optionally update UI state for shuffle mode.
        },
      );
      initializeUserAndPlaylists(
        updateUserId: (id) => setState(() => userID = id),
        updatePlaylists: (list) => setState(() => _playlists = list),
        updateIsLoading: (loading) => setState(() => _isLoadingPlaylists = loading),
      );
    });
  }

  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    stopPomodoro(); // Stop Pomodoro session using mixin method.
    super.dispose();
  }

  Future<void> _showStopConfirmation(BuildContext context) async {
    await showStopConfirmation(
      context: context,
      stopPomodoro: stopPomodoro,
      pomodoroTimer: pomodoroTimer,
    );
    _musicPlayerKey.currentState?.switchLayout(PlayerLayoutType.compact);
    // Also pause the player.
    spotifyPlayerController = SpotifyPlayerController(spotifyAPI: spotifyAPI);
    spotifyPlayerController.stop(userID);
  }

  Future<void> pomodoroSessionCheck({required Duration workDuration, required Duration shortBreak, required Duration longBreak}) async {
    if (pomodoroTimer == null) {
      await startPomodoroSession(
        workDuration: workDuration,
        shortBreak: shortBreak,
        longBreak: longBreak,
      );
      // If a playlist is selected, start playing it.
      spotifyPlayerController = SpotifyPlayerController(spotifyAPI: spotifyAPI);
      spotifyPlayerController.play(_selectedPlaylist, userID);
    } else if (pomodoroTimer!.isActive) {
      await _showStopConfirmation(context);
    } else {
      await startPomodoroSession(
        workDuration: workDuration,
        shortBreak: shortBreak,
        longBreak: longBreak,
      );
      // If a playlist is selected, start playing it.
      spotifyPlayerController = SpotifyPlayerController(spotifyAPI: spotifyAPI);
      spotifyPlayerController.play(_selectedPlaylist, userID);
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
                  isWorkPhase ? 'Work Time' : 'Break Time',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedPomodoroTime,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
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
                                      image: NetworkImage(playlist.playlistImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                const SizedBox(height: 20),
                // Session start buttons.
                CustomButton(
                  text: "25/5 Session",
                  onPressed: () async {
                    pomodoroSessionCheck(
                      workDuration: const Duration(minutes: 25),
                      shortBreak: const Duration(minutes: 5),
                      longBreak: const Duration(minutes: 30),
                    );
                  },
                  buttonParams: startSessionButtonParams,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "40/10 Session",
                  onPressed: () async {
                    pomodoroSessionCheck(
                      workDuration: const Duration(minutes: 40),
                      shortBreak: const Duration(minutes: 10),
                      longBreak: const Duration(minutes: 30),
                    );
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
                    pomodoroSessionCheck(
                      workDuration: const Duration(seconds: 10),
                      shortBreak: const Duration(seconds: 5),
                      longBreak: const Duration(seconds: 15),
                    );
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_lastPlayerData != null) {
              return Container(
                height: 210,
                child: CustomPlayerWidget(
                  data: _lastPlayerData!,
                  userID: userID ?? '',
                  musicPlayerKey: _musicPlayerKey,
                ),
              );
            } else {
              return Container(
                height: 210,
                child: const Center(child: Text('Loading...')),
              );
            }
          } else if (snapshot.hasError) {
            if (_lastPlayerData != null) {
              return Container(
                height: 210,
                child: CustomPlayerWidget(
                  data: _lastPlayerData!,
                  userID: userID ?? '',
                  musicPlayerKey: _musicPlayerKey,
                ),
              );
            } else {
              return Container(
                height: 210,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
          } else if (!snapshot.hasData || snapshot.data!['item'] == null) {
            if (_lastPlayerData != null) {
              return Container(
                height: 210,
                child: CustomPlayerWidget(
                  data: _lastPlayerData!,
                  userID: userID ?? '',
                  musicPlayerKey: _musicPlayerKey,
                ),
              );
            } else {
              return Container(
                height: 210,
                child: const Center(child: Text('No track is currently playing.')),
              );
            }
          } else {
            _lastPlayerData = snapshot.data;
            return Container(
              height: 210,
              child: CustomPlayerWidget(
                data: snapshot.data!,
                userID: userID ?? '',
                musicPlayerKey: _musicPlayerKey,
              ),
            );
          }
        },
      ),
    );
  }
}
