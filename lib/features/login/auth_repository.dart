// lib/features/login/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 닉네임 중복 예외 클래스
class NicknameAlreadyUsedException implements Exception {
  @override
  String toString() => 'NicknameAlreadyUsedException';
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterSecureStorage _storage;

  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ✅ [1] 재인증 (Verify 버튼용)
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user found');

    final cred = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);
  }

  // ✅ [2] 비밀번호 업데이트 (내부 사용)
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user found');

    await user.updatePassword(newPassword);

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await saveCredentials(email, newPassword);
    }
  }

  // ✅ [3] 비밀번호 변경 통합 함수
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('No email found for current user');
    }

    await reauthenticate(email: email, password: currentPassword);
    await updatePassword(newPassword);
  }

  // ✅ [4] 프로필 이미지 변경
  Future<void> updateProfileImage(String userId, int imageIndex) async {
    await _db.collection('users').doc(userId).update({
      'profileImageIndex': imageIndex,
    });
  }

  // ✅ [5] 닉네임 중복 확인
  Future<bool> checkNickname(String nickname) async {
    final result = await _db
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();
    return result.docs.isEmpty;
  }

  // ✅ Email 중복 확인 (Firestore 기준)
  // - 지금 너 구조에선 users 컬렉션이 소스 오브 트루스라 이게 제일 안정적
  Future<bool> checkEmail(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return result.docs.isEmpty;
  }

  // ✅ [6] 회원가입
  Future<void> signUp({
    required String name,
    required String nickname,
    required String email,
    required String password,
  }) async {
    // 닉네임 중복 재확인
    final isAvailable = await checkNickname(nickname);
    if (!isAvailable) {
      throw NicknameAlreadyUsedException();
    }

    User? user;

    // Firebase Auth 계정 생성
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    user = cred.user;

    if (user == null) throw Exception("User creation failed");

    // Firestore 저장 (✅ 디폴트 코인 1000)
    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'nickname': nickname,
      'email': email,
      'coins': 1000,
      'profileImageIndex': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 로컬 저장
    await saveCredentials(email, password);
  }

  // ✅ [7] 로그인
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await saveCredentials(email, password);
  }

  // ✅ [8] 닉네임 업데이트
  Future<void> updateNickname(String uid, String newNickname) async {
    await _db.collection('users').doc(uid).update({
      'nickname': newNickname,
    });
  }

  // ✅ [9] 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
    await deleteCredentials();
  }

  // ----------------------------
  // Secure storage
  // ----------------------------
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
}
