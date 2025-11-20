// lib/features/auth/domain/auth_repository.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NicknameAlreadyUsedException implements Exception {
  final String nickname;
  NicknameAlreadyUsedException(this.nickname);

  @override
  String toString() => 'Nickname "$nickname" is already in use';
}

/// ✅ Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterSecureStorage _storage;

  // 🔐 기존 키 이름은 그대로 유지 (username/password)
  static const _keyUsername = 'username'; // 여기에는 이메일을 넣을 예정
  static const _keyPassword = 'password';

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

  // ================================
  // 🔥 Firebase Auth / Firestore 쪽
  // ================================

  /// 로그인 상태 스트림 (필요하면 상위에서 listen해서 쓰기)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 현재 로그인된 유저 (없으면 null)
  User? get currentUser => _auth.currentUser;

  /// 회원가입: Firebase Auth + Firestore(users 컬렉션)에 name/nickname/email 저장
  /// + nicknames 컬렉션으로 닉네임 유일성 보장
  Future<UserCredential> signUp({
    required String name,
    required String nickname,
    required String email,
    required String password,
  }) async {
    // 1) 닉네임 중복 검사 (nicknames/{nickname} 문서 존재 여부)
    final nickRef = _db.collection('nicknames').doc(nickname);
    final nickSnap = await nickRef.get();
    if (nickSnap.exists) {
      // 이미 사용 중인 닉네임
      throw NicknameAlreadyUsedException(nickname);
    }

    // 2) Firebase Auth 계정 생성
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 3) users/{uid} 문서에 기본 프로필 저장
    await _db.collection('users').doc(uid).set({
      'name': name,
      'nickname': nickname,
      'email': email,
      'coins': 1000, // 가입 시 기본 코인 지급
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4) nicknames/{nickname} 문서에 uid 매핑 저장 (닉네임 예약)
    await nickRef.set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 5) 선택: 로컬에도 이메일/비번 저장 (자동 로그인 등에 사용 가능)
    await saveCredentials(email, password);

    return cred;
  }

  /// 로그인: Firebase Auth 사용
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 성공하면 로컬에 저장
    await saveCredentials(email, password);
    return cred;
  }

  /// 로그아웃: Firebase + 로컬 정보 삭제
  Future<void> signOut() async {
    await _auth.signOut();
    await deleteCredentials();
  }

  // =====================================
  // 🗂 secure storage 관련 메서드들
  // (이제는 email/password 저장용으로 사용)
  // =====================================

  // 로그인 정보 저장 (username 자리에 email 넣기)
  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }

  // 로그인 정보 가져오기 (auto-login 등에 쓰고 싶으면 사용)
  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);
    return {'username': username, 'password': password};
  }

  // 로그인 정보 삭제
  Future<void> deleteCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    // 1순위: Firebase 에서 이미 로그인된 유저가 있다면 true
    if (_auth.currentUser != null) {
      return true;
    }

    // 2순위: 로컬에 username(email) 이 남아있는지 확인
    final username = await _storage.read(key: _keyUsername);
    return username != null;
  }
}
