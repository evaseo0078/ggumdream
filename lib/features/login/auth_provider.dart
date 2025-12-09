import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final String? username; // 이메일 또는 닉네임
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      error: error,
    );
  }

  factory AuthState.initial() =>
      const AuthState(isAuthenticated: false, username: null, error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState.initial());

  /// ✅ LoginPage에서 에러 초기화하고 싶을 때 사용
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// ✅ 딱 2개 케이스로 에러 정규화
  String _mapAuthErrorCode(String code) {
    // 1) 이메일 형식 오류
    if (code == 'invalid-email') {
      return 'Email format is invalid.';
    }

    // 2) 그 외 로그인 실패는 전부 통합
    // wrong-password, user-not-found, invalid-credential 등
    return 'Email or password is incorrect.';
  }

  Future<bool> login(String email, String password) async {
    try {
      // 에러 초기화
      state = state.copyWith(error: null);

      await _repo.signIn(email: email, password: password);

      state = state.copyWith(
        isAuthenticated: true,
        username: email,
        error: null,
      );
      return true;

    } on FirebaseAuthException catch (e) {
      final msg = _mapAuthErrorCode(e.code);

      state = state.copyWith(
        isAuthenticated: false,
        username: null,
        error: msg, // ✅ 이제 UI는 이 문장만 쓰면 됨
      );
      return false;

    } catch (_) {
      // 혹시 repo가 다른 예외를 던져도
      state = state.copyWith(
        isAuthenticated: false,
        username: null,
        error: 'Email or password is incorrect.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = AuthState.initial();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
