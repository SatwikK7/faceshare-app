import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  
  // Static instance for backward compatibility
  static AuthService? _instance;
  
  AuthService(this._prefs) {
    _instance = this;
    _loadUserFromStorage();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  
  // Static getter for backward compatibility
  static User? get staticCurrentUser => _instance?._currentUser;
  
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
      final apiService = ApiService();
      await apiService.getCurrentUser(_token!);
      // Token is valid, keep current user
    } catch (e) {
      debugPrint('Token verification failed: $e');
      await _clearUserData();
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.login(email, password);
      
      _token = response['token'];
      _currentUser = User.fromJson(response);
      
      // Save to storage
      await _prefs.setString(StorageKeys.authToken, _token!);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_currentUser!.toJson()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register method
  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.register(email, password, fullName);
      
      _token = response['token'];
      _currentUser = User.fromJson(response);
      
      // Save to storage
      await _prefs.setString(StorageKeys.authToken, _token!);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_currentUser!.toJson()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration failed: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    await _clearUserData();
  }

  // Clear user data
  Future<void> _clearUserData() async {
    _currentUser = null;
    _token = null;
    await _prefs.remove(StorageKeys.authToken);
    await _prefs.remove(StorageKeys.userData);
    notifyListeners();
  }
}