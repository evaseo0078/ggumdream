// lib/features/auth/domain/auth_repository.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

class AuthRepository {
  final _storage = const FlutterSecureStorage();

  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  // 로그인 정보 저장
  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }

  // 로그인 정보 가져오기
  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);
    return {'username': username, 'password': password};
  }

  // 로그인 정보 삭제 (로그아웃)
  Future<void> deleteCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final username = await _storage.read(key: _keyUsername);
    return username != null;
  }
}
