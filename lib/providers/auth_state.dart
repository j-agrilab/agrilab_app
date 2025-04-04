// lib/providers/auth_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const _authTokenKey = 'authToken';
  String? _authToken;
  bool get isAuthenticated => _authToken != null;

  Future<void> loadAuthToken() async {
    _authToken = await _storage.read(key: _authTokenKey);
    notifyListeners();
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: _authTokenKey, value: token);
    notifyListeners();
  }

  Future<void> logout() async {
    _authToken = null;
    await _storage.delete(key: _authTokenKey);
    notifyListeners();
  }

  // Add other authentication related methods (login, signup, refresh token) as needed
}