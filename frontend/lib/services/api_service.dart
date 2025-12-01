import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class ApiService {
  static const String _baseUrl = ApiConstants.baseUrl;
  
  // Helper method to create headers
  Map<String, String> _getHeaders({String? token, bool isMultipart = false}) {
    final headers = <String, String>{};
    
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Helper method to handle HTTP responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing response JSON: $e');
        return {'success': true};
      }
    } else {
      String errorMessage = 'Request failed';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? errorBody['message'] ?? 'Request failed';
        }
      } catch (e) {
        debugPrint('Error parsing error response: $e');
        errorMessage = 'Request failed with status ${response.statusCode}';
      }
      throw ApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  // Authentication APIs
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = '$_baseUrl${ApiConstants.loginEndpoint}';
      debugPrint('=== LOGIN ATTEMPT ===');
      debugPrint('Full URL: $url');
      debugPrint('Base URL: $_baseUrl');
      debugPrint('Timeout: ${ApiConstants.requestTimeout}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConstants.requestTimeout);

      debugPrint('Response received: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Login error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.registerEndpoint}'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      ).timeout(ApiConstants.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.meEndpoint}'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConstants.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Get current user error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.refreshEndpoint}'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConstants.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Refresh token error: $e');
      rethrow;
    }
  }

  // Photo APIs
  Future<List<Map<String, dynamic>>> getMyPhotos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.myPhotosEndpoint}'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final result = jsonDecode(response.body);
        if (result is List) {
          return List<Map<String, dynamic>>.from(result);
        }
        return [];
      } else {
        throw ApiException(
          message: 'Failed to get photos',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Get my photos error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSharedPhotos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.sharedPhotosEndpoint}'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final result = jsonDecode(response.body);
        if (result is List) {
          return List<Map<String, dynamic>>.from(result);
        }
        return [];
      } else {
        throw ApiException(
          message: 'Failed to get shared photos',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Get shared photos error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadPhoto(String token, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiConstants.uploadEndpoint}'),
      );

      request.headers.addAll(_getHeaders(token: token, isMultipart: true));
      
      // Check if file exists
      if (!await imageFile.exists()) {
        throw ApiException(message: 'Image file not found', statusCode: 400);
      }
      
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send().timeout(ApiConstants.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Upload photo error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Upload failed: ${e.toString()}', statusCode: 500);
    }
  }

  // User APIs
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.profileEndpoint}'),
        headers: _getHeaders(token: token),
      ).timeout(ApiConstants.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Get user profile error: $e');
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}