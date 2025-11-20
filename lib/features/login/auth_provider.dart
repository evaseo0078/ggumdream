// lib/features/login/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// 회원가입한 ID를 임시 저장하는 provider
final tempSignupIdProvider = StateProvider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, String?>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    return CurrentUserNotifier(repo);
  },
);

class CurrentUserNotifier extends StateNotifier<String?> {
  final AuthRepository _repo;
  CurrentUserNotifier(this._repo) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _repo.currentUser();
  }

  Future<bool> signup(String id, String password) async {
    final ok = await _repo.signup(id, password);
    if (ok) state = id;
    return ok;
  }

  Future<bool> login(String id, String password) async {
    final ok = await _repo.login(id, password);
    if (ok) state = id;
    return ok;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
  }
}
