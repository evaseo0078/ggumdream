import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

final llmServiceProvider = Provider<MockLLMService>((ref) => MockLLMService());

class DiaryListNotifier extends StateNotifier<List<DiaryEntry>> {
  final DiaryRepository _repository;
  StreamSubscription<List<DiaryEntry>>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  DiaryListNotifier(this._repository) : super([]) {
    // Firebase Auth 상태 변화를 감지하여 다이어리 데이터 로드
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print('🔐 User logged in, loading diaries...');
        _listenToDiaries();
      } else {
        print('🚪 User logged out, clearing diaries...');
        _subscription?.cancel();
        state = [];
      }
    });
  }

  void _listenToDiaries() {
    _subscription?.cancel();
    _subscription = _repository.watchDiaries().listen(
      (entries) => state = entries,
      onError: (_) => state = [],
    );
  }

  Future<void> refresh() async {
    try {
      state = await _repository.fetchDiaries();
    } catch (_) {
      state = [];
    }
  }

  Future<void> addDiary(DiaryEntry entry) async {
    await _repository.saveDiary(entry);
  }

  Future<void> updateDiary(DiaryEntry entry) async {
    await _repository.saveDiary(entry);
  }

  Future<void> deleteDiary(String id) async {
    await _repository.deleteDiary(id);
  }

  Future<void> setSellStatus(String id, bool isSold) async {
    await _repository.setSellStatus(id, isSold);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, List<DiaryEntry>>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return DiaryListNotifier(repository);
});
