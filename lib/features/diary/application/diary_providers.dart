// lib/features/diary/application/diary_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/diary_entry.dart';
import '../data/diary_repository.dart';

// 1. Hive Box Provider
final diaryBoxProvider = Provider<Box<DiaryEntry>>((ref) {
  const boxName = 'diaries';
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box<DiaryEntry>(boxName);
  }

  throw StateError(
    'diaryBoxProvider was not overridden and Hive box "$boxName" is not open.\n'
    'Make sure you open the box in main() before runApp and pass it via ProviderScope(overrides: ...).',
  );
});

// 2. Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final box = ref.watch(diaryBoxProvider);
  return DiaryRepository(box);
});

// 3. LLM Service Provider
final llmServiceProvider = Provider<MockLLMService>((ref) => MockLLMService());

// 4. Diary List Notifier (실제 UI에서 관찰할 대상)
class DiaryListNotifier extends StateNotifier<List<DiaryEntry>> {
  final DiaryRepository _repository;

  DiaryListNotifier(this._repository) : super([]) {
    loadDiaries();
  }

  void loadDiaries() {
    state = _repository.getDiaries();
  }

  Future<void> addDiary(DiaryEntry entry) async {
    await _repository.addDiary(entry);
    loadDiaries();
  }

  Future<void> deleteDiary(String id) async {
    await _repository.deleteDiary(id);
    loadDiaries();
  }

  Future<void> toggleSell(String id) async {
    await _repository.toggleSellStatus(id);
    loadDiaries();
  }

  DiaryEntry? byId(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String id) async => deleteDiary(id);
}

final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, List<DiaryEntry>>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return DiaryListNotifier(repository);
});

/// DateFormat provider used by presentation layers
final dateFmtProvider = Provider<DateFormat>((ref) => DateFormat('yyyy.MM.dd'));
