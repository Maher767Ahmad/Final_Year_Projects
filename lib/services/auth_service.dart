import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _initialized = false;
  bool get initialized => _initialized;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      // Load cached profile first for offline support
      final cachedProfile = prefs.getString('user_profile');
      if (cachedProfile != null) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(cachedProfile));
          notifyListeners();
        } catch (e) {
          debugPrint('Error loading cached profile: $e');
        }
      }
      
      // Attempt to refresh profile from server
      _fetchUserProfile(userId);
    }
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String id) async {
    try {
      final response = await _apiService.get('/users/profile?id=$id');
      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id.toString());
        await prefs.setString('user_profile', jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // If error (e.g., user deleted), logout locally
      if (e.toString().contains('404')) {
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/users/login', {
        'email': email,
        'password': password,
      }, requireAuth: false);

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id.toString());
        await prefs.setString('user_profile', jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String department,
    List<String>? subjects,
    required String idCardUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Register
      final response = await _apiService.post('/users/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
        'approved_subjects': subjects ?? [],
        'id_card_url': idCardUrl,
      }, requireAuth: false);

      // Auto login (or just set user)
      if (response != null && response['id'] != null) {
         final userId = response['id'].toString();
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('user_id', userId);
         await _fetchUserProfile(userId);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_profile');
    notifyListeners();
  }
}
