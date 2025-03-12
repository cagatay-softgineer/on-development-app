import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'authlib.dart';
import 'package:flutter/material.dart';
import 'models/playlist.dart';

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
MainAPI mainAPI = MainAPI();
SpotifyAPI spotifyAPI = SpotifyAPI();

class ApiService {

}

class SpotifyAPI {
    
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.spotify.com/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 5000),
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

class MainAPI {

   // Create Dio without a base URL for now.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(milliseconds: 5000),
    receiveTimeout: Duration(milliseconds: 5000),
  ));

  // List of candidate base URLs.
  final List<String> _baseUrls = [
    'https://api-sync-branch.yggbranch.dev/',
    'https://python-hello-world-911611650068.europe-west3.run.app/'
  ];

  MainAPI() {
    // Set the active base URL when initializing.
    initializeBaseUrl();
  }

  // Asynchronously set the active base URL.
  Future<void> initializeBaseUrl() async {
    try {
      String activeUrl = await _getActiveBaseUrl();
      _dio.options.baseUrl = activeUrl;
      print('Active base URL set to: $activeUrl');
    } catch (e) {
      // Handle the case when no URL is active.
      print('Error: No active base URL found. $e');
    }
  }

  // Method to check which base URL is active.
  Future<String> _getActiveBaseUrl() async {
    for (final url in _baseUrls) {
      try {
        // Assumes each service exposes a /health endpoint for a basic check.
        final response = await Dio().get('${url}healthcheck');
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {
        // If the request fails, move on to the next URL.
        continue;
      }
    }
    // If none of the URLs responded with 200, throw an exception.
    throw Exception('No active base URL found.');
  }

  // Example API method that uses the active base URL.
  Future<Response> fetchData(String endpoint) async {
    return await _dio.get(endpoint);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print(_dio.options.baseUrl);
      final response = await _dio.post(
        'auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      //print('Response Data: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        // Check if the response contains access_token
        if (response.data.containsKey('access_token')) {
          // Store the token securely
          await _secureStorage.write(
            key: 'access_token',
            value: response.data['access_token'],
          );
          //print('Access token stored securely.');
        }

        return response.data;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message':
              'Connection timed out. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
        };
      } else if (e.response != null) {
        return {
          'error': true,
          'message': e.response?.data['message'] ?? 'Login failed',
        };
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
        };
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/register',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
  
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      // Handle timeouts separately.
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message':
              'Connection timed out. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
        };
      } else if (e.response != null && e.response?.data is Map<String, dynamic>) {
        // Return the full error response from the server.
        return e.response!.data;
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
        };
      }
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String? userId) async {
    final response = await _dio.post(
          'spotify/user_profile',
          data: {
            "user_id": userId
          }
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
      return result;
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<List<Playlist>> fetchPlaylists(String? userId) async {
    final response = await _dio.post(
          'spotify/playlists',
          data: {
            "user_email": userId
          }
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Playlist.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<String> getToken(String? userId) async {
    final response = await _dio.post(
          'spotify/token',
          data: {
            "user_email": userId
          }
    );

    if (response.statusCode == 200) {
      return response.data["token"].toString();
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDuration(String? playlistId, String? userId) async {
    try {
    print("$playlistId");
    final response = await _dio.post(
          'https://api-sync-branch.yggbranch.dev/spotify-micro-service/playlist_duration',
          data: {
            "playlist_id": "$playlistId",
            "user_id": "$userId"
          }
    );
  
    if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception(
              'Unexpected response type: ${response.data.runtimeType}');
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout) {
          return {
            'error': true,
            'message':
                'Connection timed out. Please check your internet connection.',
          };
        } else if (e.type == DioExceptionType.receiveTimeout) {
          return {
            'error': true,
            'message': 'Server took too long to respond. Please try again later.',
          };
        } else if (e.response != null) {
          return {
            'error': true,
            'message': e.response?.data['message'] ?? 'Login failed',
          };
        } else {
          return {
            'error': true,
            'message': 'An unexpected error occurred. Please try again.',
        };
      }
    }
  }

  Future<Map<String, dynamic>> checkLinkedApp(String? email, String appName) async {
    try {
      final response = await _dio.post(
        'apps/check_linked_app',
        data: {
          'app_name': appName,
          'user_email': email,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Debugging response data
      //print('Response Data: ${response.data}');

      // Validate response type
      if (response.data is Map<String, dynamic>) {
        // Check if the response contains 'user_linked'
        if (response.data.containsKey('user_linked')) {
          final userLinked = response.data['user_linked'];

          // Ensure 'user_linked' is stored as a string in secure storage
          await _secureStorage.write(
            key: appName,
            value: userLinked.toString(), // Convert to String if necessary
          );

          //print('User linked status stored securely for app: $app_name');
        }

        // Return the response data
        return response.data;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      // Debugging DioException
      //print('DioException occurred: $e');

      // Handle specific Dio exceptions
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message':
              'Connection timed out. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
        };
      } else if (e.response != null && e.response!.data is Map<String, dynamic>) {
        // Check if response contains a 'message' key
        return {
          'error': true,
          'message': e.response!.data['message'] ?? 'App Linked Check failed',
        };
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
        };
      }
    } catch (e) {
      // Debugging generic exceptions
      //print('Unexpected exception: $e');

      // Handle non-Dio exceptions
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> unlinkApp(String appName) async {
    final userId = await AuthService.getUserId();
    try {
      final response = await _dio.post(
        'apps/unlink_app',
        data: {
          'app_name': appName,
          'user_email': userId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Validate the response type
      if (response.data is Map<String, dynamic>) {
        // You can handle any specific logic here, e.g., logging
        return response.data;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message':
              'Connection timed out. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
        };
      } else if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return {
          'error': true,
          'message': e.response!.data['message'] ?? 'Unlink app failed',
        };
      } else {
        return {
          'error': true,
          'message': 'An unexpected error occurred. Please try again.',
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }
    
  Future<void> openSpotifyLogin(BuildContext context) async {
    try {
      // Fetch user ID
      final userId = await AuthService.getUserId();

      // Debugging to ensure userId is valid
      if (userId == null || userId.isEmpty) {
        //print('Error: User ID is null or empty.');
        throw 'User ID is null or empty.';
      }

      // Construct URL
      final url = 'https://api-sync-branch.yggbranch.dev/spotify/login/$userId';
      //print('Generated URL: $url');

      // Check if the URL can be launched
      await launch(url);
      //print('URL launched successfully: $url');
    } catch (e) {
      // Log errors for debugging
      //print('Error in openSpotifyLogin: $e');

      // Optionally show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch the URL.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
}