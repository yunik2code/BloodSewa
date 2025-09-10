import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://6dfdad533e13.ngrok-free.app/api';

  // Get stored token
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get stored refresh token
  static Future<String?> _getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Save tokens
  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Clear tokens
  static Future<void> _clearTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Refresh access token
  static Future<bool> _refreshAccessToken() async {
    try {
      String? refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Make authenticated request with automatic token refresh
  static Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('No access token found');
    }

    Uri uri;
    if (queryParams != null) {
      uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    } else {
      uri = Uri.parse('$baseUrl$endpoint');
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };

    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If token expired, try to refresh
    if (response.statusCode == 401) {
      bool refreshed = await _refreshAccessToken();
      if (refreshed) {
        // Retry the request with new token
        token = await _getToken();
        headers['Authorization'] = 'Bearer $token';
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: headers);
            break;
        }
      }
    }

    return response;
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String bloodGroup,
    required String phone,
    required bool isDonor,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'blood_group': bloodGroup,
          'phone': phone,
          'is_donor': isDonor,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {'error': 'Network error: $e'},
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'phone': phone, // Use phone instead of username
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Extract tokens from response
        if (responseData['access'] != null && responseData['refresh'] != null) {
          await _saveTokens(responseData['access'], responseData['refresh']);
        }
        
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': {'data': responseData}, // Match your expected structure
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {'error': 'Network error: $e'},
      };
    }
  }

  // Get profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _makeAuthenticatedRequest('GET', '/profile/');
      final responseData = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Get profile error: $e');
      if (e.toString().contains('No access token found')) {
        return {
          'success': false,
          'statusCode': 401,
          'data': {'error': 'No access token found'},
        };
      }
      return {
        'success': false,
        'statusCode': 500,
        'data': {'error': 'Network error: $e'},
      };
    }
  }

  // Get nearby donors
  static Future<Map<String, dynamic>> getNearbyDonors({
    required String bloodGroup,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/donors/',
        queryParams: {
          'blood_group': bloodGroup,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius': radius.toString(),
        },
      );

      final responseData = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      print('Get nearby donors error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {'error': 'Network error: $e'},
      };
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    String? token = await _getToken();
    if (token == null) return false;

    try {
      // Try to get profile to verify token is valid
      final result = await getProfile();
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _clearTokens();
  }
}