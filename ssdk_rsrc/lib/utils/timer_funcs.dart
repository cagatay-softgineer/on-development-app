import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/services/api_service.dart';
import '../models/playlist.dart';
import '../utils/authlib.dart';

/// Extracts the first device ID from the provided response.
/// Returns a descriptive string if not found.
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

String extractFirstSmartphoneDeviceId(Map<String, dynamic> response) {
  // Check if 'devices' key exists and is a list
  if (response.containsKey('devices') && response['devices'] is List) {
    List<dynamic> devices = response['devices'];
    
    if (devices.isNotEmpty) {
      // Iterate through devices to find the first Smartphone
      for (var device in devices) {
        if (device is Map<String, dynamic>) {
          if (device['type'] == 'Smartphone') {
            if (device.containsKey('id') && device['id'] is String) {
              String deviceId = device['id'];
              return deviceId;
            } else {
              return 'Device ID not found or is not a string.';
            }
          }
        }
      }
      return 'No Smartphone devices found.';
    } else {
      return 'No devices available.';
    }
  } else {
    return 'Invalid response format: "devices" key missing or not a list.';
  }
}

/// Initializes user ID and playlists.
/// Calls [updateUserId] with the retrieved user ID,
/// [updatePlaylists] with the fetched playlists,
/// and [updateIsLoading] with false when finished.
Future<void> initializeUserAndPlaylists({
  required Function(String) updateUserId,
  required Function(List<Playlist>) updatePlaylists,
  required Function(bool) updateIsLoading,
}) async {
  try {
    final uid = await AuthService.getUserId();
    updateUserId(uid ?? '');
    final fetchedPlaylists = await mainAPI.fetchPlaylists("${uid ?? ''}");
    updatePlaylists(fetchedPlaylists);
    updateIsLoading(false);
  } catch (e) {
    print("Error fetching userID or playlists: $e");
    updateIsLoading(false);
  }
}

/// Initializes user ID and player state.
/// Calls [updateUserId] with the retrieved user ID and
/// [updatePlayerFuture] with the Future from [spotifyAPI.getPlayer].
Future<void> initializeData({
  required Function(String) updateUserId,
  required Function(Future<Map<String, dynamic>>?) updatePlayerFuture,
}) async {
  try {
    final userId = await AuthService.getUserId();
    updateUserId(userId ?? '');
    updatePlayerFuture(spotifyAPI.getPlayer(userId ?? ''));
  } catch (e) {
    print("Error fetching userID: $e");
  }
}

/// Starts a periodic timer to check the player state every 4 seconds.
/// The [updatePlayerData] callback is invoked with the new data,
/// while [updateRepeatMode] and [updateShuffleMode] are used to update the corresponding UI state.
Timer startStateCheckTimer({
  required String userID,
  required Function(Map<String, dynamic>) updatePlayerData,
  required Function(String) updateRepeatMode,
  required Function(bool) updateShuffleMode,
}) {
  return Timer.periodic(const Duration(seconds: 4), (timer) async {
    if (userID.isNotEmpty) {
      try {
        final newData = await spotifyAPI.getPlayer(userID);
        // ignore: unnecessary_null_comparison
        if (newData != null && newData['item'] != null) {
          final String newRepeat = newData["repeat_state"] ?? "off";
          final bool newShuffle = newData["shuffle_state"] ?? false;
          updateRepeatMode(newRepeat);
          updateShuffleMode(newShuffle);
          updatePlayerData(newData);
        }
      } catch (e) {
        print("Error in state check: $e");
      }
    }
  });
}

/// Shows a confirmation dialog to stop the Pomodoro session.
/// If the user confirms, the provided [stopPomodoro] function is called.
Future<void> showStopConfirmation({
  required BuildContext context,
  required Future<void> Function() stopPomodoro,
  required Timer? pomodoroTimer,
}) async {
  if (pomodoroTimer != null && pomodoroTimer.isActive) {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Session'),
          content: const Text('Are you sure you want to stop the session?'),
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
