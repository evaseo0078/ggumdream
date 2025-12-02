// lib/features/login/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 닉네임 중복 예외
class NicknameAlreadyUsedException implements Exception {
  @override
  String toString() => 'NicknameAlreadyUsedException';
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterSecureStorage _storage;

  // 🔐 기존 키 이름은 그대로 사용 (username = email)
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

  // 로그인 상태 스트림 (필요하면 사용)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // =========================================
  // 🔥 회원가입 (Auth + Firestore + 코인 1000)
  // =========================================
  Future<void> signUp({
    required String name,
    required String nickname,
    required String email,
    required String password,
  }) async {
    // 1) 닉네임 중복 검사
    final dup = await _db
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();

    if (dup.docs.isNotEmpty) {
      throw NicknameAlreadyUsedException();
    }

    User? user;

    // 2) Firebase Auth 계정 생성
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = cred.user;
    } on FirebaseAuthException catch (e) {
      // 이메일 형식 오류, 중복, 약한 비밀번호 등은 그대로 UI 에서 처리
      throw e;
    } catch (e) {
      // ❗ 여기서 지금 보고 있는 PigeonUserDetails 캐스트 오류가 발생함
      if (e.toString().contains('PigeonUserDetails')) {
        // 실제로는 계정이 만들어지고 로그인까지 된 상태라 currentUser 가 존재함
        user = _auth.currentUser;
      } else {
        rethrow;
      }
    }

    user ??= _auth.currentUser;
    if (user == null) {
      // 여기까지 오면 정말로 뭔가 이상한 상황
      throw Exception('Sign-up was successful, but failed to retrieve user information');
    }

    final uid = user.uid;

    // 3) Firestore에 프로필 + 기본 코인 1000 저장
    await _db.collection('users').doc(uid).set({
      'name': name,
      'nickname': nickname,
      'email': email,
      'coins': 1000,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4) 로컬에도 이메일/비밀번호 저장 (자동 로그인 용도)
    await saveCredentials(email, password);
  }

  // =========================================
  // 🔐 로그인
  // =========================================
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await saveCredentials(email, password);
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      // 이쪽도 PigeonUserDetails 버그가 가끔 나오므로 한 번 더 방어
      if (e.toString().contains('PigeonUserDetails')) {
        if (_auth.currentUser != null) {
          await saveCredentials(email, password);
          // currentUser 가 있으면 사실상 로그인은 된 상태
          return;
        }
      }
      rethrow;
    }
  }

  // =========================================
  // 로그아웃 & 로컬 저장 관리
  // =========================================
  Future<void> signOut() async {
    await _auth.signOut();
    await deleteCredentials();
  }

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);
    return {'username': username, 'password': password};
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
  }

  Future<bool> isLoggedIn() async {
    if (_auth.currentUser != null) return true;

    final username = await _storage.read(key: _keyUsername);
    return username != null;
  }
}
