import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Try to load existing user
    _user = await DatabaseService.instance.getLocalUser();
    _isLoading = false;
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> login(String username, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final passwordHash = _hashPassword(password);
      final valid = await DatabaseService.instance.verifyPassword(username, passwordHash);
      
      if (valid) {
        _user = await DatabaseService.instance.getLocalUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Invalid username or password';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user already exists
      final existing = await DatabaseService.instance.getLocalUser();
      if (existing != null) {
        _error = 'A profile already exists. Please login instead.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final passwordHash = _hashPassword(password);
      
      // Generate random color
      final colors = ['#6366f1', '#ec4899', '#f59e0b', '#10b981', '#8b5cf6', '#ef4444', '#3b82f6', '#14b8a6'];
      final avatarColor = colors[DateTime.now().millisecond % colors.length];

      _user = await DatabaseService.instance.createUser(
        username,
        displayName,
        passwordHash,
        avatarColor,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? displayName,
    String? statusMessage,
    String? avatarColor,
    String? status,
  }) async {
    if (_user == null) return false;

    try {
      _user = _user!.copyWith(
        displayName: displayName,
        avatarColor: avatarColor,
        status: status,
        statusMessage: statusMessage,
      );
      
      await DatabaseService.instance.updateUser(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
