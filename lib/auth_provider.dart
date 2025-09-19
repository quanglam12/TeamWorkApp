
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  int? _userId;
  bool _rememberMe = false;

  String? get token => _token;
  int? get userId => _userId;
  bool get isLoggedIn => _token != null;

  Future<void> login(String token,int userId, {bool rememberMe = false}) async {
    _token = token;
    _userId = userId;
    _rememberMe = rememberMe;

    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('user_id', userId);
    }

    notifyListeners();
  }

  Future<void> loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('user_id');
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    notifyListeners();
  }
}
