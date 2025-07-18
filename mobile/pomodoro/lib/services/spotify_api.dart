import 'package:dio/dio.dart';
import 'package:pomodoro/services/main_api.dart';

class SpotifyAPI {
    
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.spotify.com/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 10000),
    ),
  );

  Future<Map<String, dynamic>> getDevices(String? userId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.get(
        'v1/me/player/devices',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token added
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        // Parse the response data
        final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);

        // Check if 'devices' key exists and is an empty list
        if (result.containsKey('devices') && result['devices'] is List) {
          List devices = result['devices'];

          if (devices.isEmpty) {
            return {
              'error': true,
              'message': 'No devices found. Please make sure you have an active Spotify device.',
              'status_code': 200, // Keep the status code for reference
            };
          }
        }

        // Include the status code in the response
        result['status_code'] = response.statusCode;
        result['error'] = false;
        return result;
      } else {
        return {
          'error': true,
          'message': 'Unexpected response format.',
          'status_code': 400,
        };
      }
    } on DioException catch (e) {
      // Enhanced error logging
      if (e.response != null) {
        print('Dio Error Response: ${e.response?.data}');
        print('Dio Error Status Code: ${e.response?.statusCode}');
      } else {
        print('Dio Error Message: ${e.message}');
      }

      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message': 'Connection timed out. Please check your internet connection.',
          'status_code': e.response?.statusCode,
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
          'status_code': e.response?.statusCode,
        };
      } else if (e.type == DioExceptionType.badResponse) {
        // Handle bad responses (non-2xx status codes)
        String errorMessage = 'Failed to retrieve devices.';
        if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
          if (e.response!.data.containsKey('error')) {
            errorMessage = e.response!.data['error']['message'] ?? errorMessage;
          }
        }

        return {
          'error': true,
          'message':
              'Failed to retrieve devices. Status Code: ${e.response?.statusCode}, Message: $errorMessage',
          'status_code': e.response?.statusCode,
        };
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
          'status_code': e.response?.statusCode,
        };
      }
    } catch (e) {
      // Catch any other errors
      print('General Error: $e');
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
        'status_code': null,
      };
    }
  }

  Future<bool> setRepeatMode(String? userId, String? deviceId, String? state) async {
    // State can be 
    //track, context or off.
    //track will repeat the current track.
    //context will repeat the current context.
    //off will turn repeat off.
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.put(
        'v1/me/player/repeat?state=$state&device_id=$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to set Repeat Mode: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error setting Repeat Mode: $e');
      return false;
    }
  }

  Future<bool> setShuffleMode(String? userId, String? deviceId, bool? state) async {
    // State can be 
    //true, false

    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.put(
        'v1/me/player/shuffle?state=$state&device_id=$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to set Shuffle Mode: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error setting Shuffle Mode: $e');
      return false;
    }
  }

  Future<bool> playPlaylist(String? playlistId, String? userId, String? deviceId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.put(
        'v1/me/player/play?device_id=$deviceId',
        data: {
      "context_uri": "spotify:playlist:$playlistId",
      "offset": {
        "position": 0
      },
      "position_ms": 0
    },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token ekle
          },
        ),
        );

      if (response.statusCode == 204) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to play playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error playing playlist: $e');
      return false;
    }
  }

  Future<bool> resumePlayer(String? userId, String? deviceId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.put(
        'v1/me/player/play?device_id=$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token ekle
          },
        ),
        );

      if (response.statusCode == 204) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to play playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error playing playlist: $e');
      return false;
    }
  }

  Future<bool> pausePlayer(String? userId, String? deviceId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.put(
        'v1/me/player/pause?device_id=$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token ekle
          },
        ),
        );

      if (response.statusCode == 204) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to play playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error playing playlist: $e');
      return false;
    }
  }

  Future<bool> skipToNext(String? userId, String? deviceId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.post(
        'v1/me/player/next?device_id=$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token ekle
          },
        ),
        );

      if (response.statusCode == 204) {
        // Successfully started playback
        return true;
      } else {
        print('Failed to play playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error playing playlist: $e');
      return false;
    }
  }

  Future<bool> skipToPrevious(String? userId, String? deviceId) async {
      final token = await mainAPI.getToken(userId);
      try {
        final response = await _dio.post(
          'v1/me/player/previous?device_id=$deviceId',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token', // JWT token ekle
            },
          ),
          );

        if (response.statusCode == 204) {
          // Successfully started playback
          return true;
        } else {
          print('Failed to play playlist: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        print('Error playing playlist: $e');
        return false;
      }
    }

  Future<bool> seekToPosition(String? userId, String? deviceId, String? positionMs) async {
      final token = await mainAPI.getToken(userId);
      try {
        final response = await _dio.put(
          'v1/me/player/seek?position_ms=$positionMs&device_id=$deviceId',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token', // JWT token ekle
            },
          ),
          );

        if (response.statusCode == 204) {
          // Successfully started playback
          return true;
        } else {
          print('Failed to play playlist: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        print('Error playing playlist: $e');
        return false;
      }
    }

  Future<Map<String, dynamic>> getPlayer(String? userId) async {
    final token = await mainAPI.getToken(userId);
    try {
      final response = await _dio.get(
        'v1/me/player',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // JWT token added
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        // Parse the response data
        final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);

        // Include the status code in the response
        result['status_code'] = response.statusCode;
        result['error'] = false;
        return result;
      } else {
        return {
          'error': true,
          'message': 'Unexpected response format.',
          'status_code': 400,
        };
      }
    } on DioException catch (e) {
      // Enhanced error logging
      if (e.response != null) {
        print('Dio Error Response: ${e.response?.data}');
        print('Dio Error Status Code: ${e.response?.statusCode}');
      } else {
        print('Dio Error Message: ${e.message}');
      }

      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message': 'Connection timed out. Please check your internet connection.',
          'status_code': e.response?.statusCode,
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
          'status_code': e.response?.statusCode,
        };
      } else if (e.type == DioExceptionType.badResponse) {
        // Handle bad responses (non-2xx status codes)
        String errorMessage = 'Failed to retrieve player information.';
        if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
          if (e.response!.data.containsKey('error')) {
            errorMessage = e.response!.data['error']['message'] ?? errorMessage;
          }
        }

        return {
          'error': true,
          'message':
              'Failed to retrieve player information. Status Code: ${e.response?.statusCode}, Message: $errorMessage',
          'status_code': e.response?.statusCode,
        };
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
          'status_code': e.response?.statusCode,
        };
      }
    } catch (e) {
      print('General Error: $e');
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
        'status_code': null,
      };
    }
  }

}
