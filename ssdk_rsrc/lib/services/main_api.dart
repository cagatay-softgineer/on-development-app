import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ssdk_rsrc/utils/authlib.dart';
import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/playlist.dart';
import 'package:ssdk_rsrc/enums/enums.dart';
import 'package:ssdk_rsrc/services/spotify_api.dart';

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
MainAPI mainAPI = MainAPI();
SpotifyAPI spotifyAPI = SpotifyAPI();
String? baseUrl;

class MainAPI {

   // Create Dio without a base URL for now.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(milliseconds: 5000),
    receiveTimeout: Duration(milliseconds: 10000),
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
      baseUrl = activeUrl;
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

  Future<List<Playlist>> fetchPlaylists(String? userId, { MusicApp app = MusicApp.Spotify }) async {
    // Determine the endpoint based on the MusicApp
    String endpoint;
    switch (app) {
      case MusicApp.Spotify:
        endpoint = 'spotify/playlists';
        break;
      case MusicApp.YouTube:
        endpoint = 'youtube-music/playlists';
        break;
    }

    final response = await _dio.post(
      endpoint,
      data: {
        "user_email": userId,
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data;
      // For YouTube, assume the response JSON contains an "items" array.
      if (app == MusicApp.YouTube) {
        data = response.data["items"] ?? [];
      } else {
        data = response.data;
      }
      return data.map((json) => Playlist.fromJson(json, app)).toList();
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<List<Track>> fetchPlaylistTracks(String? userEmail, String? playlistId) async {
    const endpoint = 'youtube-music/playlist_tracks';
    final response = await _dio.post(
      endpoint,
      data: {
        "user_email": userEmail,
        "playlist_id": playlistId,
      },
    );
  
    if (response.statusCode == 200) {
      List<dynamic> data = response.data["tracks"] ?? [];
      return data.map((json) => Track.fromJson(json, MusicApp.YouTube)).toList();
    } else {
      throw Exception('Failed to load playlist tracks');
    }
  }


  Future<String?> fetchFirstVideoId(String? userId, String? playlistId) async {
    if (playlistId == null || playlistId.isEmpty) return null;
    try {
      final response = await _dio.post(
        "/youtube-music/fetch_first_video_id",
        data: {"playlist_id": playlistId, "user_email": userId},
        options: Options(
        contentType: "application/json", // Sets "application/json"
        ),
      );
      if (response.statusCode == 200) {
        return response.data["videoId"];
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print("Error fetching first video id: $e");
    }
    return null;
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
  Future<void> openGoogleLogin(BuildContext context) async {
    try {
      // Fetch user ID
      final userId = await AuthService.getUserId();

      // Debugging to ensure userId is valid
      if (userId == null || userId.isEmpty) {
        //print('Error: User ID is null or empty.');
        throw 'User ID is null or empty.';
      }

      // Construct URL
      final url = '${baseUrl}google/google_api_bind?user_email=$userId';
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