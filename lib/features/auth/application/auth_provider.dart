// lib/features/auth/application/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final String? username; // 이메일 등
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.username,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    // Firebase 로그인 상태 스트림 반영
    _repository.authStateChanges().listen((user) {
      state = state.copyWith(
        isAuthenticated: user != null,
        username: user?.email,
        error: null,
      );
    });
  }

  /// 로그인 (이메일/비밀번호)
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        username: email,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

/// Provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
