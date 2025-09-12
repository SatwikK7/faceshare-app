import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../utils/constants.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  
  AuthService(this._prefs) {
    _loadUserFromStorage();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  
  // Load user data from local storage
  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = _prefs.getString(StorageKeys.authToken);
      final userJson = _prefs.getString(StorageKeys.userData);
      
      if (token != null && userJson != null) {
        _token = token;
        _currentUser = User.fromJson(jsonDecode(userJson));
        
        // Verify token is still valid
        await _verifyToken();
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
      await _clearUserData();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Verify token with backend
  Future<void> _verifyToken() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        _token = responseData['token'];
        _currentUser = User.fromJson({
          'id': responseData['userId'],
          'email': responseData['email'],
          'fullName': responseData['fullName'],
          'profileImageUrl': responseData['profileImageUrl'],
        });
        
        await _saveUserToStorage();
        
        _isLoading = false;
        notifyListeners();
        
        return AuthResult.success('Login successful');
      } else {
        _isLoading = false;
        notifyListeners();
        
        return AuthResult.error(responseData['error'] ?? 'Login failed');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      return AuthResult.error('Network error: ${e.toString()}');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Call logout endpoint if needed
      if (_token != null) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/auth/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('Error during logout API call: $e');
    }
    
    await _clearUserData();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Update user profile
  Future<AuthResult> updateProfile({
    required String fullName,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null || _token == null) {
      return AuthResult.error('User not logged in');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName,
          'profileImageUrl': profileImageUrl,
        }),
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        await _saveUserToStorage();
        
        _isLoading = false;
        notifyListeners();
        
        return AuthResult.success('Profile updated successfully');
      } else {
        _isLoading = false;
        notifyListeners();
        
        final responseData = jsonDecode(response.body);
        return AuthResult.error(responseData['error'] ?? 'Profile update failed');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      return AuthResult.error('Network error: ${e.toString()}');
    }
  }
  
  // Save user data to local storage
  Future<void> _saveUserToStorage() async {
    if (_currentUser != null && _token != null) {
      await _prefs.setString(StorageKeys.authToken, _token!);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_currentUser!.toJson()));
    }
  }
  
  // Clear user data from memory and storage
  Future<void> _clearUserData() async {
    _currentUser = null;
    _token = null;
    
    await _prefs.remove(StorageKeys.authToken);
    await _prefs.remove(StorageKeys.userData);
  }
  
  // Get authorization header
  Map<String, String> getAuthHeaders() {
    if (_token == null) {
      throw Exception('No authentication token available');
    }
    
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String message;
  
  AuthResult._(this.success, this.message);
  
  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.error(String message) => AuthResult._(false, message);
} == 401) {
        // Token is invalid, clear user data
        await _clearUserData();
      } else if (response.statusCode == 200) {
        // Update user data
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        await _saveUserToStorage();
      }
    } catch (e) {
      debugPrint('Error verifying token: $e');
    }
  }
  
  // Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _token = responseData['token'];
        _currentUser = User.fromJson({
          'id': responseData['userId'],
          'email': responseData['email'],
          'fullName': responseData['fullName'],
          'profileImageUrl': responseData['profileImageUrl'],
        });
        
        await _saveUserToStorage();
        
        _isLoading = false;
        notifyListeners();
        
        return AuthResult.success('Registration successful');
      } else {
        _isLoading = false;
        notifyListeners();
        
        return AuthResult.error(responseData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      return AuthResult.error('Network error: ${e.toString()}');
    }
  }
  
  // Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode