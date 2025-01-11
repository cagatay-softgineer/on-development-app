import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'authlib.dart';
import 'package:flutter/material.dart';
import 'models/playlist.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api-sync-branch.yggbranch.dev/',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 5000),
    ),
  );

  // Secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
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

      //print('Response Data: ${response.data}');

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

  Future<List<Playlist>> fetchPlaylists(String? userId) async {
  print("$userId");
  final response = await _dio.post(
        'https://api-sync-branch.yggbranch.dev/spotify/playlists',
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

  Future<Map<String, dynamic>> getPlaylistDuration(String? playlistId) async {
  try {
  print("$playlistId");
  final response = await _dio.post(
        'https://api-sync-branch.yggbranch.dev/spotify-micro-service/playlist_duration',
        data: {
          "playlist_id": "$playlistId"
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

  Future<Map<String, dynamic>> check_linked_app(String? email, String app_name) async {
  try {
    final response = await _dio.post(
      'apps/check_linked_app',
      data: {
        'app_name': app_name,
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
          key: app_name,
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

  // Method to retrieve the stored token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // Method to clear the stored token
  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: 'access_token');
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
}
