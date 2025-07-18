// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/widgets/button/custom_button.dart';
import 'package:pomodoro/resources/themes.dart';
import 'dart:async';
import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/models/playlist.dart';
import 'package:pomodoro/utils/timer_funcs.dart'; // Timer utilities (e.g. player state functions)
import 'package:pomodoro/utils/pomodoro_funcs.dart'; // Pomodoro mixin
import 'package:pomodoro/widgets/bar/custom_staus_bar.dart';
import 'package:pomodoro/widgets/text/glowing_text.dart';
import 'package:pomodoro/widgets/components/music_player/player_widget.dart'; // Custom player widget
import 'package:pomodoro/widgets/components/music_player/music_player.dart'; // Custom player widget
import 'package:pomodoro/utils/spotify_func.dart';
import 'package:pomodoro/widgets/others/playlist_dropdown.dart'; //spotify

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with PomodoroMixin {
  int _selectedSessionCount =
      4; // User-selectable, default 4 (same as sessionsBeforeLongBreak)
  String? userID = "";
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  bool _isLoadingPlaylists = true;

  // User-configurable timer values.
  bool focusMode = false;

  SpotifyPlayerController? spotifyPlayerController;
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
          // Optionally update UI state for repeat mode.
        },
        updateShuffleMode: (shuffle) {
          // Optionally update UI state for shuffle mode.
        },
      );
      initializeUserAndPlaylists(
        updateUserId: (id) => setState(() => userID = id),
        updatePlaylists: (list) => setState(() => _playlists = list),
        updateIsLoading:
            (loading) => setState(() => _isLoadingPlaylists = loading),
        tempLoadYoutube: false,
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
    spotifyPlayerController!.stop(userID);
  }

  Future<void> pomodoroSessionCheck({
    required Duration workDuration,
    required Duration shortBreak,
    required Duration longBreak,
    required int sessionsBeforeLongBreak,
  }) async {
    if (pomodoroTimer == null) {
      await startPomodoroSession(
        workDuration: workDuration,
        shortBreak: shortBreak,
        longBreak: longBreak,
        sessionsBeforeLongBreak: sessionsBeforeLongBreak,
      );
      // If a playlist is selected, start playing it.
      _musicPlayerKey.currentState?.switchLayout(PlayerLayoutType.focus);
      spotifyPlayerController = SpotifyPlayerController(spotifyAPI: spotifyAPI);
      spotifyPlayerController!.play(_selectedPlaylist, userID);
    } else if (pomodoroTimer!.isActive) {
      await _showStopConfirmation(context);
    } else {
      await startPomodoroSession(
        workDuration: workDuration,
        shortBreak: shortBreak,
        longBreak: longBreak,
        sessionsBeforeLongBreak: sessionsBeforeLongBreak,
      );
      // If a playlist is selected, start playing it.
      _musicPlayerKey.currentState?.switchLayout(PlayerLayoutType.focus);
      spotifyPlayerController = SpotifyPlayerController(spotifyAPI: spotifyAPI);
      spotifyPlayerController!.play(_selectedPlaylist, userID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Pomodoro Timer')),
      backgroundColor: ColorPalette.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlowingText(
                  text: isWorkPhase ? 'Work Time' : 'Break Time',
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.white,
                  glowColor: ColorPalette.gold,
                ),
                GlowingText(
                  text: formattedPomodoroTime,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.white,
                  glowColor: ColorPalette.gold,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap:
                      _isLoadingPlaylists
                          ? null
                          : () async {
                            await showPlaylistSelectorDialog(
                              context: context,
                              playlists: _playlists,
                              selected: _selectedPlaylist,
                              onSelected: (selected) async {
                                setState(() => _selectedPlaylist = selected);

                                // Print playlist duration to console
                                // ignore: unnecessary_null_comparison
                                // if (selected != null &&
                                //     selected.playlistId.isNotEmpty) {
                                //   final durationData = await mainAPI
                                //       .getPlaylistDuration(
                                //         selected.playlistId,
                                //         MusicApp.Spotify,
                                //         1,
                                //       );
                                //   print(
                                //     "Selected Playlist Duration: ${durationData}",
                                //   );
                                // }
                              },
                            );
                          },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.backgroundColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.gold.withAlpha(64),
                          blurRadius: 15,
                        ),
                      ],
                      border: Border.all(color: ColorPalette.white),
                    ),
                    child: Row(
                      children: [
                        _selectedPlaylist != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: FadeInImage.assetNetwork(
                                placeholder:
                                    'https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Placeholder/PNG/Placeholder-Rectangle%400.5x.png',
                                image:
                                    _selectedPlaylist!.playlistImage.isNotEmpty
                                        ? _selectedPlaylist!.playlistImage
                                        : 'https://raw.githubusercontent.com/Yggbranch/assets/refs/heads/main/Placeholder/PNG/Placeholder-Rectangle%400.5x.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                imageErrorBuilder:
                                    (_, __, ___) => Container(
                                      width: 32,
                                      height: 32,
                                      color: Colors.black26,
                                      child: Icon(
                                        Icons.music_note,
                                        color: Colors.white60,
                                      ),
                                    ),
                              ),
                            )
                            : Icon(
                              FontAwesomeIcons.listOl,
                              //Icons.queue_music,
                              color: Colors.white60,
                              size: 32,
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedPlaylist?.playlistName ??
                                'Select Playlist',
                            style: TextStyle(
                              color: ColorPalette.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sessions per cycle: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _selectedSessionCount,
                      dropdownColor: ColorPalette.backgroundColor,
                      style: const TextStyle(color: Colors.white),
                      items:
                          [2, 3, 4, 5, 6, 8]
                              .map(
                                (count) => DropdownMenuItem(
                                  value: count,
                                  child: Text('$count'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSessionCount = value;
                            // If user changes mid-cycle, reset Pomodoro
                            sessionCount = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Session start buttons.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      text: "25/5",
                      onPressed: () async {
                        pomodoroSessionCheck(
                          workDuration: const Duration(minutes: 25),
                          shortBreak: const Duration(minutes: 5),
                          longBreak: const Duration(minutes: 10),
                          sessionsBeforeLongBreak: _selectedSessionCount,
                        );
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                    const SizedBox(width: 5),
                    CustomButton(
                      text: "40/10",
                      onPressed: () async {
                        pomodoroSessionCheck(
                          workDuration: const Duration(minutes: 40),
                          shortBreak: const Duration(minutes: 10),
                          longBreak: const Duration(minutes: 30),
                          sessionsBeforeLongBreak: _selectedSessionCount,
                        );
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 5),
                    CustomButton(
                      text: "DBG",
                      onPressed: () async {
                        pomodoroSessionCheck(
                          workDuration: const Duration(seconds: 1),
                          shortBreak: const Duration(seconds: 2),
                          longBreak: const Duration(seconds: 3),
                          sessionsBeforeLongBreak: _selectedSessionCount,
                        );
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                    SizedBox(width: 5),
                    CustomButton(
                      text: "AI Predict",
                      onPressed: () async {
                        print(_selectedPlaylist!.playlistName);
                        if (_selectedPlaylist != null &&
                            _selectedPlaylist!.playlistId.isNotEmpty) {
                          final durationData = await mainAPI
                              .getPlaylistDuration(
                                _selectedPlaylist!.playlistId,
                                MusicApp.spotify,
                                1,
                              );
                          int totalMs = durationData['total_duration_ms'];

                          // Call ML endpoint
                          final mlResult = await mainAPI.getPredict(totalMs);
                          print("ML Result: $mlResult");

                          // ignore: unnecessary_null_comparison
                          if (mlResult != null && mlResult['pattern'] != null) {
                            // Show prediction info and wait for confirmation
                            final confirmed = await showMLPredictionDialog(
                              context,
                              mlResult,
                              durationData,
                            );

                            if (confirmed) {
                              final workSessions =
                                  (mlResult['work_sessions'] as List)
                                      .map((v) => Duration(minutes: v))
                                      .toList();
                              final shortBreak = Duration(
                                minutes: mlResult['short_break'] ?? 0,
                              );
                              final longBreak = Duration(
                                minutes: mlResult['long_break'] ?? 0,
                              );
                              final sessionsBeforeLongBreak =
                                  workSessions.length;
                              setState(() {
                                _selectedSessionCount = sessionsBeforeLongBreak;
                              });
                              await pomodoroSessionCheck(
                                workDuration: workSessions[0],
                                shortBreak: shortBreak,
                                longBreak: longBreak,
                                sessionsBeforeLongBreak:
                                    sessionsBeforeLongBreak,
                              );
                            } else {
                              print("User cancelled AI Predict start.");
                            }
                          } else {
                            print("ML Predict failed or pattern missing");
                          }
                        } else {
                          print("No playlist selected!");
                        }
                      },
                      buttonParams: startSessionSmallButtonParams,
                    ),
                    const SizedBox(width: 5),
                  ],
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
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Transparent.a00,
                    borderRadius: BorderRadius.circular(24),
                    border: BorderDirectional(
                      bottom: BorderSide(
                        color: ColorPalette.white.withAlpha(64),
                      ),
                    ),
                  ),
                  child: CustomStatusBar(
                    stepCount: _selectedSessionCount,
                    currentStep:
                        sessionCount > _selectedSessionCount
                            ? _selectedSessionCount
                            : sessionCount,
                  ),
                ),
                // const SizedBox(height: 20),
                // Change Player Type button.
                // CustomButton(
                //   text: "Change Player Type",
                //   onPressed: () {
                //     if (_musicPlayerKey.currentState != null) {
                //       if (focusMode) {
                //         _musicPlayerKey.currentState!.switchLayout(
                //           PlayerLayoutType.compact,
                //         );
                //         focusMode = false;
                //       } else {
                //         _musicPlayerKey.currentState!.switchLayout(
                //           PlayerLayoutType.focus,
                //         );
                //         focusMode = true;
                //       }
                //     }
                //   },
                //   buttonParams: changeLayoutButtonParams,
                // ),
                // const SizedBox(height: 20),
                // CustomButton(
                //   text: "Debug Session",
                //   onPressed: () async {
                //     pomodoroSessionCheck(
                //       workDuration: const Duration(seconds: 10),
                //       shortBreak: const Duration(seconds: 5),
                //       longBreak: const Duration(seconds: 15),
                //     );
                //   },
                //   buttonParams: startSessionButtonParams,
                // ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _playerFuture,
        builder: (context, snapshot) {
          Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child =
                _lastPlayerData != null
                    ? CustomPlayerWidget(
                      spotifyData: _lastPlayerData!,
                      userID: userID ?? '',
                      app: MusicApp.spotify,
                      musicPlayerKey: _musicPlayerKey,
                    )
                    : const Center(child: Text('Loading...'));
          } else if (snapshot.hasError) {
            child =
                _lastPlayerData != null
                    ? CustomPlayerWidget(
                      spotifyData: _lastPlayerData!,
                      userID: userID ?? '',
                      app: MusicApp.spotify,
                      musicPlayerKey: _musicPlayerKey,
                    )
                    : Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['item'] == null) {
            child =
                _lastPlayerData != null
                    ? CustomPlayerWidget(
                      spotifyData: _lastPlayerData!,
                      userID: userID ?? '',
                      app: MusicApp.spotify,
                      musicPlayerKey: _musicPlayerKey,
                    )
                    : const Center(
                      child: Text('No track is currently playing.'),
                    );
          } else {
            _lastPlayerData = snapshot.data;
            child = CustomPlayerWidget(
              spotifyData: snapshot.data!,
              userID: userID ?? '',
              app: MusicApp.spotify,
              musicPlayerKey: _musicPlayerKey,
            );
          }
          return Container(color: Transparent.a00, height: 250, child: child);
        },
      ),
    );
  }
}
