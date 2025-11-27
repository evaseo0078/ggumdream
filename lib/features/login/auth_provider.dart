import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(error: null);
      await _repo.signIn(email: email, password: password);
      state = state.copyWith(isAuthenticated: true, username: email);
      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: e.toString(),
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
