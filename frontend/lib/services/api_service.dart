import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://544025a59c2d.ngrok-free.app/api';

  // Helper method to get stored access token
  static Future<String?> _getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Helper method to get stored refresh token
  static Future<String?> _getRefreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Helper method to save tokens
  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Helper method to clear all tokens
  static Future<void> _clearTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Refresh access token using refresh token
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
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  // Make authenticated HTTP request with automatic token refresh
  static Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    String? token = await _getAccessToken();
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
    
    // Make the initial request
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If we get 401 (unauthorized), try to refresh the token and retry
    if (response.statusCode == 401) {
      bool refreshed = await _refreshAccessToken();
      if (refreshed) {
        // Update token in headers and retry the request
        token = await _getAccessToken();
        headers['Authorization'] = 'Bearer $token';
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: headers,
              body: body != null ? json.encode(body) : null,
            );
            break;
        }
      }
    }

    return response;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String pin,
    required String confirmPin,
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
        body: json.encode({
          'username': username,
          'email': email,
          'pin': pin,
          'confirm_pin': confirmPin,
          'first_name': firstName,
          'last_name': lastName,
          'blood_group': bloodGroup,
          'phone': phone,
          'is_donor': isDonor,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      return {
        'success': response.statusCode == 201,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': e.toString()},
        'statusCode': 500,
      };
    }
  }

  static Future<Map<String, dynamic>> login(
      String phone, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'phone': phone,
          'pin': pin, // Changed from 'password' to 'pin'
        }),
      );
      
      print('Login request: phone=$phone');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Save tokens if they exist in the response
        if (responseData['access'] != null && responseData['refresh'] != null) {
          await _saveTokens(responseData['access'], responseData['refresh']);
        }
      }

      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': e.toString()},
        'statusCode': 500,
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _makeAuthenticatedRequest('GET', '/profile/');
      
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      // If no access token found, return 401 to indicate need to login
      if (e.toString().contains('No access token found')) {
        return {
          'success': false,
          'data': {'error': 'Not authenticated'},
          'statusCode': 401,
        };
      }
      
      return {
        'success': false,
        'data': {'error': e.toString()},
        'statusCode': 500,
      };
    }
  }

  static Future<Map<String, dynamic>> getNearbyDonors({
    required String bloodGroup,
    required double latitude,
    required double longitude,
    double radius = 10.0,
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

      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': e.toString()},
        'statusCode': 500,
      };
    }
  }

  // Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    try {
      String? accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      // Try to get profile to test if token is valid
      final result = await getProfile();
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Logout user by clearing all stored tokens
  static Future<void> logout() async {
    await _clearTokens();
  }
}