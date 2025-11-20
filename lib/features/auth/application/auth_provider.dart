// lib/features/auth/application/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';

// 현재 인증 상태를 관리하는 provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// 인증 상태를 나타내는 클래스
class AuthState {
  final bool isAuthenticated;
  final String? username;
  final String? error;

  AuthState({this.isAuthenticated = false, this.username, this.error});

  AuthState copyWith({bool? isAuthenticated, String? username, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      error: error ?? this.error,
    );
  }
}

// 인증 상태를 관리하는 notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    _init();
  }

  // 초기 상태 확인
  Future<void> _init() async {
    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      final credentials = await _repository.getCredentials();
      state = state.copyWith(
        isAuthenticated: true,
        username: credentials['username'],
      );
    }
  }

  // 로그인
  Future<bool> login(String username, String password) async {
    try {
      // TODO: 여기에 실제 로그인 로직 구현 (서버 인증 등)
      await _repository.saveCredentials(username, password);
      state = state.copyWith(
        isAuthenticated: true,
        username: username,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isAuthenticated: false);
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _repository.deleteCredentials();
    state = AuthState();
  }
}
