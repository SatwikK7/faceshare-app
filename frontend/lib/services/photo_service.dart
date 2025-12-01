import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/photo.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PhotoService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  
  List<Photo> _myPhotos = [];
  List<Photo> _sharedPhotos = [];
  bool _isLoading = false;
  String? _error;

  PhotoService(this._apiService, this._authService);

  // Getters
  List<Photo> get myPhotos => _myPhotos;
  List<Photo> get sharedPhotos => _sharedPhotos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load my photos
  Future<void> loadMyPhotos() async {
    if (_authService.token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photosData = await _apiService.getMyPhotos(_authService.token!);
      _myPhotos = photosData.map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading my photos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load shared photos
  Future<void> loadSharedPhotos() async {
    if (_authService.token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photosData = await _apiService.getSharedPhotos(_authService.token!);
      _sharedPhotos = photosData.map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading shared photos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Upload photo
  Future<bool> uploadPhoto(File imageFile) async {
    if (_authService.token == null) {
      _error = 'Not authenticated';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.uploadPhoto(_authService.token!, imageFile);
      final newPhoto = Photo.fromJson(response);
      
      // Add to my photos list
      _myPhotos.insert(0, newPhoto);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMessage = 'Upload failed';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      _error = errorMessage;
      debugPrint('Error uploading photo: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh all photos
  Future<void> refreshPhotos() async {
    await Future.wait([
      loadMyPhotos(),
      loadSharedPhotos(),
    ]);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}