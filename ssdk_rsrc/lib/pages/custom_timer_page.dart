// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/widgets/custom_button.dart';
import 'package:ssdk_rsrc/styles/button_styles.dart';
import 'dart:async';
import 'package:ssdk_rsrc/services/main_api.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/utils/timer_funcs.dart'; // Timer utilities (player state functions)
import 'package:ssdk_rsrc/utils/pomodoro_funcs.dart'; // Pomodoro mixin
import 'package:ssdk_rsrc/widgets/player_widget.dart'; // Custom player widget
import 'package:ssdk_rsrc/widgets/music_player.dart'; // Custom player widget
import 'package:ssdk_rsrc/widgets/pie_time_selector.dart'; // New PieTimeSelector widget

class CustomTimerPage extends StatefulWidget {
  const CustomTimerPage({super.key});

  @override
  _CustomTimerPageState createState() => _CustomTimerPageState();
}

class _CustomTimerPageState extends State<CustomTimerPage> with PomodoroMixin {
  String? userID = "";
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  bool _isLoadingPlaylists = true;

  // User-configurable timer values.
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 30;
  int _sessionsBeforeLongBreak = 4;
  bool focusMode = false;
  // Control for expansion toggle.
  bool isTimeSelectorExpanded = false;

  Future<Map<String, dynamic>>? _playerFuture;
  Map<String, dynamic>? _lastPlayerData;
  Timer? _stateCheckTimer;

  // GlobalKey for the MusicPlayerWidget.
  final GlobalKey<MusicPlayerWidgetState> _musicPlayerKey =
      GlobalKey<MusicPlayerWidgetState>();

  String get formattedPomodoroTime {
    final minutes = pomodoroRemaining.inMinutes.remainder(60).toString();
    final seconds = pomodoroRemaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
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
          // Optionally update additional UI state
        },
        updateShuffleMode: (shuffle) {
          // Optionally update additional UI state
        },
      );
      initializeUserAndPlaylists(
        updateUserId: (id) => setState(() => userID = id),
        updatePlaylists: (list) => setState(() => _playlists = list),
        updateIsLoading:
            (loading) => setState(() => _isLoadingPlaylists = loading),
      );
    });
  }

  @override
  void dispose() {
    _stateCheckTimer?.cancel();
    stopPomodoro(); // Use mixin method to stop timer
    super.dispose();
  }

  Future<void> _showStopConfirmation(BuildContext context) async {
    await showStopConfirmation(
      context: context,
      stopPomodoro: stopPomodoro,
      pomodoroTimer: pomodoroTimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isWorkPhase ? 'Work Time' : 'Break Time',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedPomodoroTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _isLoadingPlaylists
                    ? const CircularProgressIndicator()
                    : DropdownButton<Playlist>(
                      hint: const Text("Select Playlist"),
                      value: _selectedPlaylist,
                      isExpanded: true,
                      items:
                          _playlists.map((playlist) {
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
                                        image: NetworkImage(
                                          playlist.playlistImage,
                                        ),
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          playlist.playlistOwner,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
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
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      'Timer Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    initiallyExpanded: isTimeSelectorExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        isTimeSelectorExpanded = expanded;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      text: "Start Timer",
                      onPressed: () async {
                        await startPomodoroSession(
                          workDuration: Duration(minutes: _workMinutes),
                          shortBreak: Duration(minutes: _shortBreakMinutes),
                          longBreak: Duration(minutes: _longBreakMinutes),
                          sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
                        );
                        _musicPlayerKey.currentState!.switchLayout(
                          PlayerLayoutType.focus,
                        );
                        // If a playlist is selected, start playing it.
                        if (_selectedPlaylist != null &&
                            userID != null &&
                            userID!.isNotEmpty) {
                          final response = await spotifyAPI.getDevices(userID);
                          final deviceId = extractFirstDeviceId(response);
                          await spotifyAPI.playPlaylist(
                            _selectedPlaylist!.playlistId,
                            userID,
                            deviceId,
                          );
                        }
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                    const SizedBox(width: 10),
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
                CustomButton(
                  text: "Change Player Type",
                  onPressed: () {
                    if (_musicPlayerKey.currentState != null) {
                      if (focusMode) {
                        _musicPlayerKey.currentState!.switchLayout(
                          PlayerLayoutType.compact,
                        );
                        focusMode = false;
                      } else {
                        _musicPlayerKey.currentState!.switchLayout(
                          PlayerLayoutType.focus,
                        );
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
                    await startPomodoroSession(
                      workDuration: const Duration(seconds: 10),
                      shortBreak: const Duration(seconds: 5),
                      longBreak: const Duration(seconds: 10),
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
                  spotifyData: _lastPlayerData!,
                  userID: userID ?? '',
                  app: MusicApp.Spotify,
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
                  spotifyData: _lastPlayerData!,
                  userID: userID ?? '',
                  app: MusicApp.Spotify,
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
                  spotifyData: _lastPlayerData!,
                  userID: userID ?? '',
                  app: MusicApp.Spotify,
                  musicPlayerKey: _musicPlayerKey,
                ),
              );
            } else {
              return Container(
                height: 210,
                child: const Center(
                  child: Text('No track is currently playing.'),
                ),
              );
            }
          } else {
            _lastPlayerData = snapshot.data;
            return Container(
              height: 210,
              child: CustomPlayerWidget(
                spotifyData: snapshot.data!,
                userID: userID ?? '',
                app: MusicApp.Spotify,
                musicPlayerKey: _musicPlayerKey,
              ),
            );
          }
        },
      ),
    );
  }
}
