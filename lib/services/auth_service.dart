import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoggedIn = false;
  String? _userName;
  String? _userRole;
  int? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userRole => _userRole;
  int? get userId => _userId;

  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin' || _userRole == 'main_super_admin';
  bool get isSuperAdmin => _userRole == 'super_admin' || _userRole == 'main_super_admin';
  bool get isMainSuperAdmin => _userRole == 'main_super_admin';

  Future<bool> login(String login, String password, String requestedRole) async {
    try {
      final res = await _api.get('/login.php', params: {
        'login': login,
        'password': password,
        'role': requestedRole,
      });

      if (res.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res.data['token'] ?? '');
        await prefs.setInt('user_id', res.data['user']['id'] ?? 0);
        await prefs.setString('user_name', res.data['user']['name'] ?? '');
        await prefs.setString('user_email', res.data['user']['email'] ?? '');
        await prefs.setString('user_phone', res.data['user']['phone'] ?? '');
        await prefs.setString('user_role', res.data['user']['role'] ?? 'customer');

        _isLoggedIn = true;
        _userName = res.data['user']['name'];
        _userRole = res.data['user']['role'];
        _userId = res.data['user']['id'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _userName = null;
    _userRole = null;
    _userId = null;
    notifyListeners();
  }
}