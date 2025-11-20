// lib/features/login/auth_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const _usersKey = 'auth_users';
  static const _currentUserKey = 'auth_current_user';

  Future<Map<String, String>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_usersKey);
    if (s == null || s.isEmpty) return {};
    final Map<String, dynamic> m = jsonDecode(s) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  /// Registers a new user. Returns false if the id already exists.
  /// 회원가입 성공 시 바로 현재 사용자로 설정합니다.
  Future<bool> signup(String id, String password) async {
    final users = await _loadUsers();
    if (users.containsKey(id)) return false;
    users[id] = password;
    await _saveUsers(users);
    await _setCurrentUser(id);
    return true;
  }

  /// Attempts login. Returns true if credentials match.
  Future<bool> login(String id, String password) async {
    final users = await _loadUsers();
    if (users[id] == password) {
      await _setCurrentUser(id);
      return true;
    }
    return false;
  }

  Future<void> _setCurrentUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }
}
