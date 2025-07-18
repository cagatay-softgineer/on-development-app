import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pomodoro/utils/authlib.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro/models/playlist.dart';
import 'package:pomodoro/models/music_app.dart';
import 'package:pomodoro/services/spotify_api.dart';
import 'package:pomodoro/models/track.dart';

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
MainAPI mainAPI = MainAPI();
SpotifyAPI spotifyAPI = SpotifyAPI();
String? baseUrl;

// Define a cache entry to hold the data and expiry timestamp.
class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiry;
  CacheEntry(this.data, this.expiry);
}

class MainAPI {

  static final Map<String, CacheEntry> _playlistDurationCache = {};
  
  // Cache duration set to one hour.
  static const Duration cacheDuration = Duration(hours: 1);

   // Create Dio without a base URL for now.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(milliseconds: 20000),
    receiveTimeout: Duration(milliseconds: 40000),
  ));

  // List of candidate base URLs.
  final List<String> _baseUrls = [
    // Development Backend
    'https://api-sync-branch.yggbranch.dev/',
""
    // Deployment Backend
    'https://python-hello-world-911611650068.europe-west3.run.app/',
    'https://pomodoro-911611650068.europe-west8.run.app/',
  ];

  MainAPI() {
    // Set the active base URL when initializing.
    initializeBaseUrl().then((_) {
      // Add an interceptor to automatically add the bearer token
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Exclude endpoints where you don't need the auth token.
          if (!(options.path.contains('auth/login') ||
                options.path.contains('auth/register'))) {
            String? token = await _secureStorage.read(key: 'access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // You could handle token refresh here if needed.
          return handler.next(e);
        },
      ));
    });
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
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.data is Map<String, dynamic>) {
        // Check if the response contains access_token, and store it.
        if (response.data.containsKey('access_token')) {
          await _secureStorage.write(
            key: 'access_token',
            value: response.data['access_token'],
          );
          // Optionally store refresh token if provided:
          if (response.data.containsKey('refresh_token')) {
            await _secureStorage.write(
              key: 'refresh_token',
              value: response.data['refresh_token'],
            );
          }
        }
        return response.data;
      } else {
        throw Exception('Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      // Handle Dio exceptions as before...
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message': 'Connection timed out. Please check your internet connection.',
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

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.post(
          'profile/view',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
      return result;
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<Map<String, dynamic>> getChainStatus() async {
    try {
      final response = await _dio.post('profile/chain_status');
      return response.data;
    } catch (e) {
      //print('Error fetching chain status: $e');
      return {'error': true};
    }
  }

  Future<Map<String, dynamic>> getPredict(int playlistDuration) async {
    try {
      final response = await _dio.post('ml/predict', data: {
        'data': playlistDuration,
      });
      return response.data;
    } catch (e) {
      //print('Error fetching chain status: $e');
      return {'error': true};
    }
  }

  Future<Map<String, dynamic>> updateChainStatus(String action) async {
    try {
      final response = await _dio.post('profile/chain_status_update', data: {
        'action': action,
      });
      return response.data;
    } catch (e) {
      //print('Error updating chain status: $e');
      return {'error': true};
    }
  }

  Future<List<Playlist>> fetchPlaylists(String? userId, { MusicApp app = MusicApp.spotify }) async {
    // Determine the endpoint based on the MusicApp
    String endpoint;
    switch (app) {
      case MusicApp.spotify:
        endpoint = 'spotify/playlists';
        break;
      case MusicApp.youtube:
        endpoint = 'youtube-music/playlists';
        break;
      case MusicApp.apple:
        endpoint = 'apple-music/playlists';
        break;
    }

    final response = await _dio.post(
      endpoint,
      data: {
        "user_email": userId,
      },
      options: Options(sendTimeout: Duration(milliseconds: 20000),
      receiveTimeout: Duration(milliseconds: 60000),
      ),
    );

if (response.statusCode == 200) {
    List<dynamic> data;
    if (app == MusicApp.youtube) {
      // For YouTube, assume the response JSON contains an "items" array.
      data = response.data["items"] ?? [];
    } else if (response.data is List) {
      // If the response is directly a List.
      data = response.data;
    } else if (response.data is Map && response.data["data"] is List) {
      // If the response is a Map with a "data" key holding the list.
      data = response.data["data"];
    } else {
      data = [];
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
      return data.map((json) => Track.fromJson(json, MusicApp.youtube)).toList();
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


  Future<Map<String, dynamic>> getPlaylistDuration(String? playlistId, MusicApp? app, int? playlistTrackCount) async {
    if (playlistId == null) {
      throw Exception("Playlist ID cannot be null");
    }
    if (playlistTrackCount! >= 100){
      throw Exception("Playlist track count is greater than 100");
    }
    // Check if the duration is cached and still valid.
    if (_playlistDurationCache.containsKey(playlistId)) {
      final cacheEntry = _playlistDurationCache[playlistId]!;
      if (DateTime.now().isBefore(cacheEntry.expiry)) {
        return cacheEntry.data;
      } else {
        // Remove expired cache entry.
        _playlistDurationCache.remove(playlistId);
      }
    }
  
    try {
      final userId = await AuthService.getUserId();
      print("User ID: $userId");
      String endpoint = "";
      if(app == MusicApp.spotify) {
        endpoint = "spotify-micro-service/playlist_duration";
      }
      if(app == MusicApp.youtube) {
        endpoint = "youtube-music/playlist_duration";
      }
      if(app == MusicApp.apple) {
        endpoint = "apple-music/playlist_duration";
      }
      final response = await _dio.post(
        '${endpoint}',
        data: {
          "playlist_id": "$playlistId",
          "user_email": "$userId"
        },
        options: Options(sendTimeout: Duration(milliseconds: 20000),
        receiveTimeout: Duration(milliseconds: 60000),
        ),
      );
      if (response.data is Map<String, dynamic>) {
        // Cache the response for one hour.
        _playlistDurationCache[playlistId] = CacheEntry(
          response.data,
          DateTime.now().add(cacheDuration),
        );
        return response.data;
      } else {
        throw Exception('Unexpected response type: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message': 'Connection timed out. Please check your internet connection.',
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
  
  Future<Map<String, dynamic>> getAllAppsBinding(String? email) async {
    try {
      final response = await _dio.post(
        'apps/get_all_apps_binding',
        data: {
          'user_email': email,
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
      if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'error': true,
          'message': 'Connection timed out. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'error': true,
          'message': 'Server took too long to respond. Please try again later.',
        };
      } else if (e.response != null &&
          e.response!.data is Map<String, dynamic>) {
        return {
          'error': true,
          'message': e.response!.data['message'] ?? 'Fetching apps binding failed',
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
      final url = '${baseUrl}spotify/login/$userId';
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
          content: Text('Could not launch the URL.\n ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
    Future<void> openAppleLogin(BuildContext context) async {
    try {
      // Fetch user ID
      final userId = await AuthService.getUserId();

      // Debugging to ensure userId is valid
      if (userId == null || userId.isEmpty) {
        //print('Error: User ID is null or empty.');
        throw 'User ID is null or empty.';
      }

      // Construct URL
      final url = '${baseUrl}apple/login/$userId';
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
          content: Text('Could not launch the URL.\n ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void>? openOurWebSite(BuildContext context) async {
    try {
      // Fetch user ID
      final userId = await AuthService.getUserId();

      // Debugging to ensure userId is valid
      if (userId == null || userId.isEmpty) {
        //print('Error: User ID is null or empty.');
        throw 'User ID is null or empty.';
      }

      // Construct URL
      final url = 'https://pomodoro.yggbranch.dev';
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

  getUserPlaylists(String userId) {}
}